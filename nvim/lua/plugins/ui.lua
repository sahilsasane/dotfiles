local function setup_image_preview(_, opts)
  require('image').setup(opts)

  -- ImageMagick's SVG delegate does not resolve currentColor. Keep the source
  -- SVG reusable by the web app, but give image.nvim a terminal-colored copy
  -- when it rasterizes an SVG for Kitty.
  local processor = require('image/processors').get_processor(opts.processor)
  local original_transform = processor.transform
  local preview_dir = vim.fn.stdpath 'cache' .. '/image.nvim-svg'

  local function preview_svg_path(path)
    if type(path) ~= 'string' or not path:lower():match '%.svg$' then return path end
    if vim.fn.filereadable(path) == 0 then return path end

    local source = table.concat(vim.fn.readfile(path), '\n')
    if not source:find('currentColor', 1, true) then return path end

    local color = vim.o.background == 'light' and '#4c4f69' or '#cdd6f4'
    local cache_key = vim.fn.sha256(path .. ':' .. vim.fn.getftime(path) .. ':' .. color)
    local preview_path = preview_dir .. '/' .. cache_key .. '.svg'
    if vim.fn.filereadable(preview_path) == 0 then
      vim.fn.mkdir(preview_dir, 'p')
      vim.fn.writefile(vim.split(source:gsub('currentColor', color), '\n', { plain = true }), preview_path)
    end
    return preview_path
  end

  processor.transform = function(path, request, output_path, callback) return original_transform(preview_svg_path(path), request, output_path, callback) end
