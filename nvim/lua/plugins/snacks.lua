local file_excludes = { '.venv', '.env', 'node_modules' }
local project_root_markers = { '.git', 'pyproject.toml', 'package.json', 'Cargo.toml', 'go.mod' }

local function git_statuses(cwd)
  if vim.fn.executable 'git' ~= 1 then return {} end

  local output = vim.fn.systemlist { 'git', '-C', cwd, 'status', '--porcelain=v1', '--untracked-files=all' }
  if vim.v.shell_error ~= 0 then return {} end

  local statuses = {}
  for _, line in ipairs(output) do
    local code = line:sub(1, 2)
    local path = line:sub(4)
    if code:find 'R' or code:find 'C' then path = path:match '.* -> (.*)' or path end
    statuses[vim.fs.normalize(path)] = code
  end
  return statuses
end

local function with_excludes(opts) return vim.tbl_deep_extend('force', { exclude = file_excludes }, opts or {}) end

local function files(opts)
  opts = with_excludes(opts)
  local cwd = opts.cwd or vim.uv.cwd()
  local statuses = git_statuses(cwd)
  local transform = opts.transform
  opts.transform = function(item, ctx)
    local path = vim.fs.normalize(item.file or item.text)
    local root = vim.fs.normalize(item.cwd or cwd)
    if path:sub(1, #root + 1) == root .. '/' then path = path:sub(#root + 2) end
    item.status = statuses[path]
    return transform and transform(item, ctx) or item
  end
  Snacks.picker.files(opts)
end

local function grep(opts) Snacks.picker.grep(with_excludes(opts)) end

local function grep_word() Snacks.picker.grep_word(with_excludes()) end

local function project_marks()
  local root = vim.fs.root(vim.api.nvim_buf_get_name(0), project_root_markers) or vim.uv.cwd()
  Snacks.picker.marks { cwd = root, filter = { cwd = root } }
end

local function map_lsp_picker(buf, lhs, picker, desc)
  vim.keymap.set('n', lhs, function() picker() end, { buffer = buf, desc = desc })
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        sources = {
          files = {
            args = { '--full-path' },
          },
        },
        layout = {
          layout = {
            box = 'horizontal',
            width = 0.85,
            min_width = 120,
            height = 0.9,
            backdrop = false,
            {
              box = 'vertical',
              width = 0.50,
              border = 'rounded',
              title = '{title} {live} {flags}',
              title_pos = 'center',
              { win = 'input', height = 1, border = 'bottom' },
              { win = 'list', border = 'none' },
            },
            {
              win = 'preview',
              title = '{preview}',
              width = 0.50,
              border = 'rounded',
              title_pos = 'center',
            },
          },
        },
        ui_select = true,
        win = {
          input = {
            keys = {
              ['<C-y>'] = { 'history_back', mode = { 'i', 'n' } },
              ['<C-e>'] = { 'history_forward', mode = { 'i', 'n' } },
            },
          },
        },
      },
    },
    keys = {
      { '<leader>sf', files, desc = '[S]earch [F]iles' },
      { '<leader>sF', function() files { hidden = true, ignored = true } end, desc = '[S]earch all [F]iles' },
      { '<leader>sg', grep, desc = '[S]earch by [G]rep' },
      { '<leader>sw', grep_word, mode = { 'n', 'v' }, desc = '[S]earch current [W]ord' },
      { '<leader>s/', function() Snacks.picker.grep_buffers(with_excludes { title = 'Live Grep in Open Files' }) end, desc = '[S]earch open files' },
      { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search current buffer' },
      { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = '[S]earch document [S]ymbols' },
      { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = '[S]earch workspace [S]ymbols' },
      { '<leader>sm', project_marks, desc = '[S]earch project [M]arks' },
      { '<leader>sM', function() Snacks.picker.marks() end, desc = '[S]earch all [M]arks' },
      { '<leader>sp', function() Snacks.picker() end, desc = '[S]earch picker list' },
      { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
      { '<leader>gs', function() Snacks.picker.git_status() end, desc = '[G]it [S]tatus' },
      { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
      { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch recent files' },
      { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
      { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
      { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
      { '<leader><leader>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },
      { '<leader>sn', function() files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
    },
    config = function(_, opts)
      require('snacks').setup(opts)

      local group = vim.api.nvim_create_augroup('snacks-lsp-picker-mappings', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(event)
          local buf = event.buf
          map_lsp_picker(buf, 'grr', Snacks.picker.lsp_references, '[G]oto [R]eferences')
          map_lsp_picker(buf, 'gri', Snacks.picker.lsp_implementations, '[G]oto [I]mplementation')
          map_lsp_picker(buf, 'grd', Snacks.picker.lsp_definitions, '[G]oto [D]efinition')
          map_lsp_picker(buf, 'gO', Snacks.picker.lsp_symbols, 'Open document symbols')
          map_lsp_picker(buf, 'gW', Snacks.picker.lsp_workspace_symbols, 'Open workspace symbols')
          map_lsp_picker(buf, 'grt', Snacks.picker.lsp_type_definitions, '[G]oto [T]ype definition')
        end,
      })
    end,
  },
}
