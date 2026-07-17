return {
  "pimalaya/himalaya-vim",
  lazy = true,
  cmd = { "HimalayaOpen", "HimalayaCompose", "HimalayaWrite" },
  config = function()
    vim.g.himalaya_cli_version = "v1"
    vim.g.himalaya_config_path = vim.fn.expand("~/.config/himalaya/config.toml")
  end,
  keys = {
    { "<leader>mo", "<cmd>HimalayaOpen<cr>", desc = "Open Mail" },
    { "<leader>mc", "<cmd>HimalayaCompose<cr>", desc = "Compose Mail" },
    { "<leader>mw", "<cmd>HimalayaWrite<cr>", desc = "Write Mail" },
  },
}
