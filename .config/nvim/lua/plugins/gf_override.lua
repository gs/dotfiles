return {
  "gs-deliverists-io/gf-override.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "gf",
      function()
        require("gf-override").gf_handler()
      end,
      desc = "Enhanced gf command with file creation",
    },
  },
}
