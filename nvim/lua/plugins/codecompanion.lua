require("codecompanion").setup({
  strategies = {
    chat = { adapter = "custom" },
    inline = { adapter = "custom" },
  },
  adapters = {
    custom = function()
      return require("codecompanion.adapters").extend("anthropic", {
        url = "http://claude.proxy.aim.yandex.net/v1/messages",
        env = { api_key = vim.fn.getenv("SOY_TOKEN") },
      })
    end,
  },
})
