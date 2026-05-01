-- Check if this is a pi temp file BEFORE loading plugins
local isPiTemp = false
if vim.fn.argc() > 0 then
    local file = vim.fn.expand('%:p')
    isPiTemp = file:match('/tmp/pi%-') or file:match('%.tmp%.md')
end

if isPiTemp then
    -- Minimal config for pi external editor - NO plugins
    vim.g.loaded_matchparen = 1
    vim.g.loaded_netrw = 1
    vim.opt.syntax = 'off'
    vim.opt.foldenable = false
    vim.opt.swapfile = false
    vim.opt.backup = false
    vim.opt.undofile = false
    vim.opt.showmode = false
    vim.opt.ruler = false
else
    -- Normal LazyVim config
    require("config.lazy")
    require("luasnip").filetype_extend("ruby", { "rails" })
    require("luasnip").filetype_extend("eruby", { "html" })
end
