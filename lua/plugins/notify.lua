return {
  'rcarriga/nvim-notify',
  version = '*',
  lazy = true,
  -- load early so any vim.notify() calls get routed through nvim-notify
  event = 'VimEnter',
  -- optionally expose the setup opts here
  opts = {
    -- e.g. timeout = 3000,
    --      top_down = false,
    --      stages = "fade_in_slide_out",
  },
  config = function(_, opts)
    local notify = require 'notify'
    notify.setup(opts)
    -- override default vim.notify
    vim.notify = notify
  end,
}
