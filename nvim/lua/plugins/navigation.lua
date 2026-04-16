return {
  {
    'preservim/nerdtree',
    dependencies = {
      'ryanoasis/vim-devicons',
      'Xuyuanp/nerdtree-git-plugin',
    },
    cmd = { 'NERDTreeToggle', 'NERDTreeFind' },
    keys = {
      {
        '<leader>n',
        function()
          if vim.bo.filetype == 'oil' then
            vim.cmd 'NERDTreeToggle'
          else
            vim.cmd 'NERDTreeFind'
            vim.cmd 'wincmd p'
          end
        end,
        desc = 'Reveal current file in NERDTree',
      },
    },
    init = function()
      vim.g.NERDTreeShowHidden = 1
      vim.g.NERDTreeMinimalUI = 1
      vim.g.NERDTreeDirArrows = 1
      vim.g.NERDTreeWinSize = 30
      vim.g.NERDTreeQuitOnOpen = 1
    end,
  },

  -- {
  --   'karb94/neoscroll.nvim',
  --   config = function()
  --     local neoscroll = require 'neoscroll'
  --
  --     neoscroll.setup {
  --       mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>' },
  --       post_hook = function() vim.cmd 'normal! zz' end,
  --     }
  --
  --     local t = {
  --       ['<C-u>'] = { 'scroll', { '-vim.wo.scroll', 'true', '250' } },
  --       ['<C-d>'] = { 'scroll', { 'vim.wo.scroll', 'true', '250' } },
  --       ['<C-b>'] = { 'scroll', { '-vim.api.nvim_win_get_height(0)', 'true', '450' } },
  --       ['<C-f>'] = { 'scroll', { 'vim.api.nvim_win_get_height(0)', 'true', '450' } },
  --     }
  --
  --     require('neoscroll.config').set_mappings(t)
  --   end,
  -- },

  {
    'stevearc/oil.nvim',
    lazy = false,
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    config = function()
      local oil = require 'oil'

      oil.setup {
        default_file_explorer = true,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 1,
          max_width = 0.65,
          max_height = 0.75,
          border = 'rounded',
        },
        win_options = {
          signcolumn = 'no',
          wrap = false,
        },
      }

      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
      vim.keymap.set('n', '<leader>e', function() oil.toggle_float() end, { desc = 'Toggle file [E]xplorer (float)' })
    end,
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
}
