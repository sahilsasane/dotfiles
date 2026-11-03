#!/usr/bin/env python3
"""Mechanically adapt these GLSL shaders to Metal for offscreen checks/timings.

This is a shader-only microbenchmark, not Ghostty's GLSL translation pipeline.
The native Ghostty benchmark separately measures application CPU overhead.
Requires macOS, Swift, and Metal; writes generated source into a temporary folder.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile


def metal_source(path):
    source = path.read_text()
    source = re.sub(r'\binout float (\w+)', r'thread float& \1', source)
    source = re.sub(r'\bout vec4 (\w+)', r'thread float4& \1', source)
    source = re.sub(r'\bin vec[234] ', lambda m: m[0][3:], source)
    source = re.sub(r'\bvec([234])\b', r'float\1', source)
    constants = re.findall(r'^const float .*$', source, flags=re.M)
    source = re.sub(r'^const float .*$', '', source, flags=re.M)
    constants = '\n'.join(line.replace('const float ', 'constant float ', 1) for line in constants)
    for name in ('iResolution', 'iCurrentCursor', 'iPreviousCursor', 'iCurrentCursorColor', 'iTime', 'iTimeCursorChange'):
        source = re.sub(rf'\b{name}\b', f'u.{name}', source)
    return '''#include <metal_stdlib>
using namespace metal;
struct Uniforms {
    float3 iResolution;
    float4 iCurrentCursor, iPreviousCursor, iCurrentCursorColor;
    float iTime, iTimeCursorChange;
};
float4 texture(texture2d<float> tex, float2 uv) {
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    return tex.sample(s, uv);
}
bool2 lessThan(float2 a, float2 b) { return a < b; }
bool2 lessThanEqual(float2 a, float2 b) { return a <= b; }
bool2 greaterThan(float2 a, float2 b) { return a > b; }
''' + constants + '''
struct Shader {
    Uniforms u;
    texture2d<float> iChannel0;
''' + source + '''
};
vertex float4 vertex_main(uint id [[vertex_id]]) {
    float2 points[3] = {float2(-1,-1), float2(3,-1), float2(-1,3)};
    return float4(points[id], 0, 1);
}
fragment float4 fragment_main(float4 pos [[position]],
    constant Uniforms& u [[buffer(0)]], texture2d<float> input [[texture(0)]]) {
    Shader shader{u, input};
    float4 color = float4(0);
    shader.mainImage(color, pos.xy);
    return color;
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='ghostty-metal-') as temp:
        directory = Path(temp)
        for name in ('before', 'after'):
            (directory / f'{name}.metal').write_text(metal_source(getattr(args, name)))
        executable = directory / 'check-shader'
        subprocess.run(['swiftc', '-O', str(Path(__file__).with_name('check_cursor_shader_metal.swift')),
                        '-o', str(executable)], check=True)
        subprocess.run([str(executable), str(directory / 'before.metal'),
                        str(directory / 'after.metal'), str(args.output.resolve())], check=True)
        report = json.loads(args.output.read_text())
        report['shader_sha256'] = {
            name: hashlib.sha256(getattr(args, name).read_bytes()).hexdigest()
            for name in ('before', 'after')
        }
        report['adaptation'] = 'Mechanical GLSL-to-MSL syntax adapter; not Ghostty\'s glslang/SPIRV-Cross pipeline'
        report['format_source'] = 'https://github.com/ghostty-org/ghostty/blob/main/src/renderer/Metal.zig'
        args.output.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
