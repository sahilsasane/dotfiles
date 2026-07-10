return {
  {
    'smjonas/inc-rename.nvim',
    cmd = 'IncRename',
    opts = {},
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {
        'mason-org/mason.nvim',
        ---@module 'mason.settings'
        ---@type MasonSettings
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      local inlay_hints_enabled = true

      local function buffer_supports_method(bufnr, method)
        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
          if client:supports_method(method, bufnr) then return true end
        end

        return false
      end

      local function set_inlay_hints(enabled, bufnr)
        if bufnr ~= nil then
          if buffer_supports_method(bufnr, 'textDocument/inlayHint') then vim.lsp.inlay_hint.enable(enabled, { bufnr = bufnr }) end
          return
        end

        inlay_hints_enabled = enabled

        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buffer) and buffer_supports_method(buffer, 'textDocument/inlayHint') then
            vim.lsp.inlay_hint.enable(enabled, { bufnr = buffer })
          end
        end
      end

      local function toggle_inlay_hints()
        set_inlay_hints(not inlay_hints_enabled)
        vim.notify(string.format('Inlay hints %s', inlay_hints_enabled and 'enabled' or 'disabled'), vim.log.levels.INFO)
      end

      vim.api.nvim_create_user_command('InlayHintsToggle', toggle_inlay_hints, { desc = 'Toggle inlay hints globally' })
      vim.api.nvim_create_user_command('InlayHintsEnable', function() set_inlay_hints(true) end, { desc = 'Enable inlay hints globally' })
      vim.api.nvim_create_user_command('InlayHintsDisable', function() set_inlay_hints(false) end, { desc = 'Disable inlay hints globally' })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local function goto_declaration()
            if buffer_supports_method(event.buf, 'textDocument/declaration') then
              vim.lsp.buf.declaration()
              return
            end

            vim.notify('No attached LSP provides declarations here; jumping to definition instead', vim.log.levels.INFO)
            vim.lsp.buf.definition()
          end

          vim.keymap.set(
            'n',
            'grn',
            function() return ':IncRename ' .. vim.fn.expand '<cword>' end,
            { buffer = event.buf, desc = 'LSP: [R]e[n]ame', expr = true }
          )
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', goto_declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            set_inlay_hints(inlay_hints_enabled, event.buf)
            map('<leader>th', toggle_inlay_hints, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      ---@type table<string, vim.lsp.Config>
      local servers = {
        gopls = {},
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  callArgumentNamesMatching = false,
                  functionReturnTypes = true,
                  genericTypes = true,
                },
              },
            },
          },
        },
        ruff = {},
        ts_ls = {},
        eslint = {},
        taplo = {},
        rust_analyzer = {
          settings = {
            ['rust-analyzer'] = {
              check = {
                command = 'clippy',
              },
            },
          },
        },
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
              },
            })
          end,
          settings = {
            Lua = {},
          },
        },
      }

      local tools = {
        'stylua',
        'prettierd',
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, tools)

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      formatters = {
        jq_jsonl = {
          command = 'jq',
          args = { '-M', '-c', '.' },
        },
      },
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 2000,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        rust = { 'rustfmt' },
        toml = { 'taplo' },
        lua = { 'stylua' },
        python = { 'ruff_organize_imports', 'ruff_fix', 'ruff_format' },
        go = { 'goimports', 'gofmt' },
        javascript = { 'prettierd', stop_after_first = true },
        javascriptreact = { 'prettierd', stop_after_first = true },
        typescript = { 'prettierd', stop_after_first = true },
        typescriptreact = { 'prettierd', stop_after_first = true },
        json = { 'prettierd', stop_after_first = true },
        jsonl = { 'jq_jsonl' },
        css = { 'prettierd', stop_after_first = true },
        scss = { 'prettierd', stop_after_first = true },
        html = { 'prettierd', stop_after_first = true },
        markdown = { 'prettierd', stop_after_first = true },
      },
    },
  },
}
