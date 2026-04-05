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

-- ---------- MOC helpers ----------

-- Check if file exists
local function file_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == 'file'
end

-- Get MOC chain from file path (skip "Content" folder)
local function get_moc_chain_from_path(vault_root, file_abs_path)
  local rel = rel_from(vault_root, file_abs_path)
  local parts = {}
  for part in rel:gmatch '[^/\\]+' do
    parts[#parts + 1] = part
  end
  table.remove(parts) -- Remove filename

  if parts[1] and parts[1] == 'Content' then
    table.remove(parts, 1)
  end

  return parts -- e.g., {"Games", "Tekken", "Characters"}
end

-- Build MOC index (for batch migration efficiency)
local function build_moc_index(vault_root)
  local index = {}
  iter_files(vault_root, function(p)
    if p:sub(-3):lower() ~= '.md' then
      return
    end

    -- Check filename pattern
    local filename = vim.fs.basename(p)
    local moc_name = filename:match '^_MOC%s+(.+)%.md$'
    if moc_name then
      index[moc_name:lower()] = p
      return
    end

    -- Check frontmatter aliases for migrated MOCs
    local content = read_file(p)
    if content and content:match '^%-%-%-' then
      local fm = content:match '^%-%-%-(.-)%-%-%-'
      if fm then
        for alias in fm:gmatch '_MOC%s+([^%]\n,]+)' do
          alias = alias:gsub('^%s*', ''):gsub('%s*$', '')
          if alias ~= '' then
            index[alias:lower()] = p
          end
        end
      end
    end
  end)
  return index
end

-- Find MOC by folder name
local function find_moc(vault_root, folder_name, moc_index)
  if moc_index then
    return moc_index[folder_name:lower()]
  end
  local direct_path = join_paths(vault_root, '_MOC ' .. folder_name .. '.md')
  if file_exists(direct_path) then
    return direct_path
  end
  return nil
end

-- Create a new MOC file
local function create_moc(vault_root, folder_name)
  local moc_id = generate_zettelkasten_id()
  local moc_path = join_paths(vault_root, '_MOC ' .. folder_name .. '.md')

  local content = string.format(
    [[---
id: %s
aliases:
  - _MOC %s
  - %s MOC
tags:
  - moc
---
# _MOC %s

]],
    moc_id,
    folder_name,
    folder_name,
    folder_name
  )

  local ok = write_file(moc_path, content)
  if ok then
    return moc_path, moc_id
  end
  return nil, nil
end

-- Add link to MOC (if not already present)
local function add_link_to_moc(moc_path, link_target, link_display)
  local content = read_file(moc_path)
  if not content then
    return false
  end

  if content:find(link_target, 1, true) then
    return true -- Already linked
  end

  content = content:gsub('%s*$', '')
  local link = '[[' .. link_target .. '|' .. link_display .. ']]'
  content = content .. '\n' .. link .. '\n'

  return write_file(moc_path, content)
end

-- Process MOC chain: create missing MOCs and add links
local function process_moc_chain(vault_root, moc_chain, final_target_id, final_target_display, moc_index, created_mocs)
  if #moc_chain == 0 then
    return
  end

  created_mocs = created_mocs or {}
  moc_index = moc_index or {}

  local prev_moc_path = nil

  for i, folder_name in ipairs(moc_chain) do
    local moc_path = find_moc(vault_root, folder_name, moc_index)

    if not moc_path then
      local new_path, new_id = create_moc(vault_root, folder_name)
      if new_path then
        moc_path = new_path
        moc_index[folder_name:lower()] = new_path
        created_mocs[folder_name] = new_path
        vim.notify('Created MOC: _MOC ' .. folder_name, vim.log.levels.INFO)
      end
    end

    if moc_path then
      -- Link previous MOC to this one
      if prev_moc_path then
        add_link_to_moc(prev_moc_path, '_MOC ' .. folder_name, '_MOC ' .. folder_name)
      end

      -- Last MOC links to final target
      if i == #moc_chain then
        add_link_to_moc(moc_path, final_target_id, final_target_display)
      end
    end

    prev_moc_path = moc_path
  end
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
  -- If no frontmatter exists, create it
  if not ((get(0) or ''):match '^%-%-%-$') then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, n, false)
    local new_fm = {
      '---',
      'id: ' .. new_id,
      'aliases: [' .. old_alias_text .. ']',
      '---',
      '',
    }
    for i = #new_fm, 1, -1 do
      table.insert(lines, 1, new_fm[i])
    end
    vim.api.nvim_buf_set_lines(buf, 0, n, false, lines)
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
  local id_idx
  local aliases_start_idx, aliases_is_multiline

  -- Find id and aliases (inline OR multi-line)
  for i = 1, fm_end - 1 do
    local l = lines[i + 1]
    if l then
      if (not id_idx) and l:match '^id:%s*' then
        id_idx = i + 1
      end
      if not aliases_start_idx then
        if l:match '^aliases:%s*%[' then
          aliases_start_idx = i + 1
          aliases_is_multiline = false
        elseif l:match '^aliases:%s*$' then
          aliases_start_idx = i + 1
          aliases_is_multiline = true
        end
      end
    end
  end

  if id_idx then
    lines[id_idx] = 'id: ' .. new_id
  else
    table.insert(lines, 2, 'id: ' .. new_id)
    fm_end = fm_end + 1
    -- Adjust indices if we inserted before them
    if aliases_start_idx and aliases_start_idx >= 2 then
      aliases_start_idx = aliases_start_idx + 1
    end
    if id_idx and id_idx >= 2 then
      id_idx = id_idx + 1
    else
      id_idx = 2
    end
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

  -- Parse aliases (either inline or multi-line)
  local alias_list = {}
  local aliases_end_idx = aliases_start_idx

  if aliases_start_idx then
    if aliases_is_multiline then
      -- Parse multi-line aliases: collect "  - value" lines
      for i = aliases_start_idx, fm_end - 1 do
        local l = lines[i + 1]
        if l and l:match '^%s+%-%s' then
          aliases_end_idx = i + 1
          local value = l:match '^%s+%-%s*(.*)$'
          if value then
            value = value:gsub('^%s*', ''):gsub('%s*$', '')
            value = value:gsub([[^"(.*)"$]], '%1'):gsub([[^'(.*)'$]], '%1')
            if value ~= '' then
              alias_list[#alias_list + 1] = value
            end
          end
        else
          break
        end
      end
    else
      alias_list = parse_inline_list(lines[aliases_start_idx])
    end
  end

  -- Build new aliases list with old_alias_text first
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

  if aliases_start_idx then
    -- Remove old aliases lines (multi-line or single)
    local remove_count = aliases_end_idx - aliases_start_idx + 1
    for _ = 1, remove_count do
      table.remove(lines, aliases_start_idx)
    end
    -- Insert new inline aliases at the same position
    table.insert(lines, aliases_start_idx, line)
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

M.migrate_current_file_with_alias_links = function(opts)
  opts = opts or {}
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

  -- Get MOC chain before migration (based on original folder path)
  local moc_chain = get_moc_chain_from_path(vault, old_abs)

  -- old_alias_text is the full filename without .md (may contain spaces)
  local old_filename = vim.fs.basename(old_abs)
  local old_alias_text = old_filename:gsub('%.md$', '')

  local new_id = generate_zettelkasten_id()
  if not new_id or new_id == '' then
    vim.notify('Failed to generate Zettelkasten ID.', vim.log.levels.ERROR)
    return
  end

  local new_filename = new_id .. '.md'
  -- Move to vault root (flat structure)
  local new_abs = join_paths(vault, new_filename)

  local old_rel = rel_from(vault, old_abs)
  local new_rel = new_filename -- At vault root, relative path is just the filename

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

  -- Auto-format with conform (if available)
  pcall(function()
    require('conform').format { bufnr = buf, async = false }
  end)
  write_now(buf)

  -- Process MOC chain: create missing MOCs and add links
  if #moc_chain > 0 then
    process_moc_chain(vault, moc_chain, new_id, old_alias_text, opts.moc_index, opts.created_mocs)
  end

  vim.notify(('Migrated to %s (vault root). Updated backlinks in %d file(s).'):format(new_id, files_changed), vim.log.levels.INFO)
end

-- ========= batch migration =========

-- Check if a filename matches the zettelkasten pattern: {unix_timestamp}-{4 uppercase letters}.md
local function is_migrated(filename)
  return filename:match '^%d+%-[A-Z][A-Z][A-Z][A-Z]%.md$' ~= nil
end

-- Get list of all unmigrated .md files in the vault
local function get_unmigrated_files(vault_root)
  local unmigrated = {}
  iter_files(vault_root, function(abs_path)
    if abs_path:sub(-3):lower() ~= '.md' then
      return
    end
    local filename = vim.fs.basename(abs_path)
    if not is_migrated(filename) then
      unmigrated[#unmigrated + 1] = abs_path
    end
  end)
  table.sort(unmigrated)
  return unmigrated
end

-- List all unmigrated files in a floating window
M.list_unmigrated_files = function()
  local buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(buf)
  if current_file == '' then
    vim.notify('No file in current buffer to determine vault root.', vim.log.levels.ERROR)
    return
  end

  local vault = find_vault_root(current_file)
  if not vault then
    vim.notify('Could not locate Obsidian vault root (.obsidian).', vim.log.levels.ERROR)
    return
  end

  local unmigrated = get_unmigrated_files(vault)
  local count = #unmigrated

  if count == 0 then
    vim.notify('All files are already migrated!', vim.log.levels.INFO)
    return
  end

  -- Create display lines with relative paths
  local display_lines = { ('Found %d unmigrated file(s):'):format(count), '' }
  for _, abs_path in ipairs(unmigrated) do
    local rel = rel_from(vault, abs_path)
    display_lines[#display_lines + 1] = '  ' .. rel
  end

  -- Create floating window
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, display_lines)

  local width = 80
  local height = math.min(#display_lines + 2, 30)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(float_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Unmigrated Files ',
    title_pos = 'center',
  })

  -- Set buffer options
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].bufhidden = 'wipe'

  -- Close on q or Esc
  vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = float_buf, silent = true })
  vim.keymap.set('n', '<Esc>', '<Cmd>close<CR>', { buffer = float_buf, silent = true })

  return count
