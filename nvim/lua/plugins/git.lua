return {
  {
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 0,
        virt_text_pos = 'eol',
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        vim.keymap.set('n', '<leader>tD', gitsigns.preview_hunk_inline, {
          buffer = bufnr,
          desc = '[T]oggle show deleted lines',
        })
        vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, {
          buffer = bufnr,
          desc = 'Git [p]review hunk',
        })
      end,
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
    },
  },

  {
    'kdheepak/lazygit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'LazyGit', 'LazyGitConfig', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<CR>', desc = 'Open Lazy[G]it' },
    },
  },
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    enabled = function() return vim.g.enable_git_conflict end,
    event = 'BufReadPre',
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = 'copen',
    },
  },
}
