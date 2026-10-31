return {
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      notify = { enabled = false },
      lsp = { progress = { enabled = false } },
      presets = { long_message_to_split = true },
      views = {
        cmdline_popup = {
          position = { row = 3, col = '50%' },
        },
      },
    },
  },
}
