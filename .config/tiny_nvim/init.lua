-- Options ---------------------------------------------------------------------
vim.g.mapleader = ","
vim.g.fugitive_default_split = "edit"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.mouse = ""
vim.opt.path = "**"
vim.opt.clipboard = "unnamedplus"
vim.opt.timeoutlen = 250
vim.opt.ttimeoutlen = 10
vim.opt.updatetime = 150
vim.opt.winborder = "rounded"
vim.opt.pumborder = "rounded"
vim.opt.inccommand = "split" -- live :s preview incl. off-screen lines

-- Native autocompletion: LSP (omnifunc) first, then words from buffers
vim.opt.autocomplete = true
vim.opt.complete = "o,.^5,w^5,b^5"
vim.opt.completeopt = { "menuone", "noselect", "fuzzy", "popup" }

-- Command-line autocompletion (: / ?)
vim.opt.wildmode = "noselect:lastused,full"
vim.opt.wildoptions = "pum"
vim.api.nvim_create_autocmd("CmdlineChanged", {
  pattern = { ":", "/", "?" },
  callback = function() vim.fn.wildtrigger() end,
})
vim.keymap.set("c", "<Up>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>" end, { expr = true })
vim.keymap.set("c", "<Down>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>" end, { expr = true })

vim.diagnostic.config({ virtual_lines = { current_line = true } })

-- Spell checking (Polish) only for prose filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit", "tex", "typst" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "pl"
  end,
})
-- Fix the previous misspelled word using the first suggestion
vim.keymap.set("i", "<C-l>", "<C-g>u<Esc>[s1z=`]a<C-g>u", { desc = "Autocorrect previous spelling error" })

-- Plugins (vim.pack) -----------------------------------------------------------
-- Rebuild treesitter parsers after the plugin updates (must be before add)
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

local gh = function(repo) return "https://github.com/" .. repo end
vim.pack.add({
  gh("echasnovski/mini.nvim"),
  gh("stevearc/oil.nvim"),
  gh("mason-org/mason.nvim"),
  gh("neovim/nvim-lspconfig"),
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("rose-pine/neovim"),
  gh("tpope/vim-rails"),
  gh("tpope/vim-fugitive"),
  gh("christoomey/vim-tmux-navigator"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-neotest/nvim-nio"),
  gh("nvim-neotest/neotest"),
  gh("zidhuss/neotest-minitest"),
  gh("carderne/pi-nvim"),
  gh("chris-ritsen/autocorrect.nvim"),
})
vim.cmd.packadd("nvim.undotree")
vim.cmd.packadd("nvim.difftool")

-- Colors ------------------------------------------------------------------------
require("rose-pine").setup({ styles = { transparency = true } })
vim.cmd.colorscheme("rose-pine-moon")
vim.cmd([[hi statusline guibg=NONE]])

-- LSP ---------------------------------------------------------------------------
require("mason").setup() -- installs servers and puts them on PATH (:Mason)
vim.lsp.config("lua_ls", { -- know the Neovim API when editing this config
  settings = { Lua = { runtime = { version = "LuaJIT" }, workspace = { library = { vim.env.VIMRUNTIME } } } },
})
vim.lsp.enable({ "lua_ls", "ts_ls", "ruby_lsp", "herb_ls" })
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    -- Snippet expansion and extra edits for LSP items picked from the menu
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = false })
  end,
})

-- Treesitter --------------------------------------------------------------------
local ts_langs = { "lua", "ruby", "javascript" }
require("nvim-treesitter").install(ts_langs)
vim.api.nvim_create_autocmd("FileType", {
  pattern = ts_langs,
  callback = function() pcall(vim.treesitter.start) end,
})

-- Plugin setup ------------------------------------------------------------------
require("oil").setup()
require("autocorrect").setup()
require("pi-nvim").setup({ set_default_keymaps = false })
require("neotest").setup({
  adapters = { require("neotest-minitest") },
  output_panel = { enabled = true, open = "botright split | resize 15" },
})

-- In the picker: <Tab> preview, <S-Tab> info, <C-f>/<C-b> scroll
require("mini.pick").setup({
  mappings = {
    choose_in_vsplit = "<C-q>",
    paste = "<C-v>",
  },
})
require("mini.extra").setup()
require("mini.ai").setup()
require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.basics").setup()
require("mini.bracketed").setup()
require("mini.bufremove").setup()
require("mini.diff").setup()
require("mini.git").setup()
require("mini.sessions").setup()
require("mini.indentscope").setup()
require("mini.trailspace").setup()

-- :G opens fugitive in the current window
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

-- Pasting while a picker is open goes into the query
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

-- Keymaps -----------------------------------------------------------------------
local map = vim.keymap.set

-- Completion: Tab/S-Tab move through the menu or jump in snippets, CR accepts
map({ "i", "s" }, "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  if vim.snippet.active({ direction = 1 }) then return "<Cmd>lua vim.snippet.jump(1)<CR>" end
  return "<Tab>"
end, { expr = true })
map({ "i", "s" }, "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-p>" end
  if vim.snippet.active({ direction = -1 }) then return "<Cmd>lua vim.snippet.jump(-1)<CR>" end
  return "<S-Tab>"
end, { expr = true })
map("i", "<CR>", function()
  return vim.fn.complete_info({ "selected" }).selected ~= -1 and "<C-y>" or "<CR>"
end, { expr = true })

