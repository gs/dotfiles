-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("luasnip").filetype_extend("ruby", { "rails" })
require("luasnip").filetype_extend("eruby", { "html" })
