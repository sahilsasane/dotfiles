return {
  {
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      {
        'nvim-telescope/telescope-live-grep-args.nvim',
        version = '^1.0.0',
      },
    },
    config = function()
      require('nvim-web-devicons').setup {
        override_by_extension = {
          yaml = { icon = '', color = '#D70000', name = 'Yaml' },
          yml = { icon = '', color = '#D70000', name = 'Yml' },
        },
      }

      local actions = require 'telescope.actions'
      local preview_utils = require 'telescope.previewers.utils'
      local telescope_image
      local image_extensions = {
        avif = true,
        gif = true,
        jpeg = true,
        jpg = true,
        png = true,
        webp = true,
      }

      local function clear_telescope_image()
        if not telescope_image then return end
        pcall(telescope_image.clear, telescope_image)
        telescope_image = nil
      end

      local function is_image_file(filepath)
        if type(filepath) ~= 'string' then return false end
        local extension = vim.fn.fnamemodify(filepath, ':e'):lower()
        return image_extensions[extension] == true
      end

      local function render_telescope_image(filepath, bufnr, opts)
        clear_telescope_image()

        if not is_image_file(filepath) then return false end

        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.bo[bufnr].modifiable = true
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '' })
        end

        local created, image = pcall(require('image').from_file, filepath, {
          buffer = bufnr,
          window = opts.winid,
          max_width_window_percentage = 90,
          max_height_window_percentage = 90,
          namespace = 'telescope',
        })

        if created and image then
          telescope_image = image
          local rendered = pcall(image.render, image)
          if rendered then return true end
          clear_telescope_image()
        end

        preview_utils.set_preview_message(bufnr, opts.winid, 'Image preview failed')
        return true
      end

      local function telescope_filetype_hook(filepath, bufnr, opts)
        return not render_telescope_image(filepath, bufnr, opts)
      end

      local function telescope_mime_hook(filepath, bufnr, opts)
        if render_telescope_image(filepath, bufnr, opts) then return end
        preview_utils.set_preview_message(bufnr, opts.winid, 'Binary cannot be previewed')
      end

      require('telescope').setup {
        defaults = {
          history = {
            handler = function()
              return require('telescope.picker_history').new()
            end,
          },
          preview = {
            filetype_hook = telescope_filetype_hook,
            mime_hook = telescope_mime_hook,
          },
          mappings = {
            i = {
              ['<C-y>'] = actions.cycle_history_prev,
              ['<C-e>'] = actions.cycle_history_next,
            },
          },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      local telescope = require 'telescope'
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(telescope.load_extension, 'live_grep_args')

      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('telescope-image-preview', { clear = true }),
        pattern = 'TelescopePreviewerLoaded',
        callback = function(event)
          if not vim.api.nvim_buf_is_valid(event.buf) then return end

          local window = vim.fn.bufwinid(event.buf)
          if window == -1 then return end

          local filepath = event.data and event.data.bufname
          if not is_image_file(filepath) then
            clear_telescope_image()
            return
          end

          local absolute_path = vim.fn.fnamemodify(filepath, ':p')
          if
            telescope_image
            and telescope_image.is_rendered
            and telescope_image.buffer == event.buf
            and telescope_image.window == window
            and telescope_image.original_path == absolute_path
          then
            return
          end

          render_telescope_image(filepath, event.buf, { winid = window })
        end,
      })

      local builtin = require 'telescope.builtin'
      local live_grep_args = telescope.extensions.live_grep_args.live_grep_args
      local make_entry = require 'telescope.make_entry'

      vim.api.nvim_set_hl(0, 'TelescopeGitStatusModified', { fg = '#E5C07B' })
      vim.api.nvim_set_hl(0, 'TelescopeGitStatusAdded', { fg = '#98C379' })
      vim.api.nvim_set_hl(0, 'TelescopeGitStatusDeleted', { fg = '#E06C75' })
      vim.api.nvim_set_hl(0, 'TelescopeGitStatusRenamed', { fg = '#C678DD' })
      vim.api.nvim_set_hl(0, 'TelescopeGitStatusUntracked', { fg = '#56B6C2' })

      local function git_statuses(cwd)
        if vim.fn.executable 'git' ~= 1 then return {} end

        local output = vim.fn.systemlist {
          'git',
          '-C',
          cwd,
          'status',
          '--porcelain=v1',
          '--untracked-files=all',
        }
        if vim.v.shell_error ~= 0 then return {} end

        local statuses = {}
        for _, line in ipairs(output) do
          local code = line:sub(1, 2)
          local path = line:sub(4)
          if code:find 'R' or code:find 'C' then
            path = path:match '.* -> (.*)' or path
          end
          path = vim.fs.normalize(path)

          local status = code == '??' and '??' or code:gsub('%s', '')
          statuses[path] = status
        end
        return statuses
      end

      local function find_files_with_git_status(opts)
        opts = opts or {}
        local cwd = vim.fn.fnamemodify(opts.cwd or vim.uv.cwd(), ':p')
        local statuses = git_statuses(cwd)
        local base_entry_maker = make_entry.gen_from_file(opts)

        opts.entry_maker = function(line)
          local entry = base_entry_maker(line)
          if not entry then return end

          entry.git_status = statuses[vim.fs.normalize(entry.value)] or ''
          local base_display = entry.display
          entry.display = function(item)
            local path, path_highlights = base_display(item)
            local status_highlight = item.git_status == '' and nil
              or item.git_status == '??' and 'TelescopeGitStatusUntracked'
              or item.git_status:find 'D' and 'TelescopeGitStatusDeleted'
              or item.git_status:find 'A' and 'TelescopeGitStatusAdded'
              or item.git_status:find '[RC]' and 'TelescopeGitStatusRenamed'
              or 'TelescopeGitStatusModified'
            local prefix = string.format('%-2s ', item.git_status)

            if path_highlights then
              local shifted_highlights = {}
              for _, highlight in ipairs(path_highlights) do
                shifted_highlights[#shifted_highlights + 1] = {
                  { highlight[1][1] + #prefix, highlight[1][2] + #prefix },
                  highlight[2],
                }
              end
              path_highlights = shifted_highlights
            end

            if status_highlight then
              table.insert(path_highlights or {}, 1, { { 0, 2 }, status_highlight })
            end

            return prefix .. path, path_highlights
          end
          return entry
        end

        builtin.find_files(opts)
      end

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', find_files_with_git_status, { desc = '[S]earch [F]iles' })
      vim.keymap.set(
        'n',
        '<leader>sF',
        function()
          find_files_with_git_status {
            no_ignore = true,
            hidden = true,
          }
        end,
        { desc = '[S]earch all [F]iles' }
      )
      vim.keymap.set('n', '<leader>ss', builtin.lsp_document_symbols, { desc = '[S]earch document [S]ymbols' })
      vim.keymap.set('n', '<leader>sS', builtin.lsp_dynamic_workspace_symbols, { desc = '[S]earch workspace [S]ymbols' })
      vim.keymap.set('n', '<leader>sp', builtin.builtin, { desc = '[S]earch Telescope [P]ickers' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set(
        'n',
        '<leader>sg',
        live_grep_args,
        { desc = '[S]earch by [G]rep with [A]rgs' }
      )
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      vim.keymap.set(
        'n',
        '<leader>/',
        function()
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        { desc = '[/] Fuzzily search in current buffer' }
      )

      vim.keymap.set(
        'n',
        '<leader>s/',
        function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[S]earch [/] in Open Files' }
      )

      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
