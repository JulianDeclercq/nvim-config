local module = {}

---@param character string
---@return boolean
local function is_valid_character(character)
  local characters = {
    'alisa',
    'anna',
    'armor-king',
    'asuka',
    'azucena',
    'bryan',
    'claudio',
    'clive',
    'devil-jin',
    'dragunov',
    'eddy',
    'fahkumram',
    'feng',
    'heihachi',
    'hwoarang',
    'jack-8',
    'jin',
    'jun',
    'kazuya',
    'king',
    'kuma',
    'lars',
    'law',
    'lee',
    'leo',
    'leroy',
    'lidia',
    'lili',
    'nina',
    'panda',
    'paul',
    'raven',
    'reina',
    'shaheen',
    'steve',
    'victor',
    'xiaoyu',
    'yoshimitsu',
    'zafina',
  }

  local character_set = {}
  for _, name in ipairs(characters) do
    character_set[name] = true
  end

  return character_set[character:lower()] or false
end

local function get_closest_character_name()
  local buf = 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_nr = cursor[1]

  for i = line_nr, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    for word in string.gmatch(line, '([^%s]+)') do
      -- normalize: remove possessive 's and strip non-alphanumeric chars on both ends
      local cleaned = word
        :gsub("'s$", '') -- remove trailing "'s" (e.g., "King's" → "King")
        :gsub('^[^%w]+', '') -- remove leading non-alphanumeric chars (e.g., "(King" → "King")
        :gsub('[^%w]+$', '') -- remove trailing non-alphanumeric chars (e.g., "King)" → "King")

      if is_valid_character(cleaned) then
        return cleaned
      end
    end
  end

  return nil
end

---@param move string
---@param remove_plus boolean | nil
---@return string
local function sanitize_move_input(move, remove_plus)
  move = move:gsub('cd', 'f,n,d,df') -- replace crouch dash
  move = move:gsub(',', '%%2C') -- encode comma
  move = move:gsub('~', '%%7E') -- encode tilde
  move = move:gsub('*', '%%2A') -- encode asterix
  if remove_plus then
    move = move:gsub('%+', '') -- remove plus
  else
    move = move:gsub('%+', '%%2B') -- encode plus
  end
  return move
end

---@param target string
local function replace_word_under_cursor(target)
  local buf = 0
  local row, col0 = unpack(vim.api.nvim_win_get_cursor(0)) -- row is 1-based, col is 0-based
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

  -- Find the non-whitespace "WORD" run at/near the cursor and replace it by columns.
  local s = col0 + 1
  local e = col0 + 1

  -- If cursor is on whitespace, move right to the next non-space
  if line:sub(s, s):match '%s' then
    local next_nonspace = line:find('%S', s)
    if not next_nonspace then
      return
    end
    s = next_nonspace
    e = next_nonspace
  end

  -- expand left
  while s > 1 and not line:sub(s - 1, s - 1):match '%s' do
    s = s - 1
  end

  -- expand right
  while e <= #line and not line:sub(e, e):match '%s' do
    e = e + 1
  end
  e = e - 1

  -- Replace range (0-based columns, end column is exclusive)
  vim.api.nvim_buf_set_text(buf, row - 1, s - 1, row - 1, e, { target })
end

local function create_link(link_formatter)
  local move = vim.fn.expand '<cWORD>'
  local character = get_closest_character_name()
  if character == nil then
    return
  end

  local link = link_formatter(character, move)
  replace_word_under_cursor(link)
end

function module.tekken_docs_link()
  create_link(function(character, move)
    local base = sanitize_move_input(move, true)
    local link = ('https://tekkendocs.com/t8/%s/%s'):format(character, base)
    return ('[%s](%s)'):format(move, link)
  end)
end

function module.okizeme_link()
  create_link(function(character, move)
    local base = sanitize_move_input(move, false)
    local link = ('https://okizeme.gg/database/%s/%s'):format(character:lower(), base)
    return ('[%s](%s)'):format(move, link)
  end)
end

return module
