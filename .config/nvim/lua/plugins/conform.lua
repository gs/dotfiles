return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      ruby = { "rubocop" },
      eruby = { "erb_format" },
    },
    formatters = {
      rubocop = {
        command = "bundle",
        args = { "exec", "rubocop", "--no-server", "-A", "-f", "quiet", "--stderr", "--stdin", "$FILENAME" },
        stdin = true,
      },
    },
  },
}