-- ; and : swapped: ; enters the command line, : repeats f/t
map({ "n", "x" }, ";", ":")
map({ "n", "x" }, ":", ";")

-- Pickers and files
map("n", "<leader>f", "<Cmd>Pick files<CR>")
map("n", "<leader>b", "<Cmd>Pick buffers<CR>")
map("n", "<leader>s", "<Cmd>Pick grep_live<CR>")

-- Search & replace: word under cursor (normal) or selected text (visual)
local function target_text()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" then
    local text = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })[1] or ""
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    return text, false
  end
  return vim.fn.expand("<cword>"), true -- true = whole word only
end

-- Very-nomagic :s pattern for literal text
local function sub_pattern(text, whole)
  local esc = vim.fn.escape(text, "/\\")
  return whole and ("\\V\\<" .. esc .. "\\>") or ("\\V" .. esc)
end

-- Put a command on the command line with the cursor before `suffix`
local function prefill(cmd, suffix)
  vim.api.nvim_feedkeys(":" .. cmd .. suffix .. string.rep(vim.keycode("<Left>"), #suffix), "n", false)
end

-- Project search for the word/selection (picker; <C-a> marks all, <M-CR> sends to quickfix)
map({ "n", "x" }, "<leader>S", function()
  local text, whole = target_text()
  if text == "" then return end
  local pattern = vim.fn.escape(text, "\\.^$*+?()[]{}|")
  MiniPick.builtin.grep({ pattern = whole and ("\\b" .. pattern .. "\\b") or pattern })
end, { desc = "Search word/selection in project" })

-- Replace in current file: type the replacement, Enter (add `c` to the flags to confirm each)
map({ "n", "x" }, "<leader>rr", function()
  local text, whole = target_text()
  if text == "" then return end
  prefill("%s/" .. sub_pattern(text, whole) .. "/", "/gI")
end, { desc = "Replace word/selection in file" })

-- Replace in project: matches go to quickfix for review, then type replacement, Enter
map({ "n", "x" }, "<leader>rp", function()
  local text, whole = target_text()
  if text == "" then return end
  local cmd = { "rg", "--vimgrep", "--fixed-strings" }
  if whole then table.insert(cmd, "--word-regexp") end
  vim.list_extend(cmd, { "--", text })
  local lines = vim.fn.systemlist(cmd)
  if #lines == 0 then return vim.notify("No matches for " .. text) end
  vim.fn.setqflist({}, " ", { title = "Replace: " .. text, lines = lines, efm = "%f:%l:%c:%m" })
  vim.cmd("copen")
  prefill("cdo s/" .. sub_pattern(text, whole) .. "/", "/gIe | update")
end, { desc = "Replace word/selection in project" })
map("n", "<leader>h", "<Cmd>Pick help<CR>")
map("n", "<leader>e", "<Cmd>Oil<CR>")
map("n", "<leader>E", "<Cmd>e $MYVIMRC<CR>")

-- Arglist as a pinned-file list (replaces harpoon): ]a / [a to cycle
map("n", "<leader>a", "<Cmd>$argadd % | argdedupe<CR>", { desc = "Pin file to arglist" })
map("n", "<leader>A", "<Cmd>args<CR>", { desc = "Show arglist" })
for i = 1, 4 do
  map("n", "<leader>" .. i, "<Cmd>silent! " .. i .. "argument<CR>", { desc = "Go to pinned file " .. i })
end

-- LSP (built-in: grn rename, gra action, grr refs, gri impl, grt type, gO symbols, K hover)
map("n", "gd", vim.lsp.buf.definition)
map("n", "gD", vim.lsp.buf.declaration)
map("n", "<leader>lf", vim.lsp.buf.format)

-- Diagnostics (built-in: [d ]d)
map("n", "<leader>q", vim.diagnostic.setloclist)
map("n", "<leader>xx", function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = "All diagnostics in quickfix" })

-- Tests
map("n", "<leader>tt", function() require("neotest").run.run() end)
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end)
map("n", "<leader>ts", function() require("neotest").run.stop() end)
map("n", "<leader>to", function() require("neotest").output_panel.toggle() end)

-- pi
map("n", "<leader>pp", "<Cmd>PiSend<CR>")
map("n", "<leader>pf", "<Cmd>PiSendFile<CR>")
map("v", "<leader>ps", ":PiSendSelection<CR>")
map("n", "<leader>pb", "<Cmd>PiSendBuffer<CR>")

-- Tools
map("n", "<leader>u", "<Cmd>Undotree<CR>", { desc = "Undo tree" })
map("n", "<leader>R", "<Cmd>restart<CR>", { desc = "Restart nvim (reload config)" })
map("n", "<leader>U", function() vim.pack.update() end, { desc = "Update plugins" })
