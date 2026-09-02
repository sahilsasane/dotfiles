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
      local inlay_hints_enabled = false
      local python_diagnostics_enabled = true
      local python_diagnostic_servers = {
        basedpyright = true,
        jedi_language_server = true,
        mypy = true,
        pyright = true,
        ruff = true,
        ty = true,
      }
      local python = require 'dotfiles.python'

      local function is_python_diagnostics_client(client) return python_diagnostic_servers[client.name] == true end

      local function is_python_diagnostic(diagnostic)
        local source = string.lower(diagnostic.source or '')
        return python_diagnostic_servers[source] == true
      end

      local python_lint_names = { mypy = true, ty = true }
      local function is_lint_diagnostic(diagnostic)
        local source = string.lower(diagnostic.source or '')
        if not python_lint_names[source] then return false end

        local ok, lint = pcall(require, 'lint')
        return ok and diagnostic.namespace == lint.get_namespace(source)
      end

      local function is_lsp_diagnostic(diagnostic) return not is_lint_diagnostic(diagnostic) end

      local function set_python_diagnostics(enabled, bufnr)
        local namespaces = {}
        local use_lsp_diagnostics = python.for_buffer(bufnr).type_checker == 'lsp'

        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
          if is_python_diagnostics_client(client) then
            local namespace = vim.lsp.diagnostic.get_namespace(client.id)
            namespaces[namespace] = enabled and use_lsp_diagnostics
          end
        end

        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
          if is_python_diagnostic(diagnostic) then
            namespaces[diagnostic.namespace] = enabled and (not is_lsp_diagnostic(diagnostic) or use_lsp_diagnostics)
          end
        end

        for ns_id, namespace_enabled in pairs(namespaces) do
          vim.diagnostic.enable(namespace_enabled, { bufnr = bufnr, ns_id = ns_id })
        end
      end

      local function toggle_python_diagnostics()
        python_diagnostics_enabled = not python_diagnostics_enabled

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == 'python' then set_python_diagnostics(python_diagnostics_enabled, bufnr) end
        end

        if package.loaded['trouble'] then require('trouble').refresh 'diagnostics' end

        vim.notify(string.format('Python LSP diagnostics %s', python_diagnostics_enabled and 'enabled' or 'disabled'), vim.log.levels.INFO)
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('dotfiles-python-diagnostics-keymap', { clear = true }),
        pattern = 'python',
        callback = function(event)
          vim.keymap.set('n', '<leader>tw', toggle_python_diagnostics, {
            buffer = event.buf,
            desc = 'LSP: [T]oggle Python diagnostics',
          })
        end,
      })

      vim.api.nvim_create_autocmd('DiagnosticChanged', {
        group = vim.api.nvim_create_augroup('dotfiles-python-diagnostics', { clear = true }),
        callback = function(event)
          if vim.bo[event.buf].filetype ~= 'python' then return end

          local use_lsp_diagnostics = python.for_buffer(event.buf).type_checker == 'lsp'

          for _, diagnostic in ipairs(event.data.diagnostics or {}) do
            if is_python_diagnostic(diagnostic) then
              local enabled = python_diagnostics_enabled and (not is_lsp_diagnostic(diagnostic) or use_lsp_diagnostics)
              vim.diagnostic.enable(enabled, { bufnr = event.buf, ns_id = diagnostic.namespace })
            end
          end
        end,
      })

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
        group = vim.api.nvim_create_augroup('dotfiles-lsp-attach', { clear = true }),
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
            local highlight_augroup = vim.api.nvim_create_augroup('dotfiles-lsp-highlight', { clear = false })
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
              group = vim.api.nvim_create_augroup('dotfiles-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'dotfiles-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            set_inlay_hints(inlay_hints_enabled, event.buf)
            map('<leader>th', toggle_inlay_hints, '[T]oggle Inlay [H]ints')
          end

          if client and vim.bo[event.buf].filetype == 'python' and is_python_diagnostics_client(client) then
            set_python_diagnostics(python_diagnostics_enabled, event.buf)
          end
        end,
      })

      ---@type table<string, vim.lsp.Config>
      local python_servers = {
        basedpyright = {
          root_dir = python.root_dir_for 'basedpyright',
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
        jedi_language_server = { root_dir = python.root_dir_for 'jedi_language_server' },
        pyright = { root_dir = python.root_dir_for 'pyright' },
        ruff = { root_dir = python.root_dir_for 'ruff' },
        ty = { root_dir = python.root_dir_for 'ty' },
      }

      local servers = {
        basedpyright = python_servers.basedpyright,
        gopls = {
          settings = {
            gopls = {
              hints = {
                parameterNames = true,
              },
            },
          },
        },
        jedi_language_server = python_servers.jedi_language_server,
        pyright = python_servers.pyright,
        ruff = python_servers.ruff,
        ty = python_servers.ty,
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

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
        integrations = { ['mason-nvim-dap'] = false },
      }

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
        if vim.b[bufnr].conform_skip_format_once then
          vim.b[bufnr].conform_skip_format_once = nil
          return
        end

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
