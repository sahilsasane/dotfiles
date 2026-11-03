import Foundation
import Metal

struct Uniforms {
    var resolution: SIMD3<Float>
    var current: SIMD4<Float>
    var previous: SIMD4<Float>
    var color = SIMD4<Float>(0.8, 0.7, 0.9, 1)
    var time: Float
    var changed: Float = 0
}

let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!
let width = 2560, height = 1440
let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: width, height: height, mipmapped: false)
descriptor.storageMode = .shared
descriptor.usage = [.shaderRead, .renderTarget]
var input = device.makeTexture(descriptor: descriptor)!
var pixels = [SIMD4<Float>](repeating: SIMD4(0.15, 0.18, 0.22, 0.75), count: width * height)
for y in 0..<height {
    for x in 0..<width where (x / 9 + y / 18) % 2 == 0 {
        pixels[y * width + x] = SIMD4(0.5, 0.6, 0.7, 1)
    }
}
input.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
              withBytes: &pixels, bytesPerRow: width * 16)
var outputs = [device.makeTexture(descriptor: descriptor)!, device.makeTexture(descriptor: descriptor)!]
let libraries = try CommandLine.arguments[1...2].map { path in
    try device.makeLibrary(source: String(contentsOfFile: path, encoding: .utf8), options: nil)
}
func makePipelines(_ format: MTLPixelFormat) throws -> [MTLRenderPipelineState] {
    try libraries.map { library in
        let pipeline = MTLRenderPipelineDescriptor()
        pipeline.vertexFunction = library.makeFunction(name: "vertex_main")
        pipeline.fragmentFunction = library.makeFunction(name: "fragment_main")
        pipeline.colorAttachments[0].pixelFormat = format
        return try device.makeRenderPipelineState(descriptor: pipeline)
    }
}
var pipelines = try makePipelines(.rgba32Float)

func render(_ variant: Int, _ value: Uniforms, frames: Int = 1) throws -> Double {
    let command = queue.makeCommandBuffer()!
    var uniforms = value
    for _ in 0..<frames {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = outputs[variant]
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        let encoder = command.makeRenderCommandEncoder(descriptor: pass)!
        encoder.setRenderPipelineState(pipelines[variant])
        encoder.setFragmentTexture(input, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }
    command.commit()
    command.waitUntilCompleted()
    guard command.status == .completed, command.error == nil else {
        throw command.error ?? NSError(domain: "GPU", code: 1)
    }
    return (command.gpuEndTime - command.gpuStartTime) * 1000 / Double(frames)
}

func readPixels(_ texture: MTLTexture) -> [SIMD4<Float>] {
    var result = [SIMD4<Float>](repeating: .zero, count: width * height)
    texture.getBytes(&result, bytesPerRow: width * 16,
                     from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
    return result
}

func uniform(_ x: Float, _ y: Float, _ time: Float, bar: Bool = false) -> Uniforms {
    return Uniforms(resolution: SIMD3(Float(width), Float(height), 1),
                    current: SIMD4(x, y, bar ? 3 : 18, 36),
                    previous: SIMD4(600, 600, bar ? 3 : 18, 36), time: time)
}

var correctness: [[String: Any]] = []
// Diagonals exercise antialiasing; axis-aligned paths exercise the zero-blur fix.
for (name, x, y) in [("diagonal", Float(1400), Float(900)), ("left-up", 200, 200),
                      ("horizontal", 1400, 600), ("vertical", 600, 1000),
                      ("below-threshold", 610, 610), ("same-position", 600, 600)] {
    for bar in [false, true] {
        for t: Float in [0, 0.02, 0.08, 0.2, 0.398, 0.4, 1] {
            let u = uniform(x, y, t, bar: bar)
            _ = try render(0, u)
            _ = try render(1, u)
            let before = readPixels(outputs[0]), after = readPixels(outputs[1])
            var maxError: Float = 0
            var mismatches = 0, beforeNonfinite = 0, afterNonfinite = 0, effectPixels = 0
            for index in 0..<before.count {
                let a = before[index], b = after[index]
                for component in 0..<4 {
                    if !a[component].isFinite { beforeNonfinite += 1 }
                    if !b[component].isFinite { afterNonfinite += 1 }
                    if !a[component].isFinite || !b[component].isFinite { continue }
                    let error = abs(a[component] - b[component])
                    if error > 0.0001 { mismatches += 1 }
                    maxError = max(maxError, error)
                }
                if abs(b.x - pixels[index].x) > 0.0001 { effectPixels += 1 }
            }
            correctness.append(["movement": name, "bar_cursor": bar, "time": t,
                                "max_channel_error": maxError, "mismatched_channels": mismatches,
                                "before_nonfinite_channels": beforeNonfinite,
                                "after_nonfinite_channels": afterNonfinite, "effect_pixels": effectPixels])
        }
    }
}

// Keep float precision for correctness, then match Ghostty's native BGRA8 target
// and linear clamp sampler for timings (src/renderer/Metal.zig).
descriptor.pixelFormat = .bgra8Unorm
input = device.makeTexture(descriptor: descriptor)!
var packed = pixels.flatMap { pixel in
    [pixel.z, pixel.y, pixel.x, pixel.w].map { UInt8(($0 * 255).rounded()) }
}
input.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
              withBytes: &packed, bytesPerRow: width * 4)
outputs = [device.makeTexture(descriptor: descriptor)!, device.makeTexture(descriptor: descriptor)!]
pipelines = try makePipelines(.bgra8Unorm)
var timings: [[String: Any]] = []
for (name, u) in [("idle", uniform(1400, 900, 1)),
                  ("diagonal", uniform(1400, 900, 0.08)),
                  ("horizontal", uniform(1400, 600, 0.08)),
                  ("bar-diagonal", uniform(1400, 900, 0.08, bar: true))] {
    for variant in 0...1 { _ = try render(variant, u, frames: 8) }
    for round in 1...5 {
        for variant in 0...1 {
            let ms = try render(variant, u, frames: 32)
            timings.append(["scenario": name, "round": round,
                            "variant": variant == 0 ? "before" : "after", "gpu_ms_per_frame": ms])
        }
    }
}
let report: [String: Any] = ["device": device.name, "resolution": [width, height],
                           "correctness_format": "rgba32Float", "timing_format": "bgra8Unorm",
                           "sampler": "linear clamp-to-edge", "frames_per_timing": 32,
                           "correctness": correctness, "timings": timings]
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
for check in correctness {
    precondition(check["after_nonfinite_channels"] as! Int == 0, "Optimized shader produced nonfinite output: \(check)")
    let movement = check["movement"] as! String
    if movement != "horizontal" && movement != "vertical" {
        precondition(check["mismatched_channels"] as! Int == 0, "Render changed: \(check)")
        precondition(check["before_nonfinite_channels"] as! Int == 0, "Baseline nonfinite output: \(check)")
    }
    if check["time"] as! Float >= 0.4 || movement == "same-position" || movement == "below-threshold" {
        precondition(check["effect_pixels"] as! Int == 0, "Trail drawn while inactive: \(check)")
    }
    if movement == "diagonal" && check["time"] as! Float == 0.08 {
        precondition(check["effect_pixels"] as! Int > 0, "Trail missing during animation: \(check)")
    }
}
print("GPU checks: \(correctness.count); mismatched channels: \(correctness.reduce(0) { $0 + ($1["mismatched_channels"] as! Int) })")
print("GPU timings saved: \(CommandLine.arguments[3])")
