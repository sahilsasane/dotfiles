return {
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '│',
        tab_char = '│',
        highlight = 'IblIndent',
      },
      whitespace = {
        highlight = 'IblWhitespace',
        remove_blankline_trail = false,
      },
      scope = {
        enabled = true,
        char = '│',
        highlight = 'IblScope',
        show_start = false,
        show_end = false,
        include = {
          node_type = {
            python = {
              'argument_list',
              'call',
              'try_statement',
              'if_statement',
              'for_statement',
              'while_statement',
              'with_statement',
            },
          },
        },
      },
      exclude = {
        buftypes = { 'nofile', 'prompt', 'quickfix', 'terminal' },
        filetypes = { 'help', 'lazy', 'mason', 'oil', 'qf' },
      },
    },
  },

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
            Whitespace = { fg = colors.surface0 },

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
            StatusLine = { fg = colors.text, bg = colors.crust },
            StatusLineNC = { fg = colors.overlay1, bg = colors.crust },
            BlinkCmpSignatureHelp = { fg = colors.text, bg = colors.crust },
            BlinkCmpSignatureHelpBorder = { fg = colors.surface1, bg = colors.crust },
            IblIndent = { fg = colors.surface1 },
            IblWhitespace = { fg = colors.surface0 },
            IblScope = { fg = colors.overlay1 },
            MiniStatuslineGit = { fg = colors.green, bg = colors.none, style = { 'bold' } },
            MiniStatuslineDevinfo = { fg = colors.overlay1, bg = colors.crust },
            MiniStatuslineFileinfo = { fg = colors.overlay1, bg = colors.crust },
            MiniStatuslineFilename = { fg = colors.text, bg = colors.crust },
            MiniStatuslineInactive = { fg = colors.overlay1, bg = colors.crust },
            MiniStarterHeader = { fg = colors.lavender, style = { 'bold' } },
            MiniStarterSection = { fg = colors.rosewater, style = { 'bold' } },
            MiniStarterItem = { fg = colors.text },
            MiniStarterItemBullet = { fg = colors.surface1 },
            MiniStarterItemPrefix = { fg = colors.sky, style = { 'bold' } },
            MiniStarterCurrent = { fg = colors.peach, style = { 'bold' } },
            MiniStarterFooter = { fg = colors.overlay1, style = { 'italic' } },
            MiniStarterQuery = { fg = colors.yellow, style = { 'bold' } },

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
      local starter = require 'mini.starter'
      local uv = vim.uv or vim.loop

      local function starter_recent_files()
        local cwd = uv.cwd()
        if not cwd then
          return {
            { name = 'No recent files available', action = '', section = 'RECENT' },
          }
        end

        local sep = package.config:sub(1, 1)
        local cwd_prefix = cwd:sub(-1) == sep and cwd or (cwd .. sep)
        local items = {}

        for _, path in ipairs(vim.v.oldfiles) do
          if vim.fn.filereadable(path) == 1 and vim.startswith(path, cwd_prefix) then
            local filename = vim.fn.fnamemodify(path, ':t')
            local relative = vim.fs.relpath(cwd, path) or vim.fn.fnamemodify(path, ':.')

            table.insert(items, {
              action = function() vim.cmd.edit(vim.fn.fnameescape(path)) end,
              name = string.format('%-24s %s', filename, relative),
              section = 'RECENT',
            })

            if #items >= 6 then break end
          end
        end

        if #items == 0 then
          return {
            { name = 'No recent files in this workspace yet', action = '', section = 'RECENT' },
          }
        end

        return items
      end

      starter.setup {
        evaluate_single = true,
        header = table.concat({
          ' _   _                 _           ',
          '| \\ | | _____   ___   (_)_ __ ___  ',
          "|  \\| |/ _ \\ \\ / / | | | | '_ ` _ \\ ",
          '| |\\  |  __/\\ V /| |_| | | | | | |',
          '|_| \\_|\\___| \\_/  \\__,_|_| |_| |_|',
          '',
          ' open what matters',
        }, '\n'),
        footer = 'query to filter  •  <CR> open  •  <Esc> reset',
        items = {
          {
            {
              name = '  Restore session',
              action = "lua require('persistence').load()",
              section = 'SESSION',
            },
            {
              name = '󰁯  Restore last session',
              action = "lua require('persistence').load({ last = true })",
              section = 'SESSION',
            },
            {
              name = '󰍉  Select session',
              action = "lua require('persistence').select()",
              section = 'SESSION',
            },
          },
          {
            {
              name = '  Find files',
              action = 'Telescope find_files',
              section = 'COMMAND',
            },
            {
              name = '󰱼  Live grep',
              action = "lua require('telescope').extensions.live_grep_args.live_grep_args()",
              section = 'COMMAND',
            },
            {
              name = '  Recent files',
              action = 'Telescope oldfiles',
              section = 'COMMAND',
            },
            {
              name = '  Config files',
              action = "lua require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })",
              section = 'COMMAND',
            },
            {
              name = '  File explorer',
              action = 'Oil',
              section = 'COMMAND',
            },
            {
              name = '󰊢  LazyGit',
              action = 'LazyGit',
              section = 'COMMAND',
            },
            {
              name = '󰒲  Plugin manager',
              action = 'Lazy',
              section = 'COMMAND',
            },
            {
              name = '󰗼  Quit',
              action = 'qa',
              section = 'COMMAND',
            },
          },
          starter_recent_files,
        },
        content_hooks = {
          starter.gen_hook.indexing('all', { 'RECENT', 'SESSION' }),
          starter.gen_hook.padding(0, 1),
          starter.gen_hook.aligning('center', 'center'),
        },
      }

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
