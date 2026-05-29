vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'

vim.o.showmode = false

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 100

vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = {
  tab = '» ',
  lead = '·',
  leadmultispace = '····',
  trail = '·',
  nbsp = '␣',
}

vim.o.inccommand = 'split'

vim.o.cursorline = true

vim.o.scrolloff = 10

vim.o.confirm = true

vim.o.lazyredraw = true

vim.o.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  pattern = '*',
  command = 'checktime',
})
