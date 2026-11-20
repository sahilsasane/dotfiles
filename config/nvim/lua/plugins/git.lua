return {
  {
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 0,
        virt_text_pos = 'eol',
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        vim.keymap.set('n', '<leader>tD', gitsigns.preview_hunk_inline, {
          buffer = bufnr,
          desc = '[T]oggle show deleted lines',
        })
        vim.keymap.set('n', '<leader>tb', gitsigns.toggle_current_line_blame, {
          buffer = bufnr,
          desc = '[T]oggle line [B]lame',
        })
        -- vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, {
        --   buffer = bufnr,
        --   desc = 'Git [p]review hunk',
        -- })
      end,
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
    },
  },

  {
    'kdheepak/lazygit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'LazyGit', 'LazyGitConfig', 'LazyGitCurrentFile', 'LazyGitFilter', 'LazyGitFilterCurrentFile' },
    init = function()
      -- bin/lg-nvim-edit calls _G.dotfiles_lazygit_open from inside the LazyGit float.
      -- lazygit is suspended while that command runs and discards input typed then, so
      -- the quit key is retried until lazygit exits, and the file opens in the exit
      -- callback once the float has closed.
      local pending
      vim.g.lazygit_on_exit_callback = function()
        if not pending then
          return
        end
        local file, line = pending.file, pending.line
        pending = nil
        vim.cmd.edit(vim.fn.fnameescape(file))
        if line ~= '' then
          vim.cmd(line)
        end
      end

      function _G.dotfiles_lazygit_open(file, line)
        pending = { file = file, line = line }
        local job = vim.b.terminal_job_id
        vim.fn.timer_start(150, function(timer)
          if vim.fn.jobwait({ job }, 0)[1] == -1 then
            vim.fn.chansend(job, 'q')
          else
            vim.fn.timer_stop(timer)
          end
        end, { ['repeat'] = 30 })
      end
    end,
    keys = {
      { '<leader>gg', '<cmd>LazyGit<CR>', desc = 'Open Lazy[G]it' },
    },
  },

  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewToggleFiles',
      'DiffviewFocusFiles',
      'DiffviewRefresh',
    },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<CR>', desc = 'Open [G]it [D]iffview' },
      { '<leader>gD', '<cmd>DiffviewClose<CR>', desc = 'Close [G]it [D]iffview' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'Current file [G]it [H]istory' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = '[G]it Repo [H]istory' },
    },
    opts = {
      enhanced_diff_hl = true,
      use_icons = vim.g.have_nerd_font,
      view = {
        default = { layout = 'diff2_horizontal' },
        file_history = { layout = 'diff2_horizontal' },
      },
      file_panel = {
        win_config = {
          position = 'left',
          width = 36,
        },
      },
    },
  },

  {
    'akinsho/git-conflict.nvim',
    version = '*',
    enabled = function() return vim.g.enable_git_conflict end,
    event = 'BufReadPre',
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = 'copen',
    },
  },
}
