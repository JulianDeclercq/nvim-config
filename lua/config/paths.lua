local module = {}

-- Obsidian platform specific paths
if vim.fn.has 'macunix' == 1 then
  module.obsidian = '/Users/Julian/Repositories/obsidian'
elseif vim.fn.has 'win32' == 1 then
  module.obsidian = 'C:/Users/Julian/Documents/The Cache'
else
  module.obsidian = vim.fn.expand '~' .. '/Repositories/obsidian'
end

return module
