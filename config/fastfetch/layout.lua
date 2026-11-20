local esc = string.char(27)
local border = esc .. '[38;2;108;112;134m'
local keyc = esc .. '[38;2;203;166;247m'
local textc = esc .. '[38;2;205;214;244m'
local reset = esc .. '[0m'

local apple = {
  "                     ..'",
  '                 ,xNMM.',
  '               .OMMMMo',
  '               lMM"',
  '     .;loddo:.  .olloddol;.',
  '   cKMMMMMMMMMMNWMMMMMMMMMM0:',
  ' .KMMMMMMMMMMMMMMMMMMMMMMMWd.',
  ' XMMMMMMMMMMMMMMMMMMMMMMMX.',
  ';MMMMMMMMMMMMMMMMMMMMMMMM:',
  ':MMMMMMMMMMMMMMMMMMMMMMMM:',
  '.MMMMMMMMMMMMMMMMMMMMMMMMX.',
  ' kMMMMMMMMMMMMMMMMMMMMMMMMWd.',
  " 'XMMMMMMMMMMMMMMMMMMMMMMMMMMk",
  "  'XMMMMMMMMMMMMMMMMMMMMMMMMK.",
  '    kMMMMMMMMMMMMMMMMMMMMMMd',
  '     ;KMMMMMMMWXXWMMMMMMMk.',
  '       "cooc*"    "*coo\'"',
}

local function plain(value)
  return (tostring(value):gsub(esc .. '%[[0-9;]*m', ''):gsub('[%z\1-\31\127]', ' '))
end

local function codepoint(char)
  local a, b, c, d = char:byte(1, 4)
  if a < 128 then return a end
  if a < 224 then return (a - 192) * 64 + b - 128 end
  if a < 240 then return (a - 224) * 4096 + (b - 128) * 64 + c - 128 end
  return (a - 240) * 262144 + (b - 128) * 4096 + (c - 128) * 64 + d - 128
end

local wide_emoji = {
  { 0x231a, 0x231b }, { 0x23e9, 0x23ec }, { 0x23f0, 0x23f0 }, { 0x23f3, 0x23f3 },
  { 0x25fd, 0x25fe }, { 0x2614, 0x2615 }, { 0x2648, 0x2653 }, { 0x267f, 0x267f },
  { 0x2693, 0x2693 }, { 0x26a1, 0x26a1 }, { 0x26aa, 0x26ab }, { 0x26bd, 0x26be },
  { 0x26c4, 0x26c5 }, { 0x26ce, 0x26ce }, { 0x26d4, 0x26d4 }, { 0x26ea, 0x26ea },
  { 0x26f2, 0x26f3 }, { 0x26f5, 0x26f5 }, { 0x26fa, 0x26fa }, { 0x26fd, 0x26fd },
  { 0x2705, 0x2705 }, { 0x270a, 0x270b }, { 0x2728, 0x2728 }, { 0x274c, 0x274c },
  { 0x274e, 0x274e }, { 0x2753, 0x2755 }, { 0x2757, 0x2757 }, { 0x2795, 0x2797 },
  { 0x27b0, 0x27b0 }, { 0x27bf, 0x27bf }, { 0x2b1b, 0x2b1c }, { 0x2b50, 0x2b50 },
  { 0x2b55, 0x2b55 },
}

local function cell_width(char)
  local cp = codepoint(char)
  if (cp >= 0x0300 and cp <= 0x036f)
    or (cp >= 0x1ab0 and cp <= 0x1aff)
    or (cp >= 0x1dc0 and cp <= 0x1dff)
    or (cp >= 0x200b and cp <= 0x200f)
    or (cp >= 0x202a and cp <= 0x202e)
    or (cp >= 0x2060 and cp <= 0x206f)
    or (cp >= 0x20d0 and cp <= 0x20ff)
    or (cp >= 0xfe00 and cp <= 0xfe0f)
    or (cp >= 0xfe20 and cp <= 0xfe2f)
    or (cp >= 0xe0100 and cp <= 0xe01ef) then return 0 end
  if cp >= 0x231a and cp <= 0x2b55 then
    for _, range in ipairs(wide_emoji) do
      if cp >= range[1] and cp <= range[2] then return 2 end
    end
  end
  if (cp >= 0x1100 and cp <= 0x115f)
    or cp == 0x2329 or cp == 0x232a
    or (cp >= 0x2e80 and cp <= 0xa4cf and cp ~= 0x303f)
    or (cp >= 0xac00 and cp <= 0xd7a3)
    or (cp >= 0xf900 and cp <= 0xfaff)
    or (cp >= 0xfe10 and cp <= 0xfe19)
    or (cp >= 0xfe30 and cp <= 0xfe6f)
    or (cp >= 0xff00 and cp <= 0xff60)
    or (cp >= 0xffe0 and cp <= 0xffe6)
    or (cp >= 0x1f000 and cp <= 0x1faff)
    or (cp >= 0x20000 and cp <= 0x3fffd) then return 2 end
  return 1
