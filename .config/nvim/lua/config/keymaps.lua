-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("n", ";", ":")
-- vim.keymap.set("n", "<cr>", "<esc>:w!|:TestFile<cr>")
-- vim.keymap.set("n", "<c-x>", "<esc>:Neogit<cr>")
vim.keymap.set("n", "<leader>fy", function()
  local file_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", file_path)
  vim.notify("Copied file path: " .. file_path)
end, { desc = "Copy full file path to clipboard" })

vim.keymap.set("n", "<leader>fN", function()
  vim.cmd("edit /Users/sfistak/GoogleDrive/Grzegorz.Smajdor/devnotes/")
end, { desc = "Open notes folder" })
