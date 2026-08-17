return {
  {
    'mfussenegger/nvim-lint',
    ft = 'python',
    config = function()
      local python = require 'dotfiles.python'
      local lint = require 'lint'
      local original_mypy = lint.linters.mypy
      local original_ty = lint.linters.ty or {
        cmd = 'ty',
        stdin = false,
        stream = 'both',
        ignore_exitcode = true,
        args = { 'check', '--output-format', 'concise' },
        parser = require('lint.parser').from_pattern(
          '^(.+):(%d+):(%d+): (%a+)%[([^]]+)%] (.*)$',
          { 'file', 'lnum', 'col', 'severity', 'code', 'message' },
          {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
            info = vim.diagnostic.severity.INFO,
          },
          { ['source'] = 'ty' }
        ),
      }

      local function project_linter(linter, command)
        local configured = vim.deepcopy(linter)
        local root = python.root(0)
        local project_command = root and vim.fs.joinpath(root, '.venv', 'bin', command)

        if project_command and vim.fn.executable(project_command) == 1 then configured.cmd = project_command end

        return configured
      end

      lint.linters.mypy = function() return project_linter(original_mypy, 'mypy') end
      lint.linters.ty = function() return project_linter(original_ty, 'ty') end

      lint.linters_by_ft = vim.tbl_deep_extend('force', lint.linters_by_ft or {}, {
        python = { 'mypy', 'ty' },
      })

      local type_checkers = { 'mypy', 'ty' }
      local function reset_type_checker_diagnostics(bufnr)
        for _, name in ipairs(type_checkers) do
          vim.diagnostic.reset(lint.get_namespace(name), bufnr)
        end
      end

      local function run_type_checker(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'python' then return end

        local project = python.for_buffer(bufnr)
        local root = python.root(bufnr)
        reset_type_checker_diagnostics(bufnr)

        if not vim.tbl_contains(type_checkers, project.type_checker) then return end

        vim.api.nvim_buf_call(bufnr, function() lint.try_lint(project.type_checker, { cwd = root }) end)
      end

      vim.api.nvim_create_autocmd('BufWritePost', {
        group = vim.api.nvim_create_augroup('dotfiles-python-type-checker', { clear = true }),
        pattern = '*.py',
        callback = function(event) run_type_checker(event.buf) end,
      })

      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('dotfiles-python-type-checker-enter', { clear = true }),
        callback = function(event) vim.schedule(function() run_type_checker(event.buf) end) end,
      })

      if vim.bo.filetype == 'python' then vim.schedule(function() run_type_checker(0) end) end
    end,
  },
}
