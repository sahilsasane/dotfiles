-- Rex config entry point: load the actions, then bind every key here.
--   actions/   custom actions, one file per area
--   lib/       helpers the actions share
--   scripts/   programs Rex runs: extrakto.py, and watch.lua (kept running by launchd)
--   vendor/    third-party code, adapted
-- Windows, splits, panes, and zoom use the tmux ctrl+space prefix.
-- Appearance lives in the app's Settings, not here.

require("actions.panes")
require("actions.extrakto")
require("actions.workspace")
require("actions.palette")

-- require("vendor.copy-mode.copy-mode").setup({
-- 	key = false, -- The existing prefix binding below opens copy mode.
-- 	nvim = "/opt/homebrew/bin/nvim",
-- 	rex = os.getenv("HOME")
-- 		.. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
-- })

local PREFIX = "ctrl+space>"

-- Without the prefix (bind -n)
rex.bind("cmd+k", "clear_scrollback")
rex.bind("cmd+backspace", "clear_input_line")

rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })
rex.bind("alt+l", "pane.focus", { direction = "right" })

-- Behind the prefix
rex.bind(PREFIX .. "ctrl+space", "pane.send_key", { key = "ctrl+space" })
rex.bind(PREFIX .. "r", "client.config.reload")
-- rex.bind(PREFIX .. "[", "copy_mode")
rex.bind(PREFIX .. "ctrl+e", "extrakto")
rex.bind(PREFIX .. "ctrl+p", "floating_shell_here")

-- rex.bind(PREFIX .. "ctrl+k", "scroll_up")
-- rex.bind(PREFIX .. "ctrl+j", "scroll_down")
--
-- rex.bind("scroll/k", "client.scroll.page_up", { direction = "up", amount = 1 })
-- rex.bind("scoll/j", "client.scroll.page_down", { direction = "down", amount = 1 })
--
-- rex.mode("scroll", { exclusive = true })
-- rex.bind("scroll/q", "client.mode.exit")

-- Panes: resize and move, then keep going in resize mode
rex.bind(PREFIX .. "h", "resize_repeat", { direction = "left" })
rex.bind(PREFIX .. "j", "resize_repeat", { direction = "down" })
rex.bind(PREFIX .. "k", "resize_repeat", { direction = "up" })
rex.bind(PREFIX .. "l", "resize_repeat", { direction = "right" })
rex.bind(PREFIX .. "shift+h", "move_repeat", { direction = "left" })
rex.bind(PREFIX .. "shift+j", "move_repeat", { direction = "down" })
rex.bind(PREFIX .. "shift+k", "move_repeat", { direction = "up" })
rex.bind(PREFIX .. "shift+l", "move_repeat", { direction = "right" })
rex.bind(PREFIX .. "=", "pane.balance")

rex.mode("resize", { exclusive = true })
rex.bind("resize/h", "pane.resize", { direction = "left", amount = 1 })
rex.bind("resize/j", "pane.resize", { direction = "down", amount = 1 })
rex.bind("resize/k", "pane.resize", { direction = "up", amount = 1 })
rex.bind("resize/l", "pane.resize", { direction = "right", amount = 1 })
rex.bind("resize/shift+h", "pane.move.left")
rex.bind("resize/shift+j", "pane.move.down")
rex.bind("resize/shift+k", "pane.move.up")
rex.bind("resize/shift+l", "pane.move.right")
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/q", "client.mode.exit")

-- Panes, tabs, and sessions
-- rex.bind(PREFIX .. "c", "tab_here")
rex.bind(PREFIX .. "z", "pane.zoom")
rex.bind(PREFIX .. "o", "pane.focus_next")
rex.bind(PREFIX .. "x", "pane.close")
rex.bind(PREFIX .. "m", "pane.move_to_new_tab")
rex.bind(PREFIX .. "shift+7", "client.tab.close")
rex.bind(PREFIX .. "n", "client.tab.next")
rex.bind(PREFIX .. "p", "client.tab.previous")
rex.bind(PREFIX .. ",", "client.tab.rename")
rex.bind(PREFIX .. "ctrl+v", "session.rename")
rex.bind(PREFIX .. "ctrl+f", "session.switch")

-- Workspaces and palette commands (actions/workspace.lua, actions/palette.lua)
rex.bind(PREFIX .. "w", "workspace")
rex.bind(PREFIX .. "t", "run_task")
rex.bind(PREFIX .. "d", "dataos_logs")

-- >>> md-viewer: Cmd-F binding (managed by md-viewer setup; edits are replaced) >>>
local function md_viewer_pane(block)
	if block == nil then
		return false
	end
	local terminal = "com.superlogical.terminal"
	local process = rex.block.call(terminal, "process", { block_id = block })
	if process ~= nil then
		return process.foreground ~= nil and process.foreground.name == "md-viewer"
	end
	local listed = rex.session.list_blocks({})
	for _, entry in ipairs((listed or {}).blocks or {}) do
		if entry.block_id == block then
			return entry.label == "md-viewer"
		end
	end
	return false
end

rex.action({
	name = "md_viewer_find",
	title = "Find (md-viewer aware)",
	description = "Opens md-viewer's find in an md-viewer pane and Rex's Find everywhere else.",
	run = function(ctx, args)
		if md_viewer_pane(ctx.block_id) then
			local _, err =
				rex.block.call("com.superlogical.terminal", "write", { block_id = ctx.block_id, data = "\27[102;9u" })
			if err == nil then
				return { target = "md-viewer" }
			end
		end
		rex.client.queue("client.find.open")
		return { target = "rex" }
	end,
})

rex.bind("cmd+f", "md_viewer_find")
-- <<< md-viewer <<<
