-- Palette commands for the current repo and DataOS:
--   run_task       Makefile target, just recipe, or compose service -> server tab
--   dataos_logs    pick a DataOS resource -> follow its logs in a split
-- The server tab is this session's tab named "server". When it is busy, the
-- command goes to a new split in it, so a running server is never typed into.

local util = require("lib.util")
local check, SHELL, TERMINAL = util.check, util.SHELL, util.TERMINAL
local SHELLS = { zsh = true, bash = true, fish = true, sh = true }
local COMPOSE_FILES = { "compose.yaml", "compose.yml", "docker-compose.yml", "docker-compose.yaml" }
local JUST_FILES = { "justfile", "Justfile", ".justfile" }
local PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
local DATAOS = os.getenv("HOME") .. "/.dataos/v2/bin/dataos-ctl"
local DATAOS_TYPES = "vulcan,service,worker,workflow"

local function exists(path)
	local file = io.open(path)
	if file then file:close() end
	return file ~= nil
end

local function run(argv, timeout)
	local result = rex.exec(argv, { timeout = timeout or 5, env = { PATH = PATH } })
	return result and result.ok and result.stdout or ""
end

local function repo_root(ctx)
	local dir = util.block_cwd(ctx.block_id) or os.getenv("HOME")
	return run({ "git", "-C", dir, "rev-parse", "--show-toplevel" }):match("[^\n]+") or dir
end

local function compose_file(root)
	for _, name in ipairs(COMPOSE_FILES) do
		if exists(root .. "/" .. name) then return root .. "/" .. name end
	end
end

local function compose_services(file)
	local services = {}
	for service in run({ "docker", "compose", "-f", file, "config", "--services" }):gmatch("[^\n]+") do
		services[#services + 1] = service
	end
	return services
end

local function shell_block(cwd, command)
	return rex.layout.block{ flavor = SHELL, options = { cwd = cwd, initial_input = command .. "\r" } }
end

local function run_in_server_tab(root, command)
	for _, window in ipairs(check(rex.session.view{}).windows or {}) do
		if window.label == "server" then
			local block_id = window.focused_block_id
			local process = rex.block.call(TERMINAL, "process", { block_id = block_id })
			local foreground = process and process.foreground and process.foreground.name
			if foreground == nil or SHELLS[foreground] then
				rex.block.call(TERMINAL, "write", { block_id = block_id, data = command .. "\r" })
				check(rex.session.focus_block{ block_id = block_id })
			else
				check(rex.session.new_split{
					anchor_id = block_id, direction = "vertical", side = "after", focus = true, layout = shell_block(root, command),
				})
			end
			return
		end
	end
	check(rex.session.new_window{ window_label = "server", layout = shell_block(root, command) })
end

-- run_task ------------------------------------------------------------------

local function make_targets(root, items)
	local file = io.open(root .. "/Makefile")
	if not file then return end
	local seen = {}
	for line in file:lines() do
		local target = line:match("^([%w][%w_%-%./]*)%s*:")
		if target and not line:match("^[^:]*:=") and not seen[target] then
			seen[target] = true
			items[#items + 1] = { id = "make " .. target, title = target, subtitle = "make", icon = "gear" }
		end
	end
	file:close()
end

local function just_recipes(root, items)
	for _, name in ipairs(JUST_FILES) do
		if exists(root .. "/" .. name) then
			for recipe in run({ "just", "--justfile", root .. "/" .. name, "--summary" }):gmatch("%S+") do
				items[#items + 1] = { id = "just " .. recipe, title = recipe, subtitle = "just", icon = "code" }
			end
			return
		end
	end
end

local function compose_up_items(root, items)
	local file = compose_file(root)
	if not file then return end
	items[#items + 1] = { id = "docker compose up", title = "all services", subtitle = "docker compose up", icon = "server" }
	for _, service in ipairs(compose_services(file)) do
		items[#items + 1] = { id = "docker compose up " .. service, title = service, subtitle = "docker compose up", icon = "server" }
	end
end

rex.action({
	name = "run_task",
	title = "Run Repo Task…",
	keywords = "make just docker compose task target recipe service run server",
	args = { command = "string?" },
	run = function(ctx, args)
		local root = repo_root(ctx)
		local command = args.command
		if command == nil then
			local items = {}
			make_targets(root, items)
			just_recipes(root, items)
			compose_up_items(root, items)
			if #items == 0 then error("No Makefile, justfile, or compose file in " .. root, 0) end
			command = rex.ui.pick{ title = "Run task", placeholder = "Filter tasks in " .. root:match("([^/]+)$"), items = items }
			if command == nil then return end
		end
		run_in_server_tab(root, command)
	end,
})

-- dataos_logs ---------------------------------------------------------------

-- Rows of `ds resource get`: " name | version | type | status | runtime | owner".
-- Continuation rows (more runtime lines) have an empty name and are skipped.
local function dataos_resources(all_owners)
	local argv = { DATAOS, "resource", "get", "--types", DATAOS_TYPES }
	if all_owners then argv[#argv + 1] = "-a" end
	local resources = {}
	for line in run(argv, 30):gsub("\27%[[%d;]*%a", ""):gmatch("[^\n]+") do
		local name, version, kind, status, runtime, owner =
			line:match("^%s*(%S+)%s*|%s*(%S+)%s*|%s*(%S+)%s*|%s*(%S*)%s*|%s*(.-)%s*|%s*(%S*)%s*$")
		if name and name ~= "NAME" then
			resources[#resources + 1] = {
				id = kind .. "|" .. version .. "|" .. name,
				title = name,
				subtitle = kind .. " · " .. owner .. (runtime ~= "" and " · " .. runtime or ""),
				detail = status,
				icon = kind == "service" and "server" or kind == "vulcan" and "database" or "package",
			}
		end
	end
	return resources
end

rex.action({
	name = "dataos_logs",
	title = "DataOS: Follow Resource Logs…",
	keywords = "dataos ds logs resource vulcan service worker workflow",
	run = function(ctx)
		local items = dataos_resources(false)
		for _, item in ipairs(dataos_resources(true)) do
			local mine = false
			for _, own in ipairs(items) do if own.id == item.id then mine = true end end
			if not mine then items[#items + 1] = item end
		end
		if #items == 0 then error("ds found no " .. DATAOS_TYPES .. " resources. Is ds logged in?", 0) end
		local id = rex.ui.pick{ title = "Follow logs", placeholder = "Filter resources (yours first)", items = items }
		if id == nil then return end
		local kind, version, name = id:match("^([^|]+)|([^|]+)|(.+)$")
		check(rex.session.new_split{
			anchor_id = ctx.block_id, direction = "horizontal", side = "after", focus = true,
			layout = shell_block(nil, string.format("ds resource log -t %s -v %s -n %s -f", kind, version, name)),
		})
	end,
})
