local M = {}
local state_dir = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')) .. '/dotfiles-theme'
local effective_file = state_dir .. '/effective'
local watcher

function M.effective()
  local lines = vim.fn.readfile(effective_file)
  return lines[1] == 'light' and 'light' or 'dark'
end

function M.apply()
  local mode = M.effective()
  if M.configure then
    M.configure(mode)
  else
    vim.o.background = mode
    if vim.g.colors_name == 'catppuccin' then vim.cmd.colorscheme 'catppuccin' end
  end
end

function M.watch()
  if watcher then return end
  if vim.fn.isdirectory(state_dir) == 0 then return end
  watcher = (vim.uv or vim.loop).new_fs_event()
  watcher:start(state_dir, {}, vim.schedule_wrap(function(_, filename)
    if filename == 'effective' then M.apply() end
  end))
end

function M.command()
  vim.api.nvim_create_user_command('Theme', function(args)
    local controller = vim.fn.expand('~/.local/bin/dotfiles-theme')
    local result = vim.fn.system({ controller, args.args == '' and 'status' or args.args })
    if vim.v.shell_error ~= 0 then
      vim.notify(vim.trim(result), vim.log.levels.ERROR)
      return
    end
    M.apply()
    vim.notify(vim.trim(result))
  end, { nargs = '?', complete = function() return { 'light', 'dark', 'auto', 'toggle', 'status' } end })
end

return M
