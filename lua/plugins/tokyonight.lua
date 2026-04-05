require('tokyonight').setup {
  styles = {
    comments = { italic = false }, -- Disable italics in comments
  },
  on_highlights = function(hl, _)
    -- all following settings are for when 'relativenumber' is on (always in my case)
    local color = '#5C8699'
    hl.LineNrAbove = { fg = color }
    hl.CursorLineNr = { fg = color }
    hl.LineNrBelow = { fg = color }
  end,
}
vim.cmd.colorscheme 'tokyonight-night'
