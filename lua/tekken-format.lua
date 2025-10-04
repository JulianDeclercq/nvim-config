local module = {}

---@param character string
---@return boolean
local function is_valid_character(character)
  local characters = {
    'alisa',
    'anna',
    'asuka',
    'azucena',
    'bryan',
    'claudio',
    'clive',
    'devil Jin',
    'dragunov',
    'eddy',
    'fahkumram',
    'feng',
    'heihachi',
    'hwoarang',
    'jack 8',
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
      -- normalize: strip "'s" at the end and remove trailing non-alphabetic characters
      local cleaned = word:gsub("'s$", ''):gsub('[^%w]+$', '')
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
  vim.cmd 'normal! viW' -- visual select inner word
  vim.fn.setreg('z', target) -- put the target in a temp register
  vim.cmd 'normal! "_d"zP' -- paste over the selection without yanking the word to default register
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
