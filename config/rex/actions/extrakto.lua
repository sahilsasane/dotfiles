-- Extrakto: pick text from the pane in an overlay (scripts/extrakto.py).
local util = require("lib.util")
local check = util.check

local function block_rect(node, block_id)
	if node == nil then
		return nil
	end
	if node.block_id == block_id then
		return node.rect
	end
	if node.split then
		return block_rect(node.split.before, block_id) or block_rect(node.split.after, block_id)
	end
end

local function open_overlay(ctx, label, command, overlay_bounds)
	local view = check(rex.session.view({}))
	for _, window in ipairs(view.windows or {}) do
		for _, layer in ipairs(window.layers or {}) do
			local bounds = block_rect(layer.layout, ctx.block_id)
			if bounds then
				local zoomed = window.zoomed_block_id == ctx.block_id
				return check(rex.session.new_layer({
					window_id = window.window_id,
					bounds = overlay_bounds or (zoomed and { 0, 0, 1, 1 } or bounds),
					focus = true,
					layout = rex.layout.block({
						flavor = util.SHELL,
						label = label,
						options = {
							-- Overlay tools need Homebrew's PATH, without login-shell runtime setup.
							shell = "none",
							path_prepend = { "/opt/homebrew/bin" },
							-- Rex otherwise retains an overlay dismissed within its quick-exit threshold.
							exit = { quick_exit_threshold_ms = 0 },
							command = command(zoomed),
						},
					}),
				}))
			end
		end
	end
	error("The focused pane is no longer in the layout")
end

rex.action({
	name = "extrakto",
	title = "Extrakto (Pick Terminal Text)",
	run = function(ctx)
		return open_overlay(ctx, "Extrakto", function(zoomed)
			return {
				"python3",
				util.CONFIG_DIR .. "/scripts/extrakto.py",
				ctx.session_id,
				ctx.block_id,
				tostring(zoomed),
			}
		end, { 0.15, 0.225, 0.7, 0.55 })
	end,
})
