vim.opt.number = true
vim.opt.winborder = "rounded"
vim.opt.swapfile = false
vim.opt.wrap = false
--vim.opt.tabstop = 2
--vim.opt.shiftwidth = 2
--vim.opt.expandtab
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.path = "**"
vim.opt.mouse = ""
vim.g.mapleader = ","
vim.g.fugitive_default_split = 'edit'
vim.opt.clipboard = "unnamedplus"

vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/github/copilot.vim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/tpope/vim-rails" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/tpope/vim-fugitive" },
	{ src = "https://github.com/rose-pine/neovim" },
	{ src = "https://github.com/xiyaowong/transparent.nvim" },
	{ src = 'https://github.com/neovim/nvim-lspconfig' },
	{ src = "https://github.com/echasnovski/mini.nvim" },
	{ src = "https://github.com/tpope/vim-sensible"},
	{ src = "https://github.com/folke/trouble.nvim" },
	{ src = "https://github.com/nvim-pack/nvim-spectre" },
	{ src = "https://github.com/ThePrimeagen/harpoon" },
	{ src = "https://github.com/nvim-neotest/neotest" },
	{ src = "https://github.com/zidhuss/neotest-minitest" },
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/christoomey/vim-tmux-navigator" },
})

require "oil".setup()
require "mason".setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "ruby_lsp" },
})
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "ruby", "javascript" },
  highlight = { enable = true },
})
require "transparent".setup()
require("mini.pick").setup({
  source = {
    files = { preview = true },
    grep_live = { preview = true },
  },
})
require "trouble".setup()
require "spectre".setup()
require "harpoon".setup()
require("neotest").setup({
  adapters = {
    require("neotest-minitest"),
  },
  output_panel = {
    enabled = true,
    open = "botright split | resize 15",
  },
})


require "mini.ai".setup()
require "mini.align".setup()
require "mini.comment".setup()
require "mini.completion".setup()
require "mini.move".setup()
require "mini.operators".setup()
require "mini.pairs".setup()
require "mini.snippets".setup()
require "mini.surround".setup()
require "mini.basics".setup()
require "mini.bracketed".setup()
require "mini.bufremove".setup()
require "mini.diff".setup()
require "mini.extra".setup()
require "mini.git".setup()
require "mini.sessions".setup()
require "mini.indentscope".setup()
require "mini.trailspace".setup()


vim.keymap.set("n", "<leader>f", ":Pick files<CR>")
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>s", ":Pick grep_live<CR>")
vim.keymap.set("n", "<leader>p", ":TypstPreview<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
vim.keymap.set("n", "<leader>e", ":Oil<CR> ")
vim.keymap.set("n", "<leader>E", ":e ~/.config/nvim/init.lua<CR> ")

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>S", '<cmd>lua require("spectre").open()<cr>')
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>")
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
vim.keymap.set("n", "<leader>a", require("harpoon.mark").add_file)
vim.keymap.set("n", "<leader>A", require("harpoon.ui").toggle_quick_menu)
vim.keymap.set("n", "<leader>tt", require("neotest").run.run)
vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end)
vim.keymap.set("n", "<leader>ts", require("neotest").run.stop)
vim.keymap.set("n", "<leader>to", require("neotest").output_panel.toggle)
vim.keymap.set("n", ";", ":")

vim.cmd([[colorscheme rose-pine]])
vim.cmd([[hi statusline guibg=NONE]])


vim.keymap.set('n', 'U', function()
  vim.pack.update()
end, { desc = 'Update plugins' })
