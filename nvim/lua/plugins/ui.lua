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
            NormalNC = { fg = colors.text },

            ['@comment'] = { fg = colors.overlay1, style = { 'italic' } },
            CursorLine = { bg = colors.mantle, blend = 99 },
            LspInlayHint = { fg = colors.overlay0, style = { 'italic' } },

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
            StatusLine = { fg = colors.text, bg = colors.mantle },
            StatusLineNC = { fg = colors.overlay1, bg = colors.mantle },
            MiniStatuslineGit = { fg = colors.green, bg = colors.none, style = { 'bold' } },
            MiniStatuslineDevinfo = { fg = colors.overlay1, bg = colors.mantle },
            MiniStatuslineFileinfo = { fg = colors.overlay1, bg = colors.mantle },
            MiniStatuslineFilename = { fg = colors.text, bg = colors.mantle },
            MiniStatuslineInactive = { fg = colors.overlay1, bg = colors.mantle },

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
      require('mini.pairs').setup()
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      local project_root_markers = {
        '.git',
        'pyproject.toml',
        'package.json',
        'Cargo.toml',
        'go.mod',
      }

      local function escape_statusline_text(text) return text:gsub('%%', '%%%%') end

      local function active_statusline()
        local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
        local diff = statusline.section_diff { trunc_width = 75, icon = '' }
        local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
        local lsp = statusline.section_lsp { trunc_width = 75 }
        local filename = statusline.section_filename { trunc_width = 140 }
        local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
        local location = statusline.section_location { trunc_width = 75 }
        local search = statusline.section_searchcount { trunc_width = 75 }

        return statusline.combine_groups {
          { hl = mode_hl, strings = { mode } },
          { hl = 'MiniStatuslineGit', strings = { diff } },
          { hl = 'MiniStatuslineDevinfo', strings = { diagnostics, lsp } },
          '%<',
          { hl = 'MiniStatuslineFilename', strings = { filename } },
          '%=',
          { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
          { hl = mode_hl, strings = { search, location } },
        }
      end

      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = active_statusline,
        },
      }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        if vim.bo.buftype == 'terminal' then return '%t' end

        local path = vim.api.nvim_buf_get_name(0)
        if path == '' then return '[No Name]%m%r' end

        local root = vim.fs.root(0, project_root_markers) or vim.uv.cwd()
        local relative_path = root and vim.fs.relpath(root, path) or nil
        local display_path = relative_path or vim.fn.fnamemodify(path, ':~:.')

        return escape_statusline_text(display_path) .. '%m%r'
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.inactive = function()
        return statusline.combine_groups {
          { hl = 'MiniStatuslineInactive', strings = { statusline.section_filename() } },
          '%=',
        }
      end
    end,
  },
}
