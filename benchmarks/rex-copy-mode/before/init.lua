-- Windows, panes, and zoom follow tmux, behind the same ctrl+space prefix.
-- Rex's own cmd shortcuts stay as they ship. Appearance lives in the app's
-- Settings, not here.

local SHELL = "com.superlogical.terminal.shell"
local TERMINAL = "com.superlogical.terminal"
local PREFIX = "ctrl+space>"

local function check(result, err)
  if err ~= nil then error(err, 0) end
  return result
end

-- The terminal reports its directory as file://host/path.
local function block_cwd(block_id)
  if block_id == nil then return nil end
  local r = rex.block.call(TERMINAL, "pwd", { block_id = block_id })
  local url = r and r.pwd
  if type(url) ~= "string" then return nil end
  return (url:gsub("^file://[^/]*", ""))
end

local function shell_here(ctx)
  return rex.layout.block{ flavor = SHELL, options = { cwd = block_cwd(ctx.block_id) } }
end

-- tmux's -c "#{pane_current_path}": new panes and tabs start where you are.
rex.action{
  name = "split_here",
  title = "Split Pane Here",
  args = { direction = "string" },
  run = function(ctx, args)
    check(rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = (args.direction == "down" or args.direction == "up") and "vertical" or "horizontal",
      side = (args.direction == "left" or args.direction == "up") and "before" or "after",
      layout = shell_here(ctx),
      focus = true,
    })
  end,
}

rex.action{
  name = "tab_here",
  title = "New Tab Here",
  run = function(ctx)
    check(rex.session.new_window{ layout = shell_here(ctx), focus = true })
  end,
}

local function block_rect(node, block_id)
  if node == nil then return nil end
  if node.block_id == block_id then return node.rect end
  if node.split then
    return block_rect(node.split.before, block_id) or block_rect(node.split.after, block_id)
  end
end

rex.action{
  name = "copy_mode",
  title = "Copy Mode (Neovim)",
  run = function(ctx)
    local view = check(rex.session.view{})
    local config_home = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
    for _, window in ipairs(view.windows or {}) do
      for _, layer in ipairs(window.layers or {}) do
        local bounds = block_rect(layer.layout, ctx.block_id)
        if bounds then
          local zoomed = window.zoomed_block_id == ctx.block_id
          return check(rex.session.new_layer{
            window_id = window.window_id,
            bounds = zoomed and { 0, 0, 1, 1 } or bounds,
            focus = true,
            layout = rex.layout.block{
              flavor = SHELL,
              label = "Copy Mode",
              options = {
                command = {
                  "sh", "-c", [[
set -eu
scrollback=$(mktemp "${TMPDIR:-/tmp}/rex-copy-mode.XXXXXX")
trap '
  rm -f "$scrollback"
  rex focus -s "$1" "$2" >/dev/null 2>&1 || :
  if [ "$4" = true ]; then rex zoom -s "$1" "$2" --on >/dev/null 2>&1 || :; fi
' EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
rex capture -s "$1" -b "$2" --trim --unwrap > "$scrollback"
nvim -u "$3" -i NONE -n -R -- "$scrollback"
]],
                  "rex-copy-mode", ctx.session_id, ctx.block_id,
                  config_home .. "/rex/copy-mode.lua", tostring(zoomed),
                },
              },
            },
          })
        end
      end
    end
    error("The focused pane is no longer in the layout")
  end,
}

-- tmux `bind -r`: the first resize enters resize mode, so hjkl keeps resizing
-- until escape, enter, or q.
rex.action{
  name = "resize_repeat",
  title = "Resize Pane and Keep Resizing",
  args = { direction = "string" },
  run = function(ctx, args)
    rex.client.queue("pane.resize", { direction = args.direction, amount = 7 })
    rex.client.queue("client.mode.enter", { name = "resize" })
  end,
}

-- Without the prefix (bind -n)
rex.bind("alt+h", "client.tab.previous")
rex.bind("alt+l", "client.tab.next")
for i = 1, 4 do
  rex.bind("alt+" .. i, "client.tab.goto", { index = i })
end

-- Behind the prefix
rex.bind(PREFIX .. "ctrl+space", "pane.send_key", { key = "ctrl+space" })
rex.bind(PREFIX .. "r", "client.config.reload")
rex.bind(PREFIX .. "[", "copy_mode")

local directions = { h = "left", j = "down", k = "up", l = "right" }
for key, direction in pairs(directions) do
  rex.bind(PREFIX .. key, "pane.focus", { direction = direction })
  rex.bind(PREFIX .. "shift+" .. key, "resize_repeat", { direction = direction })
  rex.bind("resize/" .. key, "pane.resize", { direction = direction, amount = 7 })
  rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 7 })
end
rex.mode("resize", { exclusive = true })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/q", "client.mode.exit")

rex.bind(PREFIX .. "c", "tab_here")
rex.bind(PREFIX .. "shift+\\", "split_here", { direction = "right" })
rex.bind(PREFIX .. "-", "split_here", { direction = "down" })
rex.bind(PREFIX .. "z", "pane.zoom")
rex.bind(PREFIX .. "o", "pane.focus_next")
rex.bind(PREFIX .. "x", "pane.close")
rex.bind(PREFIX .. "shift+1", "pane.move_to_new_tab")
rex.bind(PREFIX .. "shift+7", "client.tab.close")
rex.bind(PREFIX .. "n", "client.tab.next")
rex.bind(PREFIX .. "p", "client.tab.previous")
rex.bind(PREFIX .. ",", "client.tab.rename")
rex.bind(PREFIX .. "shift+4", "session.rename")
rex.bind(PREFIX .. "e", "session.switch")
