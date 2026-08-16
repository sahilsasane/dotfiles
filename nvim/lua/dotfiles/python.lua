local M = {}

local project_options = {
  'dotfiles_python_lsp',
  'dotfiles_python_type_checker',
}

local lsp_names = {
  basedpyright = 'basedpyright',
  none = false,
  jedi = 'jedi_language_server',
  pyright = 'pyright',
  ruff = 'ruff',
  ['ruff-lsp'] = 'ruff',
}

local type_checker_names = {
  lsp = true,
  none = true,
  mypy = true,
  ty = true,
}

local root_markers = {
  'pyproject.toml',
  'setup.py',
  'setup.cfg',
  'requirements.txt',
  'Pipfile',
  '.git',
}

local function read_project_options(root)
  local path = vim.fs.joinpath(root, '.nvim.lua')
  local content = vim.secure.read(path)
  if type(content) ~= 'string' then return {} end

  local options = {}
  local sandbox = {
    vim = {
      cmd = function() end,
      g = setmetatable({}, {
        __newindex = function(_, key, value)
          for _, allowed_key in ipairs(project_options) do
            if key == allowed_key then options[key] = value end
          end
        end,
      }),
    },
  }

  local chunk, load_error = load(content, '@' .. path, 't', sandbox)
  if not chunk then
    vim.notify(string.format('Could not load project Neovim config %s: %s', path, load_error), vim.log.levels.WARN)
    return {}
  end

  local ok, run_error = pcall(chunk)
  if not ok then
    vim.notify(string.format('Could not read Python settings from %s: %s', path, run_error), vim.log.levels.WARN)
    return {}
  end

  return options
end

function M.root(bufnr) return vim.fs.root(bufnr, root_markers) end

function M.for_root(root)
  local options = root and read_project_options(root) or {}
  local lsp = options.dotfiles_python_lsp or 'basedpyright'
  if lsp_names[lsp] == nil then
    vim.notify(string.format('Unsupported project Python LSP %q; using basedpyright', lsp), vim.log.levels.WARN)
    lsp = 'basedpyright'
  end

  local type_checker = options.dotfiles_python_type_checker or 'lsp'
  if not type_checker_names[type_checker] then
    vim.notify(string.format('Unsupported project Python type checker %q; using lsp', type_checker), vim.log.levels.WARN)
    type_checker = 'lsp'
  end

  return {
    lsp = lsp_names[lsp],
    type_checker = type_checker,
  }
end

function M.for_buffer(bufnr) return M.for_root(M.root(bufnr)) end

function M.root_dir_for(server_name)
  return function(bufnr, on_dir)
    local root = M.root(bufnr)
    if root and M.for_root(root).lsp == server_name then on_dir(root) end
  end
end

return M
