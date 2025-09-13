-- Migrates the currently open Obsidian file to Zettelkasten format.

local module = {}
local function generate_zettelkasten_id()
  -- simple mimic the one from obsidian-nvim/obsidian.nvim
  local suffix = ''
  for _ = 1, 4 do -- append 4 random uppercase letters
    suffix = suffix .. string.char(math.random(65, 90))
  end

  return tostring(os.time()) .. '-' .. suffix
end

local function update_frontmatter_alias(old_title)
  local buf = 0
  for i = 1, vim.api.nvim_buf_line_count(buf) do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    if line and line:find '^aliases:%s*%[' then
      -- replace the first [...] after 'aliases:' on that line
      local new_line = line:gsub('^(aliases:%s*)%b[]', '%1[' .. old_title .. ']', 1)
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { new_line })
      return
    end
  end
end

module.migrate_file = function()
  local old_id = vim.fn.expand '%:t:r'
  local new_id = generate_zettelkasten_id()
  if new_id == nil then
    return
  end

  vim.cmd('Obsidian rename ' .. new_id)
  vim.cmd 'wa' -- ensure backlink updates are written, see the [README](https://github.com/obsidian-nvim/obsidian.nvim/blob/db08b881b287cc3d50131a0c9d3b3bf4e5794218/README.md?plain=1#L108)

  update_frontmatter_alias(old_id)
end

return module
