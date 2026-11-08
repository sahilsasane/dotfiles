-- Run: nvim --headless -u NONE -i NONE -n -l config/nvim/tests/test_git_line_history.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
package.path = config .. '/lua/?.lua;' .. package.path
vim.g.mapleader = ' '
vim.o.columns, vim.o.lines = 180, 65
vim.o.swapfile = false
require 'keymaps'
local history = require 'dotfiles.git_line_history'
local repository = vim.fn.tempname() .. ' history repo'
local path = repository .. "/source's file.lua"
vim.fn.mkdir(repository, 'p')

local notices = {}
vim.notify = function(message) notices[#notices + 1] = message end

local function git(...)
  local result = vim.system(vim.list_extend({ 'git', '-C', repository }, { ... }), { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

local function commit()
  git('add', '.')
  git(
    '-c',
    'user.name=History test',
    '-c',
    'user.email=history@example.invalid',
    '-c',
    'commit.gpgsign=false',
    '-c',
    'core.hooksPath=/dev/null',
    'commit',
    '-qm',
    'HIDDEN COMMIT MESSAGE'
  )
end

local function wait_for(predicate, message) assert(vim.wait(5000, predicate, 10), message .. ': ' .. table.concat(notices, '; ')) end
local function press(keys) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'xt', false) end
local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') end

local function wait_for_history()
  wait_for(function() return vim.bo.buftype == 'terminal' and text():find('local ', 1, true) ~= nil end, 'History did not open')
  return vim.api.nvim_get_current_buf(), vim.b.terminal_job_id
end

local function close_history(source, job)
  vim.api.nvim_chan_send(job, 'q')
  wait_for(function() return vim.api.nvim_get_current_buf() == source and #vim.api.nvim_list_tabpages() == 1 end, 'q did not return to source')
end

local function expect_notice(fragment, callback)
  local count, tabs = #notices, #vim.api.nvim_list_tabpages()
  callback()
  wait_for(function() return #notices > count end, 'Expected notification')
  assert(notices[#notices]:find(fragment, 1, true), notices[#notices])
  assert(#vim.api.nvim_list_tabpages() == tabs, 'Failure opened a tab')
end

local function run()
  git('init', '-q')
  local lines = {}
  for i = 1, 30 do
    lines[i] = '-- context ' .. i
  end
  lines[5], lines[6], lines[25] = 'local token_cache = 1', 'local cache_limit = 10', 'local unrelated = 1'
  lines[12], lines[20] = 'local duplicate = true', 'local duplicate = true'
  vim.fn.writefile(lines, path)
  commit()
  lines[5], lines[6], lines[25] = 'local token_cache = 2', 'local cache_limit = 20', 'local unrelated = 2'
  vim.fn.writefile(lines, path)
  vim.fn.writefile({ 'UNRELATED FILE CONTENT' }, repository .. '/other.txt')
  commit()
  lines[12] = 'local duplicate = false'
  vim.fn.writefile(lines, path)
  commit()
  lines[12] = 'local duplicate = true'
  vim.fn.writefile(lines, path)
  commit()
  table.insert(lines, 1, '-- new committed header')
  table.insert(lines, 1, '-- another committed header')
  lines[7] = 'local token_cache = 3'
  vim.fn.writefile(lines, path)
  commit()

  -- The buffer path is a symlink and Neovim's cwd is outside the repository.
  local link = repository .. '/linked.lua'
  assert(vim.uv.fs_symlink(path, link))
  vim.cmd.edit(vim.fn.fnameescape(link))
  local source = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { 7, 0 })
  press ' gl'
  local terminal, job = wait_for_history()
  wait_for(function() return text():find('local token_cache = 2', 1, true) ~= nil end, 'Missing earlier version')
  assert(not text():find('unrelated', 1, true), 'Unrelated changes leaked into history')
  assert(not text():find('HIDDEN COMMIT MESSAGE', 1, true), 'Commit message was displayed')
  assert(not text():find('Author:', 1, true), 'Commit metadata was displayed')
  close_history(source, job)
  assert(not vim.api.nvim_buf_is_valid(terminal), 'Terminal buffer was left behind')

  -- Unsaved insertions must not move the history to unrelated HEAD lines.
  vim.api.nvim_buf_set_lines(source, 0, 0, false, { '-- unsaved header 1', '-- unsaved header 2', '-- unsaved header 3' })
  vim.api.nvim_win_set_cursor(0, { 11, 0 })
  press 'Vk'
  assert(vim.fn.mode() == 'V', 'Could not create a backwards visual selection')
  press ' gl'
  _, job = wait_for_history()
  wait_for(function() return text():find('local cache_limit = 10', 1, true) ~= nil end, 'Visual range lost its second line')
  assert(not text():find('unrelated', 1, true), 'Dirty buffer selected wrong history')
  close_history(source, job)

  local selected = false
  vim.ui.select = function(items, options, callback)
    assert(#items == 2, 'Duplicate matches were not offered')
    assert(options.format_item(items[2]):find('Lines 22–22:', 1, true), 'Picker lacked HEAD location')
    selected = true
    callback(items[2])
  end
  vim.api.nvim_win_set_cursor(0, { 25, 0 })
  history.open()
  _, job = wait_for_history()
  assert(selected, 'Duplicate occurrence picker was skipped')
  assert(not text():find('duplicate = false', 1, true), 'History used the wrong duplicate')
  close_history(source, job)

  local cancelled = false
  vim.ui.select = function(_, _, callback)
    cancelled = true
    callback(nil)
  end
  history.open()
  wait_for(function() return cancelled end, 'Duplicate picker did not open')
  assert(#vim.api.nvim_list_tabpages() == 1, 'Cancelling opened a history tab')

  vim.api.nvim_buf_set_lines(source, 9, 10, false, { 'local never_committed = true' })
  vim.api.nvim_win_set_cursor(0, { 10, 0 })
  expect_notice('do not match HEAD', history.open)

  local untracked = repository .. '/untracked.lua'
  vim.fn.writefile({ 'local untracked = true' }, untracked)
  vim.cmd.edit(vim.fn.fnameescape(untracked))
  expect_notice('untracked.lua', history.open)
  vim.cmd.enew()
  expect_notice('Open a saved file', history.open)
end

local ok, error_message = xpcall(run, debug.traceback)
for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buffer].buftype == 'terminal' then pcall(vim.api.nvim_buf_delete, buffer, { force = true }) end
end
vim.fn.delete(repository, 'rf')
if not ok then
  io.stderr:write(error_message .. '\n')
  vim.cmd 'cquit 1'
end
print 'Git line history: all checks passed'
vim.cmd 'qa!'
