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
      local prompt_memory = {
        find_files = '',
        live_grep = '',
      }

      local function with_prompt_memory(key, opts)
        opts = opts or {}

        local user_input_filter = opts.on_input_filter_cb
        opts.default_text = opts.default_text or prompt_memory[key]
        opts.on_input_filter_cb = function(prompt)
          prompt_memory[key] = prompt
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

      local builtin = require 'telescope.builtin'
      local live_grep_args = telescope.extensions.live_grep_args.live_grep_args

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', function() builtin.find_files(with_prompt_memory('find_files')) end, { desc = '[S]earch [F]iles' })
      vim.keymap.set(
        'n',
        '<leader>sF',
        function()
          builtin.find_files(with_prompt_memory('find_files', {
            no_ignore = true,
            hidden = true,
          }))
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
        function() live_grep_args(with_prompt_memory('live_grep')) end,
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
          builtin.live_grep(with_prompt_memory('live_grep', {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }))
        end,
        { desc = '[S]earch [/] in Open Files' }
      )

      vim.keymap.set('n', '<leader>sn', function() builtin.find_files(with_prompt_memory('find_files', { cwd = vim.fn.stdpath 'config' })) end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
