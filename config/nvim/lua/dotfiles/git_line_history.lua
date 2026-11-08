local M = {}

local function notify(message, level) vim.notify(message, level or vim.log.levels.WARN, { title = 'Git line history' }) end

local function git(directory, args, callback)
  vim.system(
    vim.list_extend({ 'git', '--no-pager', '-C', directory }, args),
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        notify(vim.trim(result.stderr), vim.log.levels.ERROR)
        return
      end
      callback(result.stdout)
    end)
  )
end

local function show_history(directory, path, patch)
  if patch == '' then
    notify 'No history found for these lines.'
    return
  end

  local patch_file = vim.fn.tempname()
  vim.fn.writefile(vim.split(patch, '\n', { plain = true }), patch_file, 'b')
  vim.cmd.tabnew()
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  vim.bo[buffer].bufhidden = 'wipe'
  vim.bo[buffer].buflisted = false

  local function close()
    if vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == buffer then pcall(vim.api.nvim_win_close, window, true) end
    if vim.api.nvim_buf_is_valid(buffer) then vim.api.nvim_buf_delete(buffer, { force = true }) end
  end

  local job = vim.fn.jobstart({ 'sh', '-c', 'exec delta --side-by-side --navigate --paging=always < "$1"', 'git-line-history', patch_file }, {
    cwd = directory,
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        vim.fn.delete(patch_file)
        if not vim.api.nvim_buf_is_valid(buffer) then return end
        if code == 0 then
          close()
        else
          notify('Delta exited with code ' .. code .. '.', vim.log.levels.ERROR)
        end
      end)
    end,
  })

  if job <= 0 then
    vim.fn.delete(patch_file)
    close()
    notify('Could not start Delta.', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_name(buffer, ('line-history://%d/%s'):format(buffer, vim.fs.basename(path)))
  vim.keymap.set('n', 'q', close, { buffer = buffer, desc = 'Close line history' })
  vim.cmd.startinsert()
end

function M.open()
  for _, executable in ipairs { 'git', 'delta' } do
    if vim.fn.executable(executable) == 0 then
      notify(executable .. ' is required for line history.')
      return
    end
  end

  local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
  if not path or vim.bo.buftype ~= '' then
    notify 'Open a saved file to view its line history.'
    return
  end

  local first, last = vim.fn.line '.', vim.fn.line '.'
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    first, last = math.min(first, vim.fn.line 'v'), math.max(last, vim.fn.line 'v')
    vim.cmd.normal { '\27', bang = true }
  end
  local selection = vim.api.nvim_buf_get_lines(0, first - 1, last, false)

  git(vim.fs.dirname(path), { 'rev-parse', '--show-toplevel', 'HEAD' }, function(output)
    local root, revision = output:match '^(.*)\n(%x+)\n$'
    local relative_path = vim.fs.relpath(root, path)
    git(root, { 'show', revision .. ':' .. relative_path }, function(contents)
      local lines = vim.split(contents, '\n', { plain = true })
      if lines[#lines] == '' then table.remove(lines) end
      local matches = {}
      for start = 1, #lines - #selection + 1 do
        local matches_selection = true
        for offset, line in ipairs(selection) do
          if lines[start + offset - 1] ~= line then
            matches_selection = false
            break
          end
        end
        if matches_selection then matches[#matches + 1] = start end
      end

      if #matches == 0 then
        notify 'Selected lines do not match HEAD. Select text that exists in the current commit.'
        return
      end

      local function trace(start)
        if not start then return end
        local range = ('-L%d,%d:%s'):format(start, start + #selection - 1, relative_path)
        git(root, { 'log', '--color=never', '--format=', range, revision }, function(patch) show_history(root, relative_path, patch) end)
      end

      if #matches == 1 then
        trace(matches[1])
      else
        vim.ui.select(matches, {
          prompt = 'Which occurrence in HEAD?',
          format_item = function(start)
            local context = table.concat(vim.list_slice(lines, math.max(1, start - 1), math.min(#lines, start + #selection)), ' | ')
            return ('Lines %d–%d: %s'):format(start, start + #selection - 1, context)
          end,
        }, trace)
      end
    end)
  end)
end

return M
