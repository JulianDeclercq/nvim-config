-- zettel_migrate_alias.lua
-- Rename current Obsidian note to a Zettelkasten ID and update backlinks.
-- - Bare wiki links -> [[NEWID|OLD_NAME_WITH_SPACES]]
-- - Existing aliases preserved ([[OLD|X]] -> [[NEW|X]])
-- - Markdown links retargeted (handles .md, headings, and %20 spaces)
-- - Frontmatter: id: NEWID; aliases: [OLD_NAME, ...] (OLD_NAME first)
-- - Windows-safe rename (copy→unlink fallback); no overwrite prompts.

local M = {}

-- ========= helpers =========

local uv = vim.loop

local function generate_zettelkasten_id()
  local suffix = ''
  for _ = 1, 4 do
    suffix = suffix .. string.char(math.random(65, 90)) -- A-Z
  end
  return tostring(os.time()) .. '-' .. suffix
end

local function path_sep_to_slash(s)
  return (s:gsub('\\', '/'))
end

local function join_paths(a, b)
  if a:sub(-1) == '/' or a:sub(-1) == '\\' then
    return a .. b
  end
  local sep = package.config:sub(1, 1)
  return a .. sep .. b
end

local function is_dir(p)
  local stat = uv.fs_stat(p)
  return stat and stat.type == 'directory'
end

-- Find vault root by walking up until we see a ".obsidian" directory
local function find_vault_root(start)
  start = vim.fs.normalize(start)
  local dir = vim.fs.dirname(start)
  while dir and dir ~= '' do
    if is_dir(join_paths(dir, '.obsidian')) then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

-- Read an entire file (binary-safe)
local function read_file(path)
  local f, err = io.open(path, 'rb')
  if not f then
    return nil, err
  end
  local content = f:read '*a'
  f:close()
  return content
end

-- Write an entire file (binary-safe)
local function write_file(path, content)
  local f, err = io.open(path, 'wb')
  if not f then
    return false, err
  end
  f:write(content)
  f:close()
  return true
end

-- Pattern-escape single characters (robust; handles all magic chars, leaves spaces alone)
local function esc_lua(s)
  local magic = {
    ['^'] = true,
    ['$'] = true,
    ['('] = true,
    [')'] = true,
    ['%'] = true,
    ['.'] = true,
    ['['] = true,
    [']'] = true,
    ['*'] = true,
    ['+'] = true,
    ['-'] = true,
    ['?'] = true,
  }
  return (s:gsub('.', function(c)
    if magic[c] then
      return '%' .. c
    else
      return c
    end
  end))
end

-- Recursively iterate all files under root; yields absolute file paths.
local function iter_files(root, fn)
  local function scan(dir)
    local req = uv.fs_scandir(dir)
    if not req then
      return
    end
    while true do
      local name, t = uv.fs_scandir_next(req)
      if not name then
        break
      end
      local abs = join_paths(dir, name)
      if t == 'directory' then
        if name ~= '.obsidian' and name ~= '.git' and name ~= '.trash' then
          scan(abs)
        end
      elseif t == 'file' then
        fn(abs)
      end
    end
  end
  scan(root)
end

