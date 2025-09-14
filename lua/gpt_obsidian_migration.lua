-- zettel_migrate_alias.lua
-- Rename current Obsidian note to a Zettelkasten ID without using :Obsidian rename.
-- Updates backlinks across the vault and:
--   * Bare wiki links become [[NEWID|OLDID]]
--   * Existing aliases are preserved: [[OLDID|X]] -> [[NEWID|X]]
-- Also adds OLDID to the note's frontmatter aliases.

local M = {}

-- ========= helpers =========

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
  local stat = vim.loop.fs_stat(p)
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

-- Escape a string so it is treated as a plain pattern in Lua gsub/find
local function escape_lua(s)
  return (s:gsub('(%W)', '%%%1'))
end

-- Update YAML frontmatter: set id: NEW_ID and aliases: [OLD_ID]
-- Only works if a frontmatter block already exists.
local function update_frontmatter_id_and_alias(old_id, new_id)
  local buf = 0
  local n = vim.api.nvim_buf_line_count(buf)
  if n == 0 then
    return
  end

  local get = function(i)
    return vim.api.nvim_buf_get_lines(buf, i, i + 1, false)[1]
  end

  -- Detect frontmatter block
  local has_front = (get(0) or ''):match '^%-%-%-$'
  if not has_front then
    return
  end

  local fm_start, fm_end
  for i = 1, math.min(n - 1, 400) do
    local l = get(i)
    if l and l:match '^%-%-%-$' then
      fm_start, fm_end = 0, i
      break
    end
  end
  if not fm_end then
    return
  end -- no closing ---

  -- Work with lines in frontmatter
  local lines = vim.api.nvim_buf_get_lines(buf, 0, n, false)

  local id_idx, aliases_idx = nil, nil
  for i = fm_start + 1, fm_end - 1 do
    local l = lines[i + 1] -- Lua tables are 1-based
    if l then
      if not id_idx and l:match '^id:%s*' then
        id_idx = i + 1
      end
      if not aliases_idx and l:match '^aliases:%s*%[' then
        aliases_idx = i + 1
      end
    end
  end

  if id_idx then
    lines[id_idx] = 'id: ' .. new_id
  end

  if aliases_idx then
    lines[aliases_idx] = 'aliases: [' .. old_id .. ']'
  end

  vim.api.nvim_buf_set_lines(buf, 0, n, false, lines)
end

-- Recursively iterate all files under root; yields absolute file paths.
local function iter_files(root, fn)
  local function scan(dir)
    local req = vim.loop.fs_scandir(dir)
    if not req then
      return
    end
    while true do
      local name, t = vim.loop.fs_scandir_next(req)
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

-- Build the replacement lookup used to update backlinks.
-- Bare wiki links become [[new_id|alias_text]].
local function build_search_lookup(old_id, old_rel_path, new_id, new_rel_path)
  local lookup = {}

  -- Helper to add all forms for a single "old" token
  local function add_wiki_forms(old, new_for_prefix, alias_text)
    -- Bare wiki link -> inject alias text
    lookup['[[' .. old .. ']]'] = '[[' .. new_for_prefix .. '|' .. alias_text .. ']]'
    -- Heading form: keep anchor
    lookup['[[' .. old .. '#'] = '[[' .. new_for_prefix .. '#'
    -- Existing alias forms: keep alias as-is
    lookup['[[' .. old .. '|'] = '[[' .. new_for_prefix .. '|'
    lookup['[[' .. old .. '\\|'] = '[[' .. new_for_prefix .. '\\|'
  end

  -- Markdown links: keep the visible alias outside the link; just retarget
  local function add_md_forms(old, new_plain)
    lookup['](' .. old .. ')'] = '](' .. new_plain .. ')'
    lookup['](' .. old .. '#'] = '](' .. new_plain .. '#'
  end

  local old_rel_noext = old_rel_path:gsub('%.md$', '')
  local new_rel_noext = new_rel_path:gsub('%.md$', '')

  local alias = old_id

  -- For wiki links we prefer the *ID* as the target inside [[...]].
  add_wiki_forms(old_id, new_id, alias)
  add_wiki_forms(old_rel_path, new_id, alias)
  add_wiki_forms(old_rel_noext, new_id, alias)

  -- For markdown links, accept any of id/rel/noext and retarget to NEWID (not path)
  add_md_forms(old_id, new_id)
  add_md_forms(old_rel_path, new_id)
  add_md_forms(old_rel_noext, new_id)

  local keys = {}
  for k, _ in pairs(lookup) do
    table.insert(keys, k)
  end
  return lookup, keys
