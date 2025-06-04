-- Make sure to install RipGrep

-- Platform specific paths
local obsidian_path
if vim.fn.has 'macunix' == 1 then
  obsidian_path = '/Users/Julian/Repositories/obsidian'
elseif vim.fn.has 'win32' == 1 then
  obsidian_path = 'C:\\Users\\Julian\\Repositories\\obsidian'
else
  obsidian_path = vim.fn.expand '~' .. '/Repositories/obsidian'
end

-- File name override, default for this plugin is a Zettelkasten id, I don't like it
local fileNameFunction = function(title)
  local name = title:gsub('[\\/:*?"<>|]', '') -- trim illegal characters
  name = name:match '^%s*(.-)%s*$' -- trim leading and trailing whitespace

  local candidate = name
  local fullpath = string.format('%s/%s.md', obsidian_path, candidate)

  -- if the file already exists, bump a counter
  if vim.loop.fs_stat(fullpath) then
    local i = 1
    repeat
      candidate = string.format('%s(%d)', name, i)
      fullpath = string.format('%s/%s.md', obsidian_path, candidate)
      i = i + 1
    until not vim.loop.fs_stat(fullpath)
  end

  return candidate
end

-- Generate id like the default. `note_id_func` overrides both title and id so let's pass this to still keep the id
local function generate_id()
  local ts = tostring(os.time()) -- e.g. "1749041682"
  local random_suffix = {}
  for i = 1, 4 do
    -- pick a random uppercase letter A–Z
    random_suffix[i] = string.char(math.random(65, 90))
  end
  return ts .. '-' .. table.concat(random_suffix) -- e.g. "1749041682-XQJF"
end

local noteFrontmatterFunction = function(note)
  return {
    id = generate_id(),
    aliases = { note.title },
    tags = {},
  }
end

return {
  'epwalsh/obsidian.nvim',
  version = '*', -- use latest release
  lazy = true,
  event = 'VimEnter', -- load on startup (no file)…, looks like this also works if you do any file so it's kind of pointless for me at the moment, need to figure out why this is or if there's another solution
  ft = 'markdown', -- …or on any markdown buffer

  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp', -- autocomplete for note references
  },

  opts = {
    workspaces = {
      {
        name = 'vault',
        path = obsidian_path,
      },
    },
    note_id_func = fileNameFunction,
    note_frontmatter_func = noteFrontmatterFunction,
    completion = {
      nvim_cmp = true,
      min_chars = 2,
      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = 'notes_subdir',
      file_popup = true,
    },
  },
}
