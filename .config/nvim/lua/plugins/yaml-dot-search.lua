return {
  config = function()
    local function search_yaml(query)
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local target_keys = vim.split(query, ".", { plain = true })
      local path_stack = {}

      for lnum, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed == "" or trimmed:match("^#") then goto continue end

        local key = trimmed:match("^([^:%s]+):")
        if not key then goto continue end

        local indent = #line:match("^(%s*)")
        while #path_stack > 0 and path_stack[#path_stack].indent >= indent do
          table.remove(path_stack)
        end
        table.insert(path_stack, {key = key, indent = indent})

        if #path_stack == #target_keys then
          local match = true
          for i = 1, #target_keys do
            if path_stack[i].key ~= target_keys[i] then
              match = false
              break
            end
          end
          if match then
            vim.api.nvim_win_set_cursor(0, {lnum + 1, 0})
            return
          end
        end

        ::continue::
      end
      vim.notify("Key path not found: " .. query, vim.log.levels.WARN)
    end

    vim.api.nvim_create_user_command("YamlSearch", function(opts)
      search_yaml(opts.args)
    end, { nargs = 1, desc = "Search YAML by dot-notation (e.g., pl.pdf.kotek)" })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "yaml", "yml" },
      callback = function(args)
        vim.api.nvim_buf_set_keymap(args.buf, "n", "/", ":YamlSearch ", {
          noremap = true,
          silent = false,
          desc = "Search YAML by dot-notation"
        })
      end
    })
  end
}