end

local function chars(value)
  return value:gmatch('[%z\1-\127\194-\244][\128-\191]*')
end

local function width(value)
  local cells = 0
  for char in chars(value) do cells = cells + cell_width(char) end
  return cells
end

local function clip(value, limit)
  local text = plain(value)
  if limit <= 0 then return '' end
  if width(text) <= limit then return text end
  local result, cells = {}, 0
  for char in chars(text) do
    local size = cell_width(char)
    if cells + size > limit - 1 then break end
    result[#result + 1], cells = char, cells + size
  end
  return table.concat(result) .. '…'
end

local function pad(value, limit)
  local text = clip(value, limit)
  return text .. string.rep(' ', limit - width(text))
end

local function get(object, key, fallback)
  if type(object) == 'table' and object[key] ~= nil and object[key] ~= '' then
    return plain(object[key])
  end
  return fallback or 'n/a'
end

local function number(object, key)
  local value = tonumber(get(object, key, ''))
  return value and string.format('%.2f', value) or 'n/a'
end

local function panels(v)
  local function g(name, key) return get(v[name], key) end
  local battery = g('battery', 'status')
  if battery:find('Charging') then battery = 'Charging'
  elseif battery:find('AC Connected') then battery = 'AC' end
  return {
    { title = 'MACHINE', rows = {
      { '', 'OS', 'OS', g('os', 'name') .. ' ' .. g('os', 'version') .. ' · ' .. g('os', 'arch') },
      { '󰌢', 'HOST', 'HOST', g('host', 'name') },
      { '󰘧', 'MODEL', 'MODEL', g('host', 'family') .. ' · build ' .. g('os', 'buildId') },
      { '', 'KERNEL', 'KERN', g('os', 'sysname') .. ' ' .. g('os', 'kernelRelease') },
      { '󰅐', 'UPTIME', 'UP', g('uptime', 'formatted') },
      { '󰏖', 'PACKAGES', 'PKGS', g('packages', 'brew') .. ' brew · ' .. g('packages', 'brewCask') .. ' casks' },
    } },
    { title = 'STATUS', rows = {
      { '󰓅', 'CPU', 'CPU', g('cpuusage', 'avg') .. ' avg · ' .. g('cpuusage', 'max') .. ' peak' },
      { '󰾲', 'GPU', 'GPU', g('gpu', 'coreUsageNum') .. ' core · ' .. g('gpu', 'sharedPercentageNum') .. ' shared' },
      { '', 'MEMORY', 'MEM', g('memory', 'used') .. ' / ' .. g('memory', 'total') .. ' · ' .. g('memory', 'percentage') },
      { '', 'DISK', 'DISK', g('disk', 'sizeUsed') .. ' / ' .. g('disk', 'sizeTotal') .. ' · ' .. g('disk', 'sizePercentage') },
      { '', 'BATTERY', 'BATT', g('battery', 'capacity') .. ' · ' .. g('battery', 'cycleCount') .. ' cycles · ' .. battery },
      { '󰊚', 'LOAD', 'LOAD', number(v.load, 'loadavg1') .. ' / ' .. number(v.load, 'loadavg2') .. ' / ' .. number(v.load, 'loadavg3') .. ' · ' .. g('processes', 'result') .. ' proc' },
    } },
    { title = 'HARDWARE', rows = {
      { '', 'CPU', 'CPU', g('cpu', 'name') .. ' · ' .. g('cpu', 'coreTypes') .. ' · ' .. g('cpu', 'freqMax') },
      { '󰾲', 'GPU', 'GPU', g('gpu', 'name'):gsub('Apple ', '') .. ' · ' .. g('gpu', 'coreCount') .. 'c · ' .. g('gpu', 'frequency'):gsub(' ', '') .. ' · ' .. (g('gpu', 'type') == 'Integrated' and 'iGPU' or g('gpu', 'type')) },
      { '󰍹', 'DISPLAY', 'DISP', g('display', 'width') .. 'x' .. g('display', 'height') .. '@' .. g('display', 'refreshRate') .. ' · ' .. g('display', 'inch') .. 'in ' .. g('display', 'type') },
      { '', 'RAM', 'RAM', g('memory', 'total') .. ' unified' },
      { '', 'STORAGE', 'STOR', g('disk', 'sizeAvailable') .. ' free · ' .. g('disk', 'filesystem') },
      { '󰚥', 'POWER', 'PWR', g('adapter', 'name') },
    } },
    { title = 'ENVIRONMENT', rows = {
      { '', 'SHELL', 'SHELL', g('shell', 'prettyName') .. ' ' .. g('shell', 'version') },
      { '󱞎', 'EDITOR', 'EDIT', g('editor', 'name') .. ' ' .. g('editor', 'version') },
      { '', 'TERMINAL', 'TERM', g('terminal', 'prettyName') .. ' ' .. g('terminal', 'version') },
      { '', 'FONT', 'FONT', g('font', 'combined') },
      { '󰩟', 'LOCAL IP', 'IP', g('ip', 'ipv4') .. ' · ' .. g('ip', 'ifname') },
      { '', 'WI-FI', 'WI-FI', g('wifi', 'ssid') .. ' · ' .. g('wifi', 'protocol') .. ' · ' .. g('wifi', 'signalQuality') },
    } },
  }
end

local function panel_lines(panel, columns, compact)
  local lines = {}
  if columns < 6 then
    lines[1] = keyc .. clip(panel.title, columns) .. reset
    for _, row in ipairs(panel.rows) do
      lines[#lines + 1] = textc .. clip(row[3] .. ' ' .. row[4], columns) .. reset
    end
    return lines
  end
  local title = clip(panel.title, columns - 5)
  lines[1] = border .. '╭─ ' .. keyc .. title .. border .. ' ' .. string.rep('─', columns - 5 - width(title)) .. '╮' .. reset
  local key_width = compact and math.min(7, math.floor((columns - 5) / 3)) or 12
  local value_width = columns - key_width - 5
  for _, row in ipairs(panel.rows) do
    local key = compact and row[3] or row[1] .. '  ' .. row[2]
    lines[#lines + 1] = border .. '│ ' .. keyc .. pad(key, key_width) .. ' ' .. textc .. pad(row[4], value_width) .. border .. ' │' .. reset
  end
  lines[#lines + 1] = border .. '╰' .. string.rep('─', columns - 2) .. '╯' .. reset
  return lines
end

local function render(columns, values)
  columns = tonumber(columns)
  columns = columns and columns >= 1 and math.floor(columns) or 80
  local logo_width = 0
  for _, line in ipairs(apple) do logo_width = math.max(logo_width, width(line)) end
  local logo = columns >= 127
  local available = columns - (logo and logo_width + 3 or 0)
  local count = available >= 94 and 2 or 1
  local panel_width = math.floor((available - (count - 1) * 2) / count)
  local sections, lines = panels(values), {}
  for index = 1, #sections, count do
    if #lines > 0 then lines[#lines + 1] = '' end
    local left = panel_lines(sections[index], panel_width, columns < 46)
    local right = count == 2 and panel_lines(sections[index + 1], panel_width, false)
    for row = 1, #left do
      lines[#lines + 1] = left[row] .. (right and '  ' .. right[row] or '')
    end
  end
  if logo then
    for index = 1, math.max(#lines, #apple) do
      lines[index] = reset .. pad(apple[index] or '', logo_width) .. '   ' .. (lines[index] or '')
    end
  end
  return table.concat(lines, '\n')
end

return { render = render }