-- Normalize to forward-slash relative path from vault root
local function rel_from(root, abs)
  local norm_root = path_sep_to_slash(vim.fs.normalize(root))
  local norm_abs = path_sep_to_slash(vim.fs.normalize(abs))
  if norm_abs:sub(1, #norm_root) == norm_root then
    local rel = norm_abs:sub(#norm_root + 2) -- drop trailing "/"
    return rel
  end
  return vim.fs.basename(abs)
end

-- ---------- frontmatter tweak ----------
-- Preserve existing aliases; ensure OLD (with spaces) is first; set id: NEW
local function update_frontmatter_id_and_alias(old_alias_text, new_id)
  local buf = 0
  local n = vim.api.nvim_buf_line_count(buf)
  if n == 0 then
    return
  end
  local function get(i)
    return vim.api.nvim_buf_get_lines(buf, i, i + 1, false)[1]
  end
  if not ((get(0) or ''):match '^%-%-%-$') then
    return
  end

  local fm_end
  for i = 1, math.min(n - 1, 400) do
    local l = get(i)
    if l and l:match '^%-%-%-$' then
      fm_end = i
      break
    end
  end
  if not fm_end then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, n, false)
  local id_idx, aliases_idx
  for i = 1, fm_end - 1 do
    local l = lines[i + 1]
    if l then
      if (not id_idx) and l:match '^id:%s*' then
        id_idx = i + 1
      end
      if (not aliases_idx) and l:match '^aliases:%s*%[' then
        aliases_idx = i + 1
      end
    end
  end

  if id_idx then
    lines[id_idx] = 'id: ' .. new_id
  else
    table.insert(lines, 2, 'id: ' .. new_id)
    fm_end = fm_end + 1
  end

  local function parse_inline_list(s)
    local inside = s and s:match '^aliases:%s*%[(.-)%]%s*$'
    if not inside then
      return {}
    end
    local out = {}
    for item in inside:gmatch '([^,]+)' do
      item = item:gsub('^%s*', ''):gsub('%s*$', '')
      item = item:gsub([[^"(.*)"$]], '%1'):gsub([[^'(.*)'$]], '%1')
      if item ~= '' then
        out[#out + 1] = item
      end
    end
    return out
  end

  local alias_list = aliases_idx and parse_inline_list(lines[aliases_idx]) or {}

  local seen = {}
  local new_aliases = { old_alias_text }
  seen[old_alias_text] = true
  for _, a in ipairs(alias_list) do
    if not seen[a] then
      new_aliases[#new_aliases + 1] = a
      seen[a] = true
    end
  end

  local line = 'aliases: [' .. table.concat(new_aliases, ', ') .. ']'
  if aliases_idx then
    lines[aliases_idx] = line
  else
    local insert_at = (id_idx and id_idx + 1) or 2
    table.insert(lines, insert_at, line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, n, false, lines)
end

-- ---------- backlinks rewrite ----------
local function percent_encode_spaces(s)
  return (s:gsub(' ', '%%20'))
end

-- Build the replacement lookup used to update backlinks.
-- Bare wiki links become [[new_id|alias_text]].
local function build_search_lookup(old_alias_text, old_rel_path, new_id, new_rel_path)
  local lookup = {}

  -- Helper to add all forms for a single "old" token (wiki)
  local function add_wiki_forms(old, new_for_prefix, alias_text)
    lookup['[[' .. old .. ']]'] = '[[' .. new_for_prefix .. '|' .. alias_text .. ']]'
    lookup['[[' .. old .. '#'] = '[[' .. new_for_prefix .. '#'
    lookup['[[' .. old .. '|'] = '[[' .. new_for_prefix .. '|'
    lookup['[[' .. old .. '\\|'] = '[[' .. new_for_prefix .. '\\|'
  end

  -- Markdown links: keep the visible alias outside the link; just retarget
  local function add_md_forms(old_plain, new_plain)
    -- plain
    lookup['](' .. old_plain .. ')'] = '](' .. new_plain .. ')'
    lookup['](' .. old_plain .. '#'] = '](' .. new_plain .. '#'
    -- with .md (when old_plain lacked it)
    lookup['](' .. old_plain .. '.md)'] = '](' .. new_plain .. ')'
    lookup['](' .. old_plain .. '.md#'] = '](' .. new_plain .. '#'
    -- %20-encoded variants (spaces in paths)
    local enc = percent_encode_spaces(old_plain)
    lookup['](' .. enc .. ')'] = '](' .. new_plain .. ')'
    lookup['](' .. enc .. '#'] = '](' .. new_plain .. '#'
    lookup['](' .. enc .. '.md)'] = '](' .. new_plain .. ')'
    lookup['](' .. enc .. '.md#'] = '](' .. new_plain .. '#'
  end

  local old_rel_noext = old_rel_path:gsub('%.md$', '')
  local alias = old_alias_text -- full old filename without .md (may contain spaces)

  -- WIKI: target NEWID (not path) and set alias text
  add_wiki_forms(old_alias_text, new_id, alias) -- [[old id]]
  add_wiki_forms(old_rel_path, new_id, alias) -- [[dir/old.md]]
  add_wiki_forms(old_rel_noext, new_id, alias) -- [[dir/old]]

  -- MARKDOWN: accept id/rel/noext and id.md; retarget to NEWID (not path)
  add_md_forms(old_alias_text, new_id) -- (old id) and (old id.md)
  add_md_forms(old_rel_path, new_id) -- (dir/old.md)
  add_md_forms(old_rel_noext, new_id) -- (dir/old) and (dir/old.md)

  local keys = {}
  for k, _ in pairs(lookup) do
    table.insert(keys, k)
  end
  return lookup, keys
end

-- Do fixed-string replacements using the lookup, returning new text and whether it changed
local function replace_all(text, lookup)
  local changed = false
  for old, newv in pairs(lookup) do
    local before = text
    text = text:gsub(esc_lua(old), newv)
    if text ~= before then
      changed = true
    end
  end
  return text, changed
end

-- ---------- writes / rename ----------
local function write_now(bufnr)
  pcall(function()
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd 'silent noautocmd write!'
    end)
  end)
end

-- Windows-safe file rename: try fs_rename, fall back to copy+unlink (no prompts).
local function safe_rename_file(old_path, new_path, current_bufnr)
  if current_bufnr and current_bufnr ~= -1 then
    write_now(current_bufnr)
  end

  local ok = pcall(uv.fs_rename, old_path, new_path)
  if ok then
    return true
  end

  local ok_copy, err_copy = pcall(uv.fs_copyfile, old_path, new_path, { excl = true })
  if not ok_copy then
    return false, ('copy failed: %s'):format(tostring(err_copy))
  end

  if current_bufnr and current_bufnr ~= -1 then
    vim.api.nvim_buf_set_name(current_bufnr, new_path)
    write_now(current_bufnr)
  end

  local ok_unlink, _ = pcall(uv.fs_unlink, old_path)
  if not ok_unlink then
    vim.api.nvim_create_autocmd('VimLeavePre', {
      once = true,
      callback = function()
        pcall(uv.fs_unlink, old_path)
      end,
    })
  end

  return true
end

-- ========= main =========

M.migrate_current_file_with_alias_links = function()
  pcall(vim.cmd, 'silent noautocmd wall')

  local buf = 0
  local old_abs = vim.api.nvim_buf_get_name(buf)
  if old_abs == '' then
    vim.notify('No file name for current buffer.', vim.log.levels.ERROR)
    return
  end

  local vault = find_vault_root(old_abs)
  if not vault then
    vim.notify('Could not locate Obsidian vault root (.obsidian).', vim.log.levels.ERROR)
    return
  end

  -- old_alias_text is the full filename without .md (may contain spaces)
  local old_filename = vim.fs.basename(old_abs)
  local old_alias_text = old_filename:gsub('%.md$', '')
  local dir_abs = vim.fs.dirname(old_abs)

  local new_id = generate_zettelkasten_id()
  if not new_id or new_id == '' then
    vim.notify('Failed to generate Zettelkasten ID.', vim.log.levels.ERROR)
    return
  end

  local new_filename = new_id .. '.md'
  local new_abs = join_paths(dir_abs, new_filename)

  local old_rel = rel_from(vault, old_abs)
  local new_rel = rel_from(vault, new_abs)

  local lookup, keys = build_search_lookup(old_alias_text, old_rel, new_id, new_rel)

  -- Update backlinks across the vault (sequential I/O).
  local files_changed = 0
  iter_files(vault, function(p)
    if p:sub(-3):lower() ~= '.md' then
      return
    end
    local content = read_file(p)
    if not content then
      return
    end

    -- Quick precheck using fixed strings (includes %20 variants etc.)
    local has_any = false
    for _, k in ipairs(keys) do
      if content:find(k, 1, true) then
        has_any = true
        break
      end
    end
    if not has_any then
      return
    end

    local new_content, changed = replace_all(content, lookup)
    if changed then
      local ok = write_file(p, new_content)
      if ok then
        files_changed = files_changed + 1
      end
    end
  end)

  -- Rename current file (Windows-safe, no prompts)
  local ok_rename, rerr = safe_rename_file(old_abs, new_abs, buf)
  if not ok_rename then
    vim.notify('Rename failed: ' .. (rerr or ''), vim.log.levels.ERROR)
    return
  end

  -- Point buffer to new path and write (no prompt)
  vim.api.nvim_buf_set_name(buf, new_abs)
  write_now(buf)

  -- Add full old filename as first alias; set new id
  update_frontmatter_id_and_alias(old_alias_text, new_id)
  write_now(buf)

  vim.notify(('Migrated to %s.md. Updated backlinks in %d file(s).'):format(new_id, files_changed), vim.log.levels.INFO)
end

return M
