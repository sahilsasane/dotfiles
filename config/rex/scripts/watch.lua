-- Background handlers for Rex. launchd keeps this running:
--   rex do ~/.config/rex/scripts/watch.lua --all
--
-- Tab names: each tab is named after the folder its focused pane is in.
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

-- "file://host/Users/me/my%20repo" -> "my repo"; the home folder -> "~".
local function folder_name(url)
	local path = url:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	if path == HOME or path == HOME .. "/" then return "~" end
	return path:match("([^/]+)/?$") or path
end

local function is_default_label(window)
	return window.label == "Window " .. window.window_id:sub(-8)
end

rex.on("terminal.pwd_changed", function(ctx, ev)
	for _, window in ipairs(rex.session.view{}.windows or {}) do
		if window.focused_block_id == ctx.block_id then
			local name = folder_name(ev.pwd)
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
