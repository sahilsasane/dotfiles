return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha',
        transparent_background = true,
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          keywords = { 'italic' },
          functions = { 'bold' },
          types = { 'bold' },
        },
        custom_highlights = function(colors)
          return {
            NormalFloat = { bg = colors.crust },
            FloatBorder = { bg = colors.crust, fg = colors.lavender },
            NormalNC = { fg = colors.overlay0 },

            ['@comment'] = { fg = colors.overlay1, style = { 'italic' } },
            CursorLine = { bg = colors.mantle, blend = 99 },

            TelescopeNormal = { bg = colors.none },
            TelescopeBorder = { bg = colors.none, fg = colors.surface1 },
            TelescopePromptNormal = { bg = colors.none },
            TelescopePromptBorder = { bg = colors.none, fg = colors.surface1 },
            TelescopeResultsNormal = { bg = colors.none },
            TelescopeResultsBorder = { bg = colors.none, fg = colors.surface1 },
            TelescopePreviewNormal = { bg = colors.none },
            TelescopePreviewBorder = { bg = colors.none, fg = colors.surface1 },
            TelescopeSelection = { bg = colors.surface0 },

            CursorLineNr = { fg = colors.yellow, style = { 'bold' } },
            WinSeparator = { fg = colors.surface2 },

            OilDir = { fg = colors.lavender, style = { 'bold' } },
            OilFile = { fg = colors.text },
            OilLink = { fg = colors.mauve },
            OilCopy = { fg = colors.green },
            OilMove = { fg = colors.yellow },
            OilChange = { fg = colors.peach },
            OilCreate = { fg = colors.green },
            OilDelete = { fg = colors.red },
          }
        end,
        integrations = {
          telescope = { enabled = true },
          gitsigns = true,
          mini = { enabled = true },
          which_key = true,
          blink_cmp = true,
          mason = true,
          fidget = true,
          native_lsp = {
            enabled = true,
            underlines = {
              errors = { 'underline' },
              hints = {},
              warnings = { 'underline' },
              information = {},
            },
          },
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },

  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup {
        n_lines = 500,
        custom_textobjects = {
          f = require('mini.ai').gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
        },
      }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },
}
