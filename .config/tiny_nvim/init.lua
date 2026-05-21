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
vim.opt.timeoutlen = 250
vim.opt.ttimeoutlen = 10
vim.opt.updatetime = 150
vim.opt.completeopt = { "menuone", "noselect", "fuzzy" }

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
add("nvim-lua/plenary.nvim")
add("tpope/vim-rails")
add("tpope/vim-fugitive")
add("rose-pine/neovim")
add("xiyaowong/transparent.nvim")
add("nvim-treesitter/nvim-treesitter")
add("neovim/nvim-lspconfig")
add("tpope/vim-sensible")
add("folke/trouble.nvim")
add("nvim-pack/nvim-spectre")
add("ThePrimeagen/harpoon")
add("nvim-neotest/neotest")
add("zidhuss/neotest-minitest")
add("nvim-neotest/nvim-nio")
add("christoomey/vim-tmux-navigator")
add("saghen/blink.nvim")
add("carderne/pi-nvim")

require "oil".setup()
require "mason".setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "ts_ls", "ruby_lsp" },
})
require("nvim-treesitter").setup({
  ensure_installed = { "lua", "ruby", "javascript" },
  highlight = { enable = true },
})
require "transparent".setup()
require("mini.pick").setup({
  sources = {
    files = { preview = true },
    grep_live = { preview = true },
  },
  windows = {
    pick = { float = true },
    preview = { float = true },
  },
  mappings = {
    choose_in_vsplit = "<C-q>",
    paste = "<C-v>",
  },
})
require "trouble".setup()
require "spectre".setup()
require "harpoon".setup()
pcall(vim.cmd, "packadd vim-fugitive")
pcall(vim.cmd, "packadd nvim-nio")
vim.api.nvim_create_user_command("G", function(opts)
  local args = opts.args == "" and "" or " " .. opts.args
  local cmd = vim.fn["fugitive#Command"](-1, -1, 0, opts.bang and 1 or 0, "", "++curwin" .. args)
  vim.cmd(cmd == "" and "exe" or cmd)
end, {
  bang = true,
  nargs = "*",
  complete = function(arglead, cmdline, cursorpos)
    return vim.fn["fugitive#Complete"](arglead, cmdline, cursorpos)
  end,
})
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
local snippets = require("mini.snippets")
local gen_loader = snippets.gen_loader
local snippet_match_strict = function(snips)
  return snippets.default_match(snips, { pattern_fuzzy = "%S+" })
end
snippets.setup({
  snippets = {
    gen_loader.from_file("~/.config/nvim/snippets/global.json"),
    gen_loader.from_lang(),
  },
  mappings = { expand = "", jump_next = "", jump_prev = "" },
  expand = { match = snippet_match_strict },
})
local completion = require("mini.completion")
local completion_process_items = function(items, base)
  return completion.default_process_items(items, base, { filtersort = "fuzzy" })
end
completion.setup({
  delay = { completion = 100, info = 100, signature = 50 },
  lsp_completion = { process_items = completion_process_items },
})

local termcodes = function(keys)
  return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col == 0 then return false end
  local text_before_cursor = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col)
  return not text_before_cursor:match("%s")
end

_G.cr_action = function()
  if vim.fn.complete_info()["selected"] ~= -1 then return "\25" end
  return "\r"
end

_G.tab_action = function()
  if vim.fn.pumvisible() == 1 then return "\14" end
  if _G.MiniSnippets ~= nil then
    if #MiniSnippets.expand({ insert = false }) > 0 then
      vim.schedule(MiniSnippets.expand)
      return ""
    end
    if MiniSnippets.session.get() ~= nil then
      MiniSnippets.session.jump("next")
      return ""
    end
  end
  if vim.snippet ~= nil and vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
    return ""
  end
  if has_words_before() then
    MiniCompletion.complete_twostage()
    return ""
  end
  return "\t"
end

_G.s_tab_action = function()
  if vim.fn.pumvisible() == 1 then return "\16" end
  if _G.MiniSnippets ~= nil and MiniSnippets.session.get() ~= nil then
    MiniSnippets.session.jump("prev")
    return ""
  end
  if vim.fn.complete_info()["selected"] ~= -1 then return "\25" end
  if vim.snippet ~= nil and vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
    return ""
  end
  return termcodes("<S-Tab>")
end

vim.keymap.set("i", "<CR>", "v:lua.cr_action()", { expr = true })
vim.keymap.set({ "i", "s" }, "<Tab>", "v:lua.tab_action()", { expr = true })
vim.keymap.set({ "i", "s" }, "<S-Tab>", "v:lua.s_tab_action()", { expr = true })
require "mini.move".setup()
require "mini.operators".setup()
require "mini.pairs".setup()
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

require("pi-nvim").setup()

local paste_orig = vim.paste
vim.paste = function(lines, phase)
  if not MiniPick.is_picker_active() then return paste_orig(lines, phase) end
  if phase ~= -1 and phase ~= 1 then return end

  local pasted = type(lines) == "table" and table.concat(lines, " ") or tostring(lines)
  pasted = pasted:gsub("[\n\t]", " ")
  local query = MiniPick.get_picker_query()
  table.insert(query, pasted)
  MiniPick.set_picker_query(query)
end

local pick_grep_cword = function()
  require("mini.pick").builtin.grep({ pattern = vim.fn.expand("<cword>") })
end


vim.keymap.set("n", "<leader>f", ":Pick files<CR>")
vim.keymap.set("n", "<leader>b", ":Pick buffers<CR>")
vim.keymap.set("n", "<leader>s", ":Pick grep_live<CR>")
vim.keymap.set("n", "<leader>p", ":TypstPreview<CR>")
vim.keymap.set("n", "<leader>h", ":Pick help<CR>")
vim.keymap.set("n", "<leader>e", ":Oil<CR> ")
vim.keymap.set("n", "<leader>E", ":e ~/.config/nvim/init.lua<CR> ")

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>S", pick_grep_cword)
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
vim.keymap.set("n", "<leader>pp", ":PiSend<CR>")
vim.keymap.set("n", "<leader>pf", ":PiSendFile<CR>")
vim.keymap.set("v", "<leader>ps", ":PiSendSelection<CR>")
vim.keymap.set("n", "<leader>pb", ":PiSendBuffer<CR>")
vim.keymap.set("n", ";", ":")

vim.cmd([[colorscheme rose-pine-moon]])
vim.cmd([[hi statusline guibg=NONE]])


vim.keymap.set('n', 'U', function()
  if vim.fn.confirm("Update plugins?", "&Yes\n&No") == 1 then
    MiniDeps.update()
  end
end, { desc = 'Update plugins (confirm)' })
