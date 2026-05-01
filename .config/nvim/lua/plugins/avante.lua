return {
  "yetone/avante.nvim",
  opts = {
    provider = "ollama",
    providers = {
      ollama = {
        endpoint = "https://ollama.com", -- IMPORTANT: no /api
        -- model = "gpt-oss:120b", -- put your cloud model id here
        model = "kimi-k2.5", -- put your cloud model id here
        api_key_name = "21f48a18eadc4f3bace9c557096b0597.52a4zxzpBXhzEpdqe9fbDO0V",

        -- Enable provider when the env var exists
        is_env_set = function()
          return (vim.env.OLLAMA_API_KEY or "") ~= ""
        end,

        -- Some versions/configs needed this override to actually read the env var:
        parse_api_key = function()
          return vim.env.OLLAMA_API_KEY
        end,

        -- Needed for /api/tags (model listing / endpoint checks), which uses extra_headers:
        extra_headers = {
          ["Authorization"] = "Bearer " .. (os.getenv("OLLAMA_API_KEY") or ""),
        },
      },
    },
  },
}
