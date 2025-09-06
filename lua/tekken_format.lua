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
        print('found character ' .. word)
        return word
      end
    end
  end

  return nil
end

local function create_link(character, move)
  local linkMove = move:gsub(',', '%%2C') -- encode comma
  linkMove = linkMove:gsub('+', '') -- remove plus
  local link = ('https://tekkendocs.com/t8/%s/%s'):format(character, linkMove)
  local output = ('[%s](%s)'):format(move, link)
  -- https://tekkendocs.com/t8/law/1,2,2,12
  print(output)
  return output
end

---@param target string
local function replace_word_under_cursor(target)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- make it 0 indexed for API calls

  local word = vim.fn.expand '<cWORD>'
  vim.api.nvim_buf_set_text(0, row, col - #word + 1, row, col + 1, { target })
end

function module.format_tekken_move()
  local move = vim.fn.expand '<cWORD>'
  local character = get_character_name()
  if character == nil then
    return
  end

  local link = create_link(character, move)
  replace_word_under_cursor(link)
end

return module
