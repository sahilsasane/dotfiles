-- A read-only scrollback viewer, loaded independently of the editor's plugins.
vim.o.loadplugins = false
vim.o.modeline = false
vim.o.exrc = false
vim.o.swapfile = false
vim.o.undofile = false
vim.o.backup = false
vim.o.writebackup = false
vim.o.number = false
vim.o.relativenumber = false
vim.o.signcolumn = "no"
vim.o.wrap = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.mouse = "a"
vim.o.virtualedit = "block"
vim.o.laststatus = 2
vim.o.statusline = " Copy Mode | v/V/C-v select  s jump  y copy  q close%=%l/%L "

vim.keymap.set({ "n", "x", "o" }, "s", function()
  vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/flash.nvim")
  require("flash").jump()
end, { desc = "Flash jump" })

vim.keymap.set({ "n", "x" }, "q", "<Cmd>qa!<CR>", { silent = true })
vim.keymap.set("n", "<Esc>", "<Cmd>qa!<CR>", { silent = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    vim.bo.buftype = "nofile"
    vim.bo.modifiable = false
    vim.cmd("normal! G$")
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local event = vim.v.event
    if event.operator ~= "y" then return end
    local text = table.concat(event.regcontents, "\n")
    if event.regtype == "V" then text = text .. "\n" end
    -- Wait for the clipboard write before the overlay's process exits.
    local output = vim.fn.system({ "pbcopy" }, text)
    if vim.v.shell_error ~= 0 then
      vim.notify("Could not copy to clipboard: " .. output, vim.log.levels.ERROR)
      return
    end
    vim.schedule(function() vim.cmd("qa!") end)
  end,
})
