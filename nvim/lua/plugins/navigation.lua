return {
  {
    'mikavilpas/yazi.nvim',
    version = '*',
    lazy = false,
    dependencies = { { 'nvim-lua/plenary.nvim', lazy = true } },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      open_for_directories = true,
      integrations = {
        grep_in_directory = 'snacks.picker',
        grep_in_selected_files = 'snacks.picker',
      },
    },
    keys = {
      { '-', '<cmd>Yazi<cr>', desc = 'Open Yazi at current file' },
      { '<leader>e', '<cmd>Yazi<cr>', desc = 'Open Yazi [E]xplorer' },
    },
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end)
      vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

      vim.keymap.set('n', '<C-h>', function() harpoon:list():select(1) end)
      vim.keymap.set('n', '<C-t>', function() harpoon:list():select(2) end)
      vim.keymap.set('n', '<C-n>', function() harpoon:list():select(3) end)
      vim.keymap.set('n', '<C-s>', function() harpoon:list():select(4) end)
    end,
  },

  {
    'stevearc/aerial.nvim',
    cmd = {
      'AerialToggle',
      'AerialOpen',
      'AerialClose',
      'AerialNavToggle',
      'AerialNavOpen',
      'AerialNavClose',
      'AerialNext',
      'AerialPrev',
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>o', '<cmd>AerialToggle! right<CR>', desc = 'Toggle code outline' },
      { ']a', '<cmd>AerialNext<CR>', desc = 'Next symbol' },
      { '[a', '<cmd>AerialPrev<CR>', desc = 'Previous symbol' },
    },
    opts = {
      backends = { 'treesitter', 'lsp', 'markdown', 'asciidoc', 'man' },
      layout = {
        default_direction = 'right',
        max_width = { 40, 0.2 },
        min_width = 20,
      },
      highlight_on_jump = 300,
      close_on_select = true,
      show_guides = true,
    },
  },
}
