-- Background handlers for Rex. launchd keeps this running:
--   rex do ~/.config/rex/scripts/watch.lua --all
--
-- Tab names: each tab is named after the git repo its focused pane is in (its
-- origin remote's name), or the folder when it isn't in a repo.
-- A tab you renamed yourself is left alone.

local HOME = os.getenv("HOME")
local STATE = HOME .. "/.cache/rex-watch-labels.json"

-- window_id -> the label this script last gave it. A window whose label
-- differs from this was renamed by hand, so the script stops touching it.
local ours = {}

local function load_state()
	local file = io.open(STATE)
	if not file then return end
	local ok, value = pcall(rex.json.decode, file:read("*a"))
	file:close()
	if ok and type(value) == "table" then ours = value end
end

local function save_state()
	local file = io.open(STATE, "w")
	if not file then return end
	file:write(rex.json.encode(ours))
	file:close()
end

-- path -> tab name. The shell reports its folder at every prompt, so each
-- folder asks git only once.
local names = {}

-- Inside a git repo: the repo's name from its origin remote, or the repo
-- folder's name without one. Elsewhere: the folder's name; home -> "~".
local function tab_name(url)
	local path = url:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	if names[path] then return names[path] end
	local git = rex.exec({ "git", "-C", path, "rev-parse", "--show-toplevel" }, { timeout = 2 })
	local root = git and git.ok and git.stdout:match("[^\n]+")
	local name
	if root then
		-- git@github.com:org/dataos-yamls.git -> dataos-yamls, else the repo folder.
		local remote = rex.exec({ "git", "-C", root, "remote", "get-url", "origin" }, { timeout = 2 })
		local url = remote and remote.ok and remote.stdout:match("[^\n]+")
		name = url and url:gsub("%.git$", ""):gsub("/$", ""):match("([^/:]+)$") or root:match("([^/]+)/?$")
	elseif path == HOME or path == HOME .. "/" then
		name = "~"
	else
		name = path:match("([^/]+)/?$") or path
	end
	names[path] = name
	return name
end

local function is_default_label(window)
	return window.label == "Window " .. window.window_id:sub(-8)
end

rex.on("terminal.pwd_changed", function(ctx, ev)
	for _, window in ipairs(rex.session.view{}.windows or {}) do
		if window.focused_block_id == ctx.block_id then
			local name = tab_name(ev.pwd)
			local ours_to_change = is_default_label(window) or window.label == ours[window.window_id]
			if window.label ~= name and ours_to_change then
				rex.session.set_window_label{ window_id = window.window_id, label = name }
				ours[window.window_id] = name
				save_state()
			end
			return
		end
	end
end)

rex.on("window_closed", function(ctx, ev)
	if ours[ev.window_id] then
		ours[ev.window_id] = nil
		save_state()
	end
end)

load_state()