end

-- Migrate all unmigrated files in the vault (batch_size files at a time, default 10)
M.migrate_all_unmigrated = function(batch_size)
  batch_size = batch_size or 100

  local buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(buf)
  if current_file == '' then
    vim.notify('No file in current buffer to determine vault root.', vim.log.levels.ERROR)
    return
  end

  local vault = find_vault_root(current_file)
  if not vault then
    vim.notify('Could not locate Obsidian vault root (.obsidian).', vim.log.levels.ERROR)
    return
  end

  local unmigrated = get_unmigrated_files(vault)
  local total = #unmigrated

  if total == 0 then
    vim.notify('All files are already migrated!', vim.log.levels.INFO)
    return
  end

  vim.notify(('Found %d unmigrated file(s). Processing in batches of %d...'):format(total, batch_size), vim.log.levels.INFO)

  -- Build MOC index once for batch efficiency
  local moc_index = build_moc_index(vault)
  local created_mocs = {}

  local migrated_count = 0
  local errors = {}

  for i, abs_path in ipairs(unmigrated) do
    -- Open the file in the current buffer
    local ok, err = pcall(function()
      vim.cmd('edit ' .. vim.fn.fnameescape(abs_path))
      M.migrate_current_file_with_alias_links {
        moc_index = moc_index,
        created_mocs = created_mocs,
      }
      migrated_count = migrated_count + 1
    end)

    if not ok then
      errors[#errors + 1] = { path = abs_path, error = tostring(err) }
    end

    -- Pause every batch_size files
    if i % batch_size == 0 and i < total then
      vim.cmd 'redraw'
      local choice = vim.fn.confirm(
        ('Migrated %d/%d files. Continue?'):format(i, total),
        '&Yes\n&No',
        1
      )
      if choice ~= 1 then
        vim.notify(('Stopped after %d file(s). Run :ZettelMigrateAll to continue.'):format(migrated_count), vim.log.levels.INFO)
        return
      end
    end
  end

  -- Count created MOCs
  local moc_count = 0
  for _ in pairs(created_mocs) do
    moc_count = moc_count + 1
  end

  -- Final report
  if #errors == 0 then
    vim.notify(('Successfully migrated all %d file(s). Created %d new MOC(s).'):format(migrated_count, moc_count), vim.log.levels.INFO)
  else
    vim.notify(
      ('Migrated %d file(s) with %d error(s). Created %d MOC(s). Check :messages for details.'):format(migrated_count, #errors, moc_count),
      vim.log.levels.WARN
    )
    for _, e in ipairs(errors) do
      vim.notify(('  Error in %s: %s'):format(e.path, e.error), vim.log.levels.ERROR)
    end
  end
end

return M
