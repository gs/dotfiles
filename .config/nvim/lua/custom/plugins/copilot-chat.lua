return {
  'CopilotC-Nvim/CopilotChat.nvim',
  opts = {
    debug = true,
    show_help = 'yes',
    prompts = {
      Explain = 'Explain how it works.',
      Review = 'Review the following code and provide concise suggestions.',
      Tests = 'Briefly explain how the selected code works, then generate unit tests.',
      Refactor = 'Refactor the code to improve clarity and readability.',
    },
  },
  build = function()
    vim.notify "Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim."
  end,
  event = 'VeryLazy',
  keys = {
    { '<leader>ccb', '<cmd>CopilotChatBuffer<cr>', desc = 'CopilotChat - Chat with current buffer' },
    { '<leader>cce', '<cmd>CopilotChatExplain<cr>', desc = 'CopilotChat - Explain code' },
    { '<leader>cct', '<cmd>CopilotChatTests<cr>', desc = 'CopilotChat - Generate tests' },
    { '<leader>ccr', '<cmd>CopilotChatReview<cr>', desc = 'CopilotChat - Review code' },
    { '<leader>ccR', '<cmd>CopilotChatRefactor<cr>', desc = 'CopilotChat - Refactor code' },
  },
}
