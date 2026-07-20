local Path = require 'plenary.path'
local base_history = require 'telescope.actions.history'

local uv = vim.uv

local M = {}

local function write_async(path, text, flag)
  uv.fs_open(path, flag, 438, function(open_err, fd)
    assert(not open_err, open_err)
    uv.fs_write(fd, text, -1, function(write_err)
      assert(not write_err, write_err)
      uv.fs_close(fd, function(close_err)
        assert(not close_err, close_err)
      end)
    end)
  end)
end

local function append_async(path, text)
  write_async(path, text, 'a')
end

local function history_key(picker)
  return picker.prompt_title or '__default__'
end

local function encode_entry(entry)
  return string.format('%s\t%s', entry.key, entry.value)
end

local function parse_entry(line)
  local key, value = line:match '^(.-)\t(.*)$'
  if key and value then
    return { key = key, value = value }
  end
end

local function rebuild_bucket_indexes(self)
  self._bucket_indexes = {}
  for index, entry in ipairs(self._all_entries) do
    local bucket = self._bucket_indexes[entry.key] or {}
    bucket[#bucket + 1] = index
    self._bucket_indexes[entry.key] = bucket
  end
end

local function bucket_lines(self, key)
  local lines = {}
  for _, index in ipairs(self._bucket_indexes[key] or {}) do
    lines[#lines + 1] = self._all_entries[index].value
  end
  return lines
end

local function rewrite_history(self)
  local lines = {}
  for _, entry in ipairs(self._all_entries) do
    lines[#lines + 1] = encode_entry(entry)
  end

  local data = #lines > 0 and table.concat(lines, '\n') .. '\n' or ''
  write_async(self.path, data, 'w')
end

function M.new()
  return base_history.new {
    init = function(obj)
      local path = Path:new(obj.path)
      if not path:exists() then
        path:touch { parents = true }
      end

      obj._all_entries = {}
      for _, line in ipairs(path:readlines()) do
        local entry = parse_entry(line)
        if entry then
          obj._all_entries[#obj._all_entries + 1] = entry
        end
      end

      rebuild_bucket_indexes(obj)
      obj.content = {}
      obj.index = 1
      obj._active_key = nil
    end,
    reset = function(self)
      self.index = #self.content + 1
    end,
    append = function(self, line, picker, no_reset)
      if line ~= '' then
        local key = history_key(picker)
        local bucket = self._bucket_indexes[key] or {}
        local last_index = bucket[#bucket]
        local last_entry = last_index and self._all_entries[last_index]

        if not last_entry or last_entry.value ~= line then
          local entry = { key = key, value = line }
          self._all_entries[#self._all_entries + 1] = entry
          bucket[#bucket + 1] = #self._all_entries
          self._bucket_indexes[key] = bucket

          local total = #self._all_entries
          if self.limit and total > self.limit then
            local diff = total - self.limit
            for _ = 1, diff do
              table.remove(self._all_entries, 1)
            end
            rebuild_bucket_indexes(self)
            rewrite_history(self)
          else
            append_async(self.path, encode_entry(entry) .. '\n')
          end
        end
      end

      if not no_reset then
        self:reset()
      end
    end,
    pre_get = function(self, _, picker)
      local key = history_key(picker)
      self.content = bucket_lines(self, key)

      if self._active_key ~= key or self.index > #self.content + 1 then
        self.index = #self.content + 1
      end

      self._active_key = key
    end,
  }
end

return M
