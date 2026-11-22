-- Repo workspaces: one session per repo with four tabs: nvim, server, claude, misc.
-- Picking a repo whose session already exists switches to it instead.

local util = require("lib.util")
local check, SHELL = util.check, util.SHELL
local ZOXIDE = "/opt/homebrew/bin/zoxide"
local HOME = os.getenv("HOME")

local function shell(cwd, input)
	return rex.layout.block{ flavor = SHELL, options = { cwd = cwd, initial_input = input } }
end

-- Git repos you visit, most-used first, from zoxide's history.
local function repos()
	local result = check(rex.exec({ ZOXIDE, "query", "-l" }, { timeout = 5 }))
	local items = {}
	for dir in result.stdout:gmatch("[^\n]+") do
		local git = io.open(dir .. "/.git")
		if git then
			git:close()
			items[#items + 1] = {
				id = dir, title = dir:match("([^/]+)$"), subtitle = dir:gsub("^" .. HOME, "~"), icon = "folder",
			}
		end
	end
	return items
end

local function session_named(label)
	for _, session in ipairs(check(rex.call("session.list", {})).sessions or {}) do
		if session.label == label then return session.session_id end
	end
end

local function create(dir, name)
	local created = check(rex.call("session.create", {
		label = name,
		initial_windows = {
			{ window_label = "nvim", layout = shell(dir, "nvim\r") },
			{ window_label = "server", layout = shell(dir) },
			{ window_label = "claude", layout = shell(dir) },
			{ window_label = "misc", layout = shell(dir) },
		},
	}))
	return created.session_id, created.initial_windows[1].window_id
end

rex.action({
	name = "workspace",
	title = "Open Repo Workspace…",
	keywords = "repo project workspace session layout nvim",
	args = { dir = "string?" },
	run = function(ctx, args)
		local dir = args.dir or rex.ui.pick{ title = "Open workspace", placeholder = "Filter repos", items = repos() }
		if dir == nil then return end
		local name = dir:match("([^/]+)/?$")
		local session_id, window_id = session_named(name), nil
		if not session_id then session_id, window_id = create(dir, name) end
		rex.client.queue("session.select", { session_id = session_id, window_id = window_id })
	end,
})
