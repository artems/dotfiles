require("codecompanion").setup({
  strategies = {
    cmd = { adapter = "custom_anthropic" },
    chat = { adapter = "custom_anthropic" },
    inline = { adapter = "custom_anthropic" },
  },
  adapters = {
    opts = {
      show_defaults = false,
    },
    custom_anthropic = function()
      return require("codecompanion.adapters").extend("anthropic", {
        url = "http://api.eliza.yandex.net/anthropic/v1/messages",
        env = { api_key = "SOY_TOKEN" },
        schema = {
          model = {
            default = "claude-3-7-sonnet-20250219",
          }
        }
      })
    end,
    custom_deepseek = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        url = "http://api.eliza.yandex.net/together/v1/chat/completions",
        env = {
          api_key = "SOY_TOKEN",
        },
        schema = {
          model = {
            default = "deepseek-ai/deepseek-r1",
          },
        },
      })
    end,
  },
})
