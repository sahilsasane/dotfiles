return {
  {
    'mfussenegger/nvim-lint',
    ft = 'python',
    config = function()
      local python = require 'dotfiles.python'
      local lint = require 'lint'
      local original_mypy = lint.linters.mypy

      lint.linters.mypy = function()
        local linter = vim.deepcopy(original_mypy)
        local root = python.root(0)
        local project_mypy = root and vim.fs.joinpath(root, '.venv', 'bin', 'mypy')

        if project_mypy and vim.fn.executable(project_mypy) == 1 then linter.cmd = project_mypy end

        return linter
      end

      lint.linters_by_ft = vim.tbl_deep_extend('force', lint.linters_by_ft or {}, {
        python = { 'mypy' },
      })

      vim.api.nvim_create_autocmd('BufWritePost', {
        group = vim.api.nvim_create_augroup('dotfiles-mypy', { clear = true }),
        pattern = '*.py',
        callback = function(event)
          local project = python.for_buffer(event.buf)
          local root = python.root(event.buf)
          local namespace = lint.get_namespace 'mypy'

          if project.type_checker ~= 'mypy' then
            vim.diagnostic.reset(namespace, event.buf)
            return
          end

          vim.api.nvim_buf_call(event.buf, function() require('lint').try_lint('mypy', { cwd = root }) end)
        end,
      })
    end,
  },
}
