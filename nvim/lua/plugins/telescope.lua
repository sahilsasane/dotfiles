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
      local actions = require 'telescope.actions'
      local preview_utils = require 'telescope.previewers.utils'
      local grep_memory = ''
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

      local function with_grep_memory(opts)
        opts = opts or {}

        local user_input_filter = opts.on_input_filter_cb
        opts.default_text = opts.default_text or grep_memory
        opts.on_input_filter_cb = function(prompt)
          grep_memory = prompt
          if user_input_filter then return user_input_filter(prompt) end
        end

        return opts
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

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set(
        'n',
        '<leader>sF',
        function()
          builtin.find_files {
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
      -- vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set(
        'n',
        '<leader>sg',
        function() live_grep_args(with_grep_memory()) end,
        { desc = '[S]earch by [G]rep with [A]rgs' }
      )
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
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
          builtin.live_grep(with_grep_memory {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          })
        end,
        { desc = '[S]earch [/] in Open Files' }
      )

      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
