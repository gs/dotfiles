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
vim.opt.clipboard = "unnamedplus"

vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/github/copilot.vim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/olimorris/codecompanion.nvim" },
	{ src = "https://github.com/tpope/vim-rails" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/tpope/vim-fugitive" },
	{ src = "https://github.com/rose-pine/neovim" },
	{ src = "https://github.com/xiyaowong/transparent.nvim" },
	{ src = 'https://github.com/neovim/nvim-lspconfig' },
	{ src = "https://github.com/echasnovski/mini.nvim" },
	{ src = "https://github.com/tpope/vim-sensible"},
})

require "oil".setup()
require "mason".setup()
require "mason-lspconfig".setup()
require "codecompanion".setup()
require "transparent".setup()

require "mini.pick".setup()
require "mini.ai".setup()
require "mini.align".setup()
require "mini.comment".setup()
require "mini.completion".setup()
require "mini.keymap".setup()
require "mini.move".setup()
require "mini.operators".setup()
require "mini.pairs".setup()
require "mini.snippets".setup()
require "mini.splitjoin".setup()
require "mini.surround".setup()
require "mini.basics".setup()
require "mini.bracketed".setup()
require "mini.bufremove".setup()
require "mini.clue".setup()
require "mini.deps".setup()
require "mini.diff".setup()
require "mini.extra".setup()
require "mini.files".setup()
require "mini.git".setup()
require "mini.misc".setup()
require "mini.sessions".setup()
require "mini.visits".setup()

require "mini.cursorword".setup()
require "mini.hipatterns".setup()
require "mini.indentscope".setup()
require "mini.trailspace".setup()


vim.keymap.set("n", "<leader>f", ":Pick files<CR>")
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>s", ":Pick grep_live<CR>")
vim.keymap.set("n", "<leader>p", ":TypstPreview<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
vim.keymap.set("n", "<leader>e", ":Oil<CR> ")
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", ";", ":")

vim.cmd([[colorscheme rose-pine]])
vim.cmd([[hi statusline guibg=NONE]])


vim.keymap.set('n', 'U', function()
  vim.pack.update()
end, { desc = 'Update plugins' })