end

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
        filetypes = { 'help', 'lazy', 'mason', 'yazi', 'qf' },
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
    '3rd/image.nvim',
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
      scale_factor = 3.0,
      window_overlap_clear_enabled = true,
      tmux_show_only_in_active_window = true,
      integrations = { markdown = { download_remote_images = false } },
      hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif', '*.svg' },
    },
    config = setup_image_preview,
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      local theme = require 'dotfiles_theme'
      local catppuccin_options = {
        flavour = 'auto',
        background = { light = 'latte', dark = 'mocha' },
        transparent_background = theme.effective() == 'dark',
        no_italic = false,
        no_bold = false,
        no_underline = false,
        styles = {
          conditionals = {},
          functions = {},
          keywords = {},
          loops = {},
          types = {},
        },
        custom_highlights = function(colors)
          return {
            NormalFloat = { bg = colors.crust },
            FloatBorder = { bg = colors.crust, fg = colors.lavender },
            NormalNC = { fg = colors.text },

            ['@comment'] = { fg = colors.overlay1, style = { 'italic' } },
            ['@function.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@function.call.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@function.method.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@function.method.call.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@lsp.type.function.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@lsp.type.method.go'] = { fg = colors.blue, style = { 'italic' } },
            ['@lsp.type.parameter.go'] = { fg = colors.maroon, style = { 'italic' } },
            ['@variable.parameter.go'] = { fg = colors.maroon, style = { 'italic' } },
            CursorLine = { bg = colors.mantle, blend = 99 },
            LspInlayHint = { fg = colors.overlay0, bg = colors.none },
            SymbolUsage = { fg = colors.overlay0 },
            Whitespace = { fg = colors.surface0 },

            SnacksPicker = { bg = colors.none, fg = colors.text },
            SnacksPickerBorder = { bg = colors.none, fg = colors.surface1 },
            SnacksPickerTitle = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
            SnacksPickerFooter = { bg = colors.none, fg = colors.overlay0 },
            SnacksPickerCursorLine = { bg = colors.surface0 },
            SnacksPickerBox = { bg = colors.none },
            SnacksPickerBoxBorder = { bg = colors.none, fg = colors.surface1 },
            SnacksPickerBoxTitle = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
            SnacksPickerInput = { bg = colors.none, fg = colors.text },
            SnacksPickerInputBorder = { bg = colors.none, fg = colors.blue },
            SnacksPickerInputTitle = { bg = colors.none, fg = colors.blue, style = { 'bold' } },
            SnacksPickerInputCursorLine = { bg = colors.none },
            SnacksPickerList = { bg = colors.none, fg = colors.text },
            SnacksPickerListBorder = { bg = colors.none, fg = colors.surface1 },
            SnacksPickerListCursorLine = { bg = colors.surface0 },
            SnacksPickerPreview = { bg = colors.none, fg = colors.text },
            SnacksPickerPreviewBorder = { bg = colors.none, fg = colors.surface1 },
            SnacksPickerPreviewTitle = { bg = colors.none, fg = colors.sky, style = { 'bold' } },
            SnacksPickerPreviewCursorLine = { bg = colors.none },
            SnacksPickerPrompt = { fg = colors.lavender, bg = colors.none, style = { 'bold' } },
            SnacksPickerInputSearch = { fg = colors.yellow, bg = colors.none, style = { 'bold' } },
            SnacksPickerMatch = { fg = colors.peach, style = { 'bold' } },
            SnacksPickerSelected = { fg = colors.lavender, style = { 'bold' } },
            SnacksPickerGitStatusAdded = { fg = colors.green },
            SnacksPickerGitStatusModified = { fg = colors.yellow },
            SnacksPickerGitStatusDeleted = { fg = colors.red },
            SnacksPickerGitStatusRenamed = { fg = colors.mauve },
            SnacksPickerGitStatusUntracked = { fg = colors.sky },

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
            WinSeparator = { fg = colors.surface1 },
            StatusLine = { fg = colors.text, bg = colors.none },
            StatusLineNC = { fg = colors.overlay1, bg = colors.none },
            LspReferenceText = { bg = colors.none, style = { 'underline' } },
            LspReferenceRead = { bg = colors.none, style = { 'underline' } },
            LspReferenceWrite = { bg = colors.none, style = { 'underline' } },
            BlinkCmpSignatureHelp = { fg = colors.text, bg = colors.crust },
            BlinkCmpSignatureHelpBorder = { fg = colors.surface1, bg = colors.crust },
            IblIndent = { fg = colors.surface1 },
            IblWhitespace = { fg = colors.surface0 },
            IblScope = { fg = colors.surface2 },
            Folded = { fg = colors.overlay1, bg = colors.none },
            UfoFoldedFg = { fg = colors.overlay1 },
            UfoFoldedDelimiters = { fg = colors.sky, bg = colors.none, style = { 'bold' } },
            UfoFoldedEllipsis = { fg = colors.overlay1, bg = colors.none },
            MiniStatuslineGit = { fg = colors.green, bg = colors.none, style = { 'bold' } },
            MiniStatuslineDevinfo = { fg = colors.overlay1, bg = colors.none },
            MiniStatuslineFileinfo = { fg = colors.overlay1, bg = colors.none },
            MiniStatuslineFilename = { fg = colors.text, bg = colors.none },
            MiniStatuslineInactive = { fg = colors.overlay1, bg = colors.none },
            MiniStatuslineBubbleModeNormalEdge = { fg = colors.blue, bg = colors.none },
            MiniStatuslineBubbleModeInsertEdge = { fg = colors.green, bg = colors.none },
            MiniStatuslineBubbleModeVisualEdge = { fg = colors.mauve, bg = colors.none },
            MiniStatuslineBubbleModeReplaceEdge = { fg = colors.red, bg = colors.none },
            MiniStatuslineBubbleModeCommandEdge = { fg = colors.yellow, bg = colors.none },
            MiniStatuslineBubbleModeOtherEdge = { fg = colors.sky, bg = colors.none },
            MiniStatuslineBubbleGit = { fg = colors.green, bg = colors.surface0, style = { 'bold' } },
            MiniStatuslineBubbleGitEdge = { fg = colors.surface0, bg = colors.none },
            MiniStatuslineBubbleDevinfo = { fg = colors.overlay1, bg = colors.surface0 },
            MiniStatuslineBubbleDevinfoEdge = { fg = colors.surface0, bg = colors.none },
            MiniStatuslineBubbleLocation = { fg = colors.base, bg = colors.blue, style = { 'bold' } },
            MiniStatuslineBubbleLocationEdge = { fg = colors.blue, bg = colors.none },
            MiniStarterHeader = { fg = colors.lavender, style = { 'bold' } },
            MiniStarterSection = { fg = colors.rosewater, style = { 'bold' } },
            MiniStarterItem = { fg = colors.text },
            MiniStarterItemBullet = { fg = colors.surface1 },
            MiniStarterItemPrefix = { fg = colors.sky, style = { 'bold' } },
            MiniStarterCurrent = { fg = colors.peach, style = { 'bold' } },
            MiniStarterFooter = { fg = colors.overlay1, style = { 'italic' } },
            MiniStarterQuery = { fg = colors.yellow, style = { 'bold' } },

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
      theme.configure = function(mode)
        catppuccin_options.transparent_background = mode == 'dark'
        vim.o.background = mode
        require('catppuccin').setup(catppuccin_options)
        vim.cmd.colorscheme 'catppuccin'
      end
      theme.apply()
      theme.watch()
      theme.command()
    end,
  },

  {
    'nvim-mini/mini.nvim',
    config = function()
      local starter = require 'mini.starter'

      starter.setup {
        evaluate_single = true,
        header = [[
██╗   ██╗██╗   ██╗██╗███╗   ███╗
███╗  ██║██║   ██║██║████╗ ████║
██╔██╗██║╚██╗ ██╔╝██║██╔████╔██║
██║╚████║ ╚████╔╝ ██║██║╚██╔╝██║
██║ ╚███║  ╚██╔╝  ██║██║ ╚═╝ ██║
╚═╝  ╚══╝   ╚═╝   ╚═╝╚═╝     ╚═╝

 enter quietly
]],
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
              action = 'lua Snacks.picker.files()',
              section = 'COMMAND',
            },
            {
              name = '󰱼  Live grep',
              action = 'lua Snacks.picker.grep()',
              section = 'COMMAND',
            },
            {
              name = '  Recent files',
              action = 'lua Snacks.picker.recent()',
              section = 'COMMAND',
            },
            {
              name = '  Config files',
              action = 'lua Snacks.picker.files({ cwd = vim.fn.stdpath("config") })',
              section = 'COMMAND',
            },
            {
              name = '  File explorer',
              action = 'Yazi',
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
        },
        content_hooks = {
          starter.gen_hook.indexing('all', { 'RECENT', 'SESSION' }),
          starter.gen_hook.padding(0, 1),
          starter.gen_hook.aligning('center', 'center'),
        },
      }

      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('mini-starter-navigation', { clear = true }),
        pattern = 'MiniStarterOpened',
        callback = function(event)
          vim.keymap.set('n', 'j', function() starter.update_current_item 'next' end, { buffer = event.buf, silent = true })
          vim.keymap.set('n', 'k', function() starter.update_current_item 'prev' end, { buffer = event.buf, silent = true })
        end,
      })

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

      local mode_edge_highlights = {
        MiniStatuslineModeNormal = 'MiniStatuslineBubbleModeNormalEdge',
        MiniStatuslineModeInsert = 'MiniStatuslineBubbleModeInsertEdge',
        MiniStatuslineModeVisual = 'MiniStatuslineBubbleModeVisualEdge',
        MiniStatuslineModeReplace = 'MiniStatuslineBubbleModeReplaceEdge',
        MiniStatuslineModeCommand = 'MiniStatuslineBubbleModeCommandEdge',
      }

      local function bubble(text, highlight, edge_highlight)
        if text == '' then return '' end
        return string.format('%%#%s#%%#%s# %s %%#%s#', edge_highlight, highlight, text, edge_highlight)
      end

      local function join_bubbles(parts)
        return table.concat(vim.tbl_filter(function(part) return part ~= '' end, parts), ' ')
      end

      local function format_project_relative_path(path)
        local root = vim.fs.root(path, project_root_markers) or vim.uv.cwd()
        return (root and vim.fs.relpath(root, path)) or vim.fn.fnamemodify(path, ':~:.')
      end

      local function active_statusline()
        local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
        local diff = statusline.section_diff { trunc_width = 75, icon = '' }
        local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
        local lsp = statusline.section_lsp { trunc_width = 75 }
        local filename = statusline.section_filename { trunc_width = 140 }
        local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
        local location = statusline.section_location { trunc_width = 75 }
        local search = statusline.section_searchcount { trunc_width = 75 }

        local devinfo = table.concat(vim.tbl_filter(function(part) return part ~= '' end, { diagnostics, lsp }), ' ')
        local location_info = table.concat(vim.tbl_filter(function(part) return part ~= '' end, { search, location }), ' ')
        local left = join_bubbles {
          bubble(mode, mode_hl, mode_edge_highlights[mode_hl] or 'MiniStatuslineBubbleModeOtherEdge'),
          bubble(diff, 'MiniStatuslineBubbleGit', 'MiniStatuslineBubbleGitEdge'),
          bubble(devinfo, 'MiniStatuslineBubbleDevinfo', 'MiniStatuslineBubbleDevinfoEdge'),
        }

        return table.concat {
          left,
          '%<%#MiniStatuslineFilename#',
          filename,
          '%=',
          '%#MiniStatuslineFileinfo#',
          fileinfo,
          bubble(location_info, 'MiniStatuslineBubbleLocation', 'MiniStatuslineBubbleLocationEdge'),
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

        local display_path = format_project_relative_path(path)

        return escape_statusline_text(display_path) .. '%m%r'
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.inactive = function() return '%#MiniStatuslineInactive#' .. statusline.section_filename() .. '%=' end
    end,
  },
}
