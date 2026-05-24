return {
  { 'NMAC427/guess-indent.nvim', opts = {} },

  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    keys = {
      {
        '<leader>rs',
        function() require('persistence').load() end,
        desc = '[R]estore [S]ession',
      },
      {
        '<leader>rS',
        function() require('persistence').select() end,
        desc = '[R]estore [S]ession (Select)',
      },
      {
        '<leader>rl',
        function() require('persistence').load { last = true } end,
        desc = '[R]estore [L]ast Session',
      },
      {
        '<leader>rd',
        function() require('persistence').stop() end,
        desc = '[R]equest session save [D]isable',
      },
    },
  },

  {
    'MagicDuck/grug-far.nvim',
    keys = {
      {
        '<leader>sR',
        function() require('grug-far').open() end,
        mode = 'n',
        desc = '[S]earch and [R]eplace',
      },
      {
        '<leader>sR',
        function() require('grug-far').with_visual_selection() end,
        mode = 'x',
        desc = '[S]earch and [R]eplace selection',
      },
    },
  },

  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    config = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      require('ufo').setup {
        provider_selector = function(_, filetype, buftype) return { 'treesitter', 'indent' } end,
      }

      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
      vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds)
      vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith)
    end,
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>g', group = 'Git' },
        { '<leader>r', group = 'Session' },
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>x', group = 'Diagnostics' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols' },
      { '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP List' },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List' },
    },
    opts = {
      focus = false,
      win = { type = 'split', position = 'right' },
    },
  },

  {
    'stevearc/quicker.nvim',
    ft = 'qf',
    opts = {
      keys = {
        {
          '>',
          function() require('quicker').expand { before = 2, after = 2, add_to_existing = true } end,
          desc = 'Expand quickfix context',
        },
        {
          '<',
          function() require('quicker').collapse() end,
          desc = 'Collapse quickfix context',
        },
      },
    },
  },

  {
    'Wansmer/treesj',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      {
        '<leader>m',
        function() require('treesj').toggle() end,
        desc = 'Toggle split/join under cursor',
      },
    },
    opts = {
      use_default_keymaps = false,
    },
  },

  {
    'chrisgrieser/nvim-spider',
    enabled = function() return vim.g.enable_spider_motions end,
    keys = {
      { 'w', "<cmd>lua require('spider').motion('w')<CR>", mode = { 'n', 'o', 'x' } },
      { 'e', "<cmd>lua require('spider').motion('e')<CR>", mode = { 'n', 'o', 'x' } },
      { 'b', "<cmd>lua require('spider').motion('b')<CR>", mode = { 'n', 'o', 'x' } },
      { 'ge', "<cmd>lua require('spider').motion('ge')<CR>", mode = { 'n', 'o', 'x' } },
    },
    opts = {},
  },
}
