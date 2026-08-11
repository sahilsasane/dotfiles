return {
  {
    'mfussenegger/nvim-dap',
    cmd = {
      'DapContinue',
      'DapNew',
      'DapStepInto',
      'DapStepOut',
      'DapStepOver',
      'DapTerminate',
      'DapToggleBreakpoint',
    },
    keys = {
      {
        '<leader>db',
        function() require('dap').toggle_breakpoint() end,
        desc = '[D]ebug: Toggle [B]reakpoint',
      },
      {
        '<leader>dc',
        function() require('dap').continue() end,
        desc = '[D]ebug: [C]ontinue',
      },
      {
        '<leader>di',
        function() require('dap').step_into() end,
        desc = '[D]ebug: Step [I]nto',
      },
      {
        '<leader>do',
        function() require('dap').step_over() end,
        desc = '[D]ebug: Step [O]ver',
      },
      {
        '<leader>dO',
        function() require('dap').step_out() end,
        desc = '[D]ebug: Step [O]ut',
      },
      {
        '<leader>dt',
        function() require('dap').terminate() end,
        desc = '[D]ebug: [T]erminate',
      },
      {
        '<leader>dr',
        function() require('dap').run_last() end,
        desc = '[D]ebug: [R]un last',
      },
      {
        '<leader>du',
        function() require('dapui').toggle() end,
        desc = '[D]ebug: Toggle [U]I',
      },
    },
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        dependencies = { 'nvim-neotest/nvim-nio' },
        opts = {},
      },
      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'mason-org/mason.nvim' },
        opts = {
          ensure_installed = { 'python' },
          handlers = {
            python = function(config)
              config.configurations = {
                {
                  type = 'python',
                  request = 'launch',
                  name = 'Launch current file',
                  program = '${file}',
                  cwd = function() return vim.fn.getcwd() end,
                  pythonPath = function()
                    local project_python = vim.fn.getcwd() .. '/.venv/bin/python'
                    if vim.fn.executable(project_python) == 1 then return project_python end

                    return vim.fn.exepath 'python3'
                  end,
                  console = 'integratedTerminal',
                  justMyCode = true,
                },
              }

              require('mason-nvim-dap').default_setup(config)
            end,
          },
        },
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dap.listeners.before.attach.dotfiles_dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dotfiles_dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dotfiles_dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dotfiles_dapui_config = function() dapui.close() end
    end,
  },
}
