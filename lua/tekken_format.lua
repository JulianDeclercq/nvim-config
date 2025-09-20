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

local function get_character_name()
  local buf = 0
  for i = 1, vim.api.nvim_buf_line_count(buf) do
    local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1]
    for word in string.gmatch(line, '([^%s]+)') do
      if is_valid_character(word) then
        return word
      end
    end
  end

  return nil
end

---@param move string
---@param remove_plus boolean | nil
---@return string
local function create_link_base(move, remove_plus)
  move = move:gsub('cd', 'f,n,d,df') -- replace crouch dash
  move = move:gsub(',', '%%2C') -- encode comma
  if remove_plus then
    move = move:gsub('%+', '') -- remove plus
  else
    move = move:gsub('%+', '%%2B') -- encode plus
  end
  return move
end

local function create_link_tekken_docs(character, move)
  -- https://tekkendocs.com/t8/law/1,2,2,12
  local base = create_link_base(move, true)
  local link = ('https://tekkendocs.com/t8/%s/%s'):format(character, base)
  return ('[%s](%s)'):format(move, link)
end

local function create_link_okizeme(character, move)
  --https://okizeme.gg/database/anna/H.f%2Cf%2CF%2B3%2C2
  local base = create_link_base(move, false)
  -- local link = 'https://okizeme.gg/database/anna/H.f%2Cf%2CF%2B3%2C2'
  local link = ('https://okizeme.gg/database/%s/%s'):format(character:lower(), base)
  return ('[%s](%s)'):format(move, link)
end

---@param target string
local function replace_word_under_cursor(target)
  vim.cmd 'normal! viW' -- visual select inner word
  vim.fn.setreg('z', target) -- put the target in a temp register
  vim.cmd 'normal! "zp"' -- paste over the selection
end

function module.tekken_docs_link()
  local move = vim.fn.expand '<cWORD>'
  local character = get_character_name()
  if character == nil then
    return
  end

  local link = create_link_tekken_docs(character, move)
  replace_word_under_cursor(link)
end

-- TODO Use base function and share it with format_tekken_docs_link
function module.okizeme_link()
  local move = vim.fn.expand '<cWORD>'
  local character = get_character_name()
  if character == nil then
    return
  end

  local link = create_link_okizeme(character, move)
  replace_word_under_cursor(link)
end

return module
