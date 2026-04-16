vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-j>', '<C-e>', { desc = 'Scroll down by one line' })
vim.keymap.set('n', '<C-k>', '<C-y>', { desc = 'Scroll up by one line' })

vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center' })

vim.keymap.set('n', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('v', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })

vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result and center' })

vim.keymap.set('n', '{', '{zz')
vim.keymap.set('n', '}', '}zz')

vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move line down' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move line up' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
vim.keymap.set('v', '<leader>d', '"_d', { desc = 'Delete without overwriting register' })

-- Window navigation
vim.keymap.set('n', '<leader>h', '<C-w>h', { desc = 'Focus left window' })
vim.keymap.set('n', '<leader>l', '<C-w>l', { desc = 'Focus right window' })
vim.keymap.set('n', '<leader>j', '<C-w>j', { desc = 'Focus lower window' })
vim.keymap.set('n', '<leader>k', '<C-w>k', { desc = 'Focus upper window' })
vim.keymap.set('n', '<leader>c', '<C-w>c', { desc = 'Close current split' })

vim.keymap.set('n', '<leader>v', ':vsp<CR>', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>s', ':sp<CR>', { desc = 'Horizontal split' })

vim.keymap.set('n', '<leader>L', ':vertical resize +2<CR>', { desc = 'Resize split right' })
vim.keymap.set('n', '<leader>H', ':vertical resize -2<CR>', { desc = 'Resize split left' })
vim.keymap.set('n', '<leader>K', ':resize +2<CR>', { desc = 'Resize split down' })
vim.keymap.set('n', '<leader>J', ':resize -2<CR>', { desc = 'Resize split up' })

vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Equalize splits' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.o.winborder = 'rounded'

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-hover', { clear = true }),
  callback = function(event) vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = event.buf, desc = 'LSP: Hover Documentation' }) end,
})
