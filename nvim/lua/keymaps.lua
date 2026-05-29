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
vim.keymap.set('n', '<leader>sl', ':sp<CR>', { desc = 'Horizontal split' })

vim.keymap.set('n', '<leader>L', ':vertical resize +2<CR>', { desc = 'Resize split right' })
vim.keymap.set('n', '<leader>H', ':vertical resize -2<CR>', { desc = 'Resize split left' })
vim.keymap.set('n', '<leader>K', ':resize +2<CR>', { desc = 'Resize split down' })
vim.keymap.set('n', '<leader>J', ':resize -2<CR>', { desc = 'Resize split up' })

vim.keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Equalize splits' })

local function reload_config()
  local config_dir = vim.fn.stdpath 'config'

  assert(loadfile(config_dir .. '/lua/options.lua'))()
  assert(loadfile(config_dir .. '/lua/keymaps.lua'))()

  local ok, reloader = pcall(require, 'lazy.manage.reloader')
  if ok then reloader.reload {
    { file = config_dir .. '/init.lua', what = 'changed' },
  } end

  vim.schedule(function() vim.notify('Neovim config reloaded', vim.log.levels.INFO) end)
end

pcall(vim.api.nvim_del_user_command, 'ReloadConfig')
pcall(vim.api.nvim_del_user_command, 'Rlc')
vim.api.nvim_create_user_command('ReloadConfig', reload_config, { desc = 'Reload Neovim config' })
vim.api.nvim_create_user_command('Rlc', reload_config, { desc = 'Reload Neovim config' })
vim.keymap.set('n', '<leader>tr', reload_config, { desc = '[T]ools: [R]eload config' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

local function apply_nearest_inlay_hint()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local hints = vim.lsp.inlay_hint.get {
    bufnr = bufnr,
    range = {
      start = { line = row, character = 0 },
      ['end'] = { line = row, character = math.max(vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]:len(), col + 1) },
    },
  }

  local nearest = nil
  local distance = math.huge

  for _, hint in ipairs(hints) do
    local hint_row = hint.inlay_hint.position.line
    local hint_col = hint.inlay_hint.position.character
    if hint_row == row then
      local delta = math.abs(hint_col - col)
      if delta < distance then
        nearest = hint
        distance = delta
      end
    end
  end

  if not nearest then
    vim.notify('No inlay hint found on this line', vim.log.levels.INFO)
    return
  end

  local client = vim.lsp.get_client_by_id(nearest.client_id)
  if not client then
    vim.notify('LSP client for inlay hint is no longer attached', vim.log.levels.WARN)
    return
  end

  local resolved_hint = nearest.inlay_hint
  if not resolved_hint.textEdits then
    local response = client:request_sync('inlayHint/resolve', resolved_hint, 500, bufnr)
    if response and response.result then resolved_hint = response.result end
  end

  if not resolved_hint.textEdits or vim.tbl_isempty(resolved_hint.textEdits) then
    vim.notify('This inlay hint cannot be inserted', vim.log.levels.INFO)
    return
  end

  vim.lsp.util.apply_text_edits(resolved_hint.textEdits, bufnr, client.offset_encoding)
end

vim.o.winborder = 'rounded'

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-hover', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = event.buf, desc = 'LSP: Hover Documentation' })
    vim.keymap.set('n', '<leader>ti', apply_nearest_inlay_hint, { buffer = event.buf, desc = 'LSP: Insert nearest [T]ype [I]nlay hint' })
  end,
})