end

-- Do fixed-string replacements using the lookup, returning new text and whether it changed
local function replace_all(text, lookup)
  local changed = false
  for old, new in pairs(lookup) do
    local esc_old = escape_lua(old)
    local before = text
    text = text:gsub(esc_old, new)
    if text ~= before then
      changed = true
    end
  end
  return text, changed
end

-- Windows-safe file rename: try fs_rename, fall back to copy+unlink
local function safe_rename_file(old_path, new_path, current_bufnr)
  local uv = vim.loop

  -- Ensure current buffer is flushed
  if current_bufnr and current_bufnr ~= -1 then
    pcall(function()
      vim.api.nvim_buf_call(current_bufnr, function()
        vim.cmd 'silent noautocmd write!'
      end)
    end)
  end

  -- Try a native rename first
  local ok, err = pcall(uv.fs_rename, old_path, new_path)
  if ok then
    return true
  end

  -- Fallback: copy -> repoint buffer -> unlink
  local ok_copy, err_copy = pcall(uv.fs_copyfile, old_path, new_path, { excl = true })
  if not ok_copy then
    return false, ('rename failed (%s); copy failed (%s)'):format(tostring(err), tostring(err_copy))
  end

  -- Point the buffer at the new path *before* unlinking, so we release the old handle
  if current_bufnr and current_bufnr ~= -1 then
    vim.api.nvim_buf_set_name(current_bufnr, new_path)
    pcall(function()
      vim.api.nvim_buf_call(current_bufnr, function()
        vim.cmd 'silent noautocmd write!'
      end)
    end)
  end

  -- Now try to delete the old file
  local ok_unlink, err_unlink = pcall(uv.fs_unlink, old_path)
  if not ok_unlink then
    -- Schedule a deferred unlink on VimLeave if it’s still locked
    vim.api.nvim_create_autocmd('VimLeavePre', {
      once = true,
      callback = function()
        pcall(uv.fs_unlink, old_path)
      end,
    })
    -- We proceed anyway; file has been copied and buffer updated.
  end

  return true
end

-- ========= main =========

-- New entry point name so you can keep it separate from your own.
M.migrate_current_file_with_alias_links = function()
  pcall(vim.cmd, 'wall')

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

  local old_filename = vim.fs.basename(old_abs)
  local old_id = old_filename:gsub('%.md$', '')
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

  local lookup, keys = build_search_lookup(old_id, old_rel, new_id, new_rel)

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

    -- Quick precheck
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

  -- Windows-safe rename of the current file
  local ok_rename, rerr = safe_rename_file(old_abs, new_abs, buf)
  if not ok_rename then
    vim.notify('Rename failed: ' .. (rerr or ''), vim.log.levels.ERROR)
    return
  end

  -- Ensure buffer points to new path and write
  vim.api.nvim_buf_set_name(buf, new_abs)
  pcall(vim.cmd, 'silent noautocmd write')

  -- Add old id as frontmatter alias and set new id
  update_frontmatter_id_and_alias(old_id, new_id)
  pcall(vim.cmd, 'silent noautocmd write')

  vim.notify(('Migrated to %s.md. Updated backlinks in %d file(s) with inline aliases.'):format(new_id, files_changed), vim.log.levels.INFO)
end

return M
