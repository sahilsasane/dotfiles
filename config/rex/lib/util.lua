-- Helpers shared by the actions in actions/.
local M = {}

M.SHELL = "com.superlogical.terminal.shell"
M.TERMINAL = "com.superlogical.terminal"
M.CONFIG_DIR = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/rex"

-- Rex calls return (result, err). Turn err into a Lua error.
function M.check(result, err)
	if err ~= nil then
		error(err, 0)
	end
	return result
end

-- The terminal reports its directory as file://host/path.
function M.block_cwd(block_id)
	if block_id == nil then
		return nil
	end
	local r = rex.block.call(M.TERMINAL, "pwd", { block_id = block_id })
	local url = r and r.pwd
	if type(url) ~= "string" then
		return nil
	end
	return (url:gsub("^file://[^/]*", ""))
end

return M
