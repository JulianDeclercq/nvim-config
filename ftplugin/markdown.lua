-- ~/.config/nvim/ftplugin/markdown.lua

-- Set conceallevel for prettier Markdown (hides Obsidian-style link brackets, etc.)
vim.wo.conceallevel = 2
vim.wo.concealcursor = 'nc'

-- Use two-space indentation for lists
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2

-- Turn on spell‐checking in Markdown (optional)
vim.wo.spell = true
