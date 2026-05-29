return {
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {},
        opts = {},
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        ['<Tab>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
        ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 500,
          window = { border = 'rounded' },
        },
        menu = { auto_show = true, auto_show_delay_ms = 0 },
      },
      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
        },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = {
        enabled = true,
        trigger = {
          enabled = true,
          show_on_trigger_character = true,
          show_on_insert = true,
          show_on_insert_on_trigger_character = true,
        },
        window = {
          border = 'rounded',
          show_documentation = false,
        },
      },
    },
  },
}
