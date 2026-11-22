-- Pane actions: open shells where you are, tmux-style repeat resize and move,
-- and clearing that works in floating terminals too.
local util = require("lib.util")
local check, TERMINAL = util.check, util.TERMINAL

local function shell_here(ctx)
	return rex.layout.block({ flavor = util.SHELL, options = { cwd = util.block_cwd(ctx.block_id) } })
end

-- tmux's -c "#{pane_current_path}": new panes and tabs start where you are.
rex.action({
	name = "split_here",
	title = "Split Pane Here",
	args = { direction = "string" },
	run = function(ctx, args)
		check(rex.session.new_split({
			anchor_id = ctx.block_id,
			direction = (args.direction == "down" or args.direction == "up") and "vertical" or "horizontal",
			side = (args.direction == "left" or args.direction == "up") and "before" or "after",
			layout = shell_here(ctx),
			focus = true,
		}))
	end,
})

-- rex.action({
-- 	name = "tab_here",
-- 	title = "New Tab Here",
-- 	run = function(ctx)
-- 		check(rex.session.new_window({ layout = shell_here(ctx), focus = true }))
-- 	end,
-- })

rex.action({
	name = "floating_shell_here",
	title = "Open Floating Shell",
	run = function(ctx)
		check(rex.session.new_layer({
			bounds = { 0.1, 0.1, 0.8, 0.8 },
			layout = shell_here(ctx),
			focus = true,
		}))
	end,
})

-- tmux `bind -r`: the first resize enters resize mode, so hjkl keeps resizing
-- until escape, enter, or q.
rex.action({
	name = "resize_repeat",
	title = "Resize Pane and Keep Resizing",
	args = { direction = "string" },
	run = function(ctx, args)
		rex.client.queue("pane.resize", { direction = args.direction, amount = 7 })
		rex.client.queue("client.mode.enter", { name = "resize" })
	end,
})

rex.action({
	name = "move_repeat",
	title = "Move Pane and Keep Rearranging",
	args = { direction = "string" },
	run = function(ctx, args)
		rex.client.queue("pane.move." .. args.direction)
		rex.client.queue("client.mode.enter", { name = "resize" })
	end,
})

-- Send directly to the block: pane.send_key misses floating terminals.
rex.action({
	name = "clear_scrollback",
	title = "Clear Scrollback and Redraw Prompt",
	run = function(ctx)
		local modes = check(rex.block.call(TERMINAL, "modes", { block_id = ctx.block_id }))
		if modes.screen == "alternate" then
			return
		end
		check(rex.block.call(TERMINAL, "write", { block_id = ctx.block_id, data = "\27k" }))
	end,
})

rex.action({
	name = "clear_input_line",
	title = "Clear Input Line",
	run = function(ctx)
		check(rex.block.call(TERMINAL, "write", { block_id = ctx.block_id, data = "\21" }))
	end,
})
