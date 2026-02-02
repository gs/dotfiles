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

-- Bootstrap mini.deps
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing mini.nvim"')
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  })
  vim.cmd('packadd mini.nvim')
  vim.cmd('echo "Installed mini.nvim"')
end

-- Setup mini.deps
require('mini.deps').setup({ path = { package = path_package } })

local add = MiniDeps.add

-- Add plugins
add("stevearc/oil.nvim")
add("mason-org/mason.nvim")
add("mason-org/mason-lspconfig.nvim")
add("github/copilot.vim")
add("nvim-lua/plenary.nvim")
add("tpope/vim-rails")
add("nvim-treesitter/nvim-treesitter")
add("tpope/vim-fugitive")
add("rose-pine/neovim")
add("xiyaowong/transparent.nvim")
add("neovim/nvim-lspconfig")
add("tpope/vim-sensible")
add("folke/trouble.nvim")
add("nvim-pack/nvim-spectre")
add("ThePrimeagen/harpoon")
add("nvim-neotest/neotest")
add("zidhuss/neotest-minitest")
add("nvim-neotest/nvim-nio")
add("christoomey/vim-tmux-navigator")

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
  MiniDeps.update()
end, { desc = 'Update plugins' })
