return {
  { 'nvim-treesitter/nvim-treesitter-textobjects' },

  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      enable = true,
      max_lines = 3,
      trim_scope = 'outer',
      mode = 'cursor',
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    config = function()
      vim.treesitter.language.register('bash', 'zsh')

      local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'python', 'go', 'yaml' }
      require('nvim-treesitter').install(parsers)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf, filetype = args.buf, args.match

          local language = vim.treesitter.language.get_lang(filetype)
          if not language then return end

          if not vim.treesitter.language.add(language) then return end
          vim.treesitter.start(buf, language)
          local parser = vim.treesitter.get_parser(buf, language, { error = false })
          if parser then parser:parse() end

          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
