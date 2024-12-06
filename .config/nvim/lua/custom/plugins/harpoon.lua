return {
  'ThePrimeagen/harpoon',
  config = function()
    vim.api.nvim_set_keymap('n', ',a', ':lua require("harpoon.mark").add_file()<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', ',l', ':lua require("harpoon.ui").toggle_quick_menu()<CR>', { noremap = true, silent = true })
  end,
}
