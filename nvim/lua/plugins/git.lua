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
    'sindrets/diffview.nvim',
    enabled = function() return vim.g.enable_diffview end,
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
      'DiffviewRefresh',
    },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Open [G]it [D]iffview' },
      { '<leader>gD', '<cmd>DiffviewClose<CR>', desc = 'Close [G]it [D]iffview' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'Current file [G]it [H]istory' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = '[G]it Repo [H]istory' },
    },
    opts = {
      enhanced_diff_hl = true,
      use_icons = vim.g.have_nerd_font,
      view = {
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
      file_panel = {
        win_config = {
          position = 'left',
          width = 36,
        },
      },
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
