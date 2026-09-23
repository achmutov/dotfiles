-- additional externals:
-- * wpctl
-- * scrot
-- * xbacklight
-- * xclip
-- * xdg-open
-- * tesseract

local terminal_cmd = "alacritty"
local lock_screen_cmd = "xsecurelock"
local browser_cmd = "gtk-launch helium"
local compositor_cmd = "picom"
---@type string?
local backlight = "acpi_video0"
---@type string?
local power_supply = "BAT0"

local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")

local modkey = "Mod4"

---@generic T: any
---@param fn fun(...): T
---@return  fun(): T
local function wrap(fn, ...)
  local vararg = { ... }
  return function()
    return fn(unpack(vararg))
  end
end

local function error_handling()
  naughty.connect_signal("request::display_error", function(message, startup)
    ---@cast message string
    ---@cast startup boolean
    naughty.notification({
      urgency = "critical",
      title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
      message = message,
    })
  end)
end
error_handling()

local menubar = require("menubar")
menubar.utils.terminal = terminal_cmd

local function setup_theme()
  local dpi = require("beautiful.xresources").apply_dpi

  local theme = {}

  theme.font = "sans 8"

  theme.bg_normal = "#000000"
  theme.bg_focus = "#222222"
  theme.bg_urgent = "#ff0000"
  theme.bg_minimize = "#444444"
  theme.bg_systray = theme.bg_normal

  theme.fg_normal = "#aaaaaa"
  theme.fg_focus = "#ffffff"
  theme.fg_urgent = "#ffffff"
  theme.fg_minimize = "#ffffff"

  theme.border_width = dpi(1)
  theme.border_normal = "#000000"
  theme.border_focus = "#6F5282"
  theme.border_marked = "#91231c"

  theme.notification_font = "JetBrainsMono Nerd Font"
  theme.notification_border_color = theme.border_focus

  local theme_assets = require("beautiful.theme_assets")
  local taglist_square_size = dpi(4)
  theme.taglist_squares_sel = theme_assets.taglist_squares_sel(taglist_square_size, theme.fg_normal)
  theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(taglist_square_size, theme.fg_normal)

  theme.menu_height = dpi(15)
  theme.menu_width = dpi(100)

  theme.layout_tile = "~/.config/awesome/resources/layout_tilew.png"
  theme.layout_floating = "~/.config/awesome/resources/layout_floatingw.png"
  theme.layout_fairv = "~/.config/awesome/resources/layout_fairvw.png"
  theme.layout_fullscreen = "~/.config/awesome/resources/layout_fullscreenw.png"

  beautiful.init(theme)
end
setup_theme()

local function setup_focus()
  require("awful.autofocus")
  client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", { raise = false })
  end)
end
setup_focus()

local function setup_layouts()
  tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts({
      awful.layout.suit.tile,
      awful.layout.suit.floating,
      awful.layout.suit.fair,
      awful.layout.suit.max.fullscreen,
    })
  end)
end
setup_layouts()

---@param func fun()
---@param timeout number?
---@return fun()
local function throttle(func, timeout)
  timeout = timeout or 0.1

  -- keep this timer around
  local timer
  _ = timer
  local ready = true

  return function()
    if ready then
      ready = false
      func()

      timer = gears.timer.start_new(timeout, function()
        ready = true
        return false
      end)
    end
  end
end

local refresh_volume_widget = function() end
local refresh_brightness_widget = function() end

local function setup_screens()
  screen.connect_signal("request::wallpaper", function(s)
    awful.wallpaper({
      screen = s,
      widget = {
        {
          image = beautiful.wallpaper,
          upscale = true,
          downscale = true,
          widget = wibox.widget.imagebox,
        },
        valign = "center",
        halign = "center",
        tiled = false,
        widget = wibox.container.tile,
      },
    })
  end)
  screen.connect_signal("request::desktop_decoration", function(s)
    local function update_volume_widget(widget, stdout)
      ---@param value string
      ---@param icon string?
      ---@return string
      local function volume_format(value, icon)
        return " | " .. (icon or " ") .. " " .. tostring(value) .. " | "
      end

      local trimmed = stdout:gsub("%s+$", ""):sub(#"Volume: " + 1)
      local volume_value = tonumber(stdout:match("[%d.]+"))
      if volume_value == nil then
        widget:set_text(volume_format("failed to parse volume"))
        return
      end
      local volume_percent = tostring(math.floor(volume_value * 100)) .. "%"

      if trimmed:find("MUTED") == nil then
        widget:set_text(volume_format(volume_percent, " "))
      else
        widget:set_text(volume_format(volume_percent))
      end
    end
    local volume_widget, volume_timer = awful.widget.watch("wpctl get-volume @DEFAULT_SINK@", 10, update_volume_widget)
    refresh_volume_widget = throttle(function()
      volume_timer:emit_signal("timeout")
    end)

    local brightness_widget
    if backlight then
      ---@param widget table
      ---@param stdout string
      ---@param _ any
      ---@param _ any
      ---@param exitcode number
      local function update_brightness_widget(widget, stdout, _, _, exitcode)
        local function brightness_format(value)
          return "● " .. value .. " | "
        end

        if exitcode ~= 0 then
          widget:set_text(brightness_format("missing " .. backlight))
          return
        end

        local brightness = stdout:gsub("%s+$", "")

        widget:set_text(brightness_format(brightness .. "%"))
      end
      local brightness_timer
      brightness_widget, brightness_timer = awful.widget.watch(
        "cat /sys/class/backlight/" .. backlight .. "/actual_brightness",
        10,
        update_brightness_widget
      )
      refresh_brightness_widget = throttle(function()
        brightness_timer:emit_signal("timeout")
      end)
    end

    local battery_widget
    if power_supply then
      ---@param widget table
      ---@param stdout string
      ---@param _ any
      ---@param _ any
      ---@param exitcode number
      local function update_battery_widget(widget, stdout, _, _, exitcode)
        local function bat_format(value)
          return "bat " .. value .. " | "
        end

        if exitcode ~= 0 then
          widget:set_text(bat_format("missing battery " .. power_supply))
          return
        end

        local capacity_prefix = "POWER_SUPPLY_CAPACITY="
        local capacity_line = stdout:match(capacity_prefix .. "%d+")
        if not capacity_line then
          widget:set_text(bat_format("failed to get capacity"))
          return
        end
        local capacity = capacity_line:sub(#capacity_prefix + 1)

        local status_prefix = "POWER_SUPPLY_STATUS="
        local status_line = stdout:match(status_prefix .. "[^\n]+")
        if not status_line then
          widget:set_text(bat_format("failed to get status"))
          return
        end

        local status_str = status_line:sub(#status_prefix + 1)
        local status = ""
        if status_str == "Charging" then
          status = " "
        elseif status_str == "Not charging" then
          status = "  "
        elseif status_str == "Discharging" then
          status = "↓"
        end

        widget:set_text(bat_format(capacity .. "%" .. status))
      end
      battery_widget =
        awful.widget.watch("cat /sys/class/power_supply/" .. power_supply .. "/uevent", 10, update_battery_widget)
    end

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
    s.mypromptbox = awful.widget.prompt()
    awful.wibar({
      position = "top",
      screen = s,
      widget = {
        layout = wibox.layout.align.horizontal,
        {
          layout = wibox.layout.fixed.horizontal,
          awful.widget.taglist({
            screen = s,
            filter = awful.widget.taglist.filter.all,
          }),
          s.mypromptbox,
        },
        awful.widget.tasklist({
          screen = s,
          filter = awful.widget.tasklist.filter.currenttags,
        }),
        {
          layout = wibox.layout.fixed.horizontal,
          volume_widget,
          brightness_widget,
          battery_widget,
          wibox.widget.systray(),
          awful.widget.keyboardlayout(),
          wibox.widget.textclock("| %a %F | %H:%M "),
          awful.widget.layoutbox(s),
        },
      },
    })
  end)
end
setup_screens()

local function setup_rules()
  local ruled = require("ruled")
  ruled.client.connect_signal("request::rules", function()
    local general = {
      {
        rule = {},
        properties = {
          focus = awful.client.focus.filter,
          raise = true,
          screen = awful.screen.preferred,
          placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
        callback = awful.client.setslave,
      },
      {
        rule = { role = "pop-up" },
        properties = { floating = true },
      },
    }
    ruled.client.append_rules(general)

    local telegram = {
      {
        rule = { name = "Telegram" },
        except = { name = "TelegramDesktop" },
        properties = {
          floating = true,
          height = 500,
          width = 300,
        },
      },
      {
        rule = { class = "Telegram", name = "Media viewer" },
        properties = { maximized = true },
      },
    }
    ruled.client.append_rules(telegram)
  end)
end
setup_rules()

---@alias Trigger [string[], string|number]
---@alias Mapping { [1]: Trigger, [2]: fun(...), opts?: table }
---@param mappings Mapping[]
---@param mapping_type "button"|"key"
local map_bindings = function(mappings, mapping_type)
  local awful_fun
  if mapping_type == "button" then
    awful_fun = awful.button
  else
    awful_fun = awful.key
  end
  return gears.table.map(function(mapping)
    ---@cast mapping Mapping
    local trigger, callback = unpack(mapping)
    local modifiers, button = unpack(trigger)
    ---@diagnostic disable-next-line: call-non-callable
    return awful_fun(modifiers, button, callback)
  end, mappings)
end

local function setup_client_bindings()
  client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings(map_bindings({
      {
        { {}, awful.button.names.LEFT },
        function(c)
          c:emit_signal("request::activate", "mouse_click", { raise = true })
        end,
      },
      {
        { { modkey }, awful.button.names.LEFT },
        function(c)
          c:emit_signal("request::activate", "mouse_click", { raise = true })
          awful.mouse.client.move(c)
        end,
      },
      {
        { { modkey }, awful.button.names.RIGHT },
        function(c)
          c:emit_signal("request::activate", "mouse_click", { raise = true })
          awful.mouse.client.resize(c)
        end,
      },
    }, "button"))
  end)
  client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings(map_bindings({
      {
        { { modkey }, "f" },
        function(c)
          c.fullscreen = not c.fullscreen
          c:raise()
        end,
      },
      {
        { { modkey }, "q" },
        function(c)
          c:kill()
        end,
      },
      {
        { { modkey, "Ctrl" }, "space" },
        awful.client.floating.toggle,
      },
      {
        { { modkey }, "o" },
        function(c)
          c:move_to_screen()
        end,
      },
      {
        { { modkey }, "t" },
        function(c)
          c.ontop = not c.ontop
        end,
      },
      {
        { { modkey }, "n" },
        function(c)
          c.minimized = true
        end,
      },
      {
        { { modkey }, "m" },
        function(c)
          c.maximized = not c.maximized
          c:raise()
        end,
      },
      {
        { { modkey, "Ctrl" }, "m" },
        function(c)
          c.maximized_vertical = not c.maximized_vertical
          c:raise()
        end,
      },
    }, "key"))
  end)
end
setup_client_bindings()

local function setup_global_bindings()
  ---@param mappings Mapping[]
  local map_append = function(mappings)
    awful.keyboard.append_global_keybindings(map_bindings(mappings, "key"))
  end

  local core = {
    {
      { { modkey }, "Return" },
      wrap(awful.spawn.spawn, terminal_cmd),
    },
    {
      { { modkey, "Ctrl" }, "r" },
      awesome.restart,
    },
    {
      { { modkey, "Shift" }, "q" },
      awesome.quit,
    },
  }
  map_append(core)

  local client_navigation = {
    {
      { { modkey }, "j" },
      wrap(awful.client.focus.byidx, 1),
    },
    {
      { { modkey }, "k" },
      wrap(awful.client.focus.byidx, -1),
    },
    {
      { { modkey }, "u" },
      awful.client.urgent.jumpto,
    },
  }
  map_append(client_navigation)

  local tag_navigation = {
    {
      { { modkey }, "Escape" },
      awful.tag.history.restore,
    },
  }
  map_append(tag_navigation)

  local tag_navigation_numrow = {
    awful.key({
      modifiers = { modkey },
      keygroup = "numrow",
      on_press = function(index)
        local screen = awful.screen.focused()
        local tag = screen.tags[index]
        if tag then
          tag:view_only()
        end
      end,
    }),
    awful.key({
      modifiers = { modkey, "Ctrl" },
      keygroup = "numrow",
      on_press = function(index)
        local screen = awful.screen.focused()
        local tag = screen.tags[index]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end,
    }),
    awful.key({
      modifiers = { modkey, "Shift" },
      keygroup = "numrow",
      on_press = function(index)
        if client.focus then
          local tag = client.focus.screen.tags[index]
          if tag then
            client.focus:move_to_tag(tag)
          end
        end
      end,
    }),
    awful.key({
      modifiers = { modkey, "Ctrl", "Shift" },
      keygroup = "numrow",
      on_press = function(index)
        if client.focus then
          local tag = client.focus.screen.tags[index]
          if tag then
            client.focus:toggle_tag(tag)
          end
        end
      end,
    }),
  }
  awful.keyboard.append_global_keybindings(tag_navigation_numrow)

  local screen_navigation = {
    {
      { { modkey, "Ctrl" }, "j" },
      wrap(awful.screen.focus_relative, 1),
    },
    {
      { { modkey, "Ctrl" }, "k" },
      wrap(awful.screen.focus_relative, -1),
    },
  }
  map_append(screen_navigation)

  local layout_manipulation = {
    {
      { { modkey, "Shift" }, "j" },
      wrap(awful.client.swap.byidx, 1),
    },
    {
      { { modkey, "Shift" }, "k" },
      wrap(awful.client.swap.byidx, -1),
    },
    {
      { { modkey }, "l" },
      wrap(awful.tag.incmwfact, 0.01),
    },
    {
      { { modkey }, "h" },
      wrap(awful.tag.incmwfact, -0.01),
    },
    {
      { { modkey }, "[" },
      wrap(awful.client.incwfact, -0.02),
    },
    {
      { { modkey }, "]" },
      wrap(awful.client.incwfact, 0.02),
    },
    {
      { { modkey }, "space" },
      wrap(awful.layout.inc, 1),
    },
    {
      { { modkey, "Shift" }, "space" },
      wrap(awful.layout.inc, -1),
    },
    {
      { { modkey, "Ctrl" }, "n" },
      function()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
          c:emit_signal("request::activate", "key.unminimize", { raise = true })
        end
      end,
    },
  }
  map_append(layout_manipulation)

  local awesome_utils = {
    {
      { { modkey }, "p" },
      menubar.show,
    },
  }
  map_append(awesome_utils)

  local volume = {
    {
      { {}, "XF86AudioLowerVolume" },
      wrap(awful.spawn.easy_async, "wpctl set-volume -l 1.0 @DEFAULT_SINK@ 10%-", refresh_volume_widget),
    },
    {
      { {}, "XF86AudioRaiseVolume" },
      wrap(awful.spawn.easy_async, "wpctl set-volume -l 1.0 @DEFAULT_SINK@ 10%+", refresh_volume_widget),
    },
    {
      { {}, "XF86AudioMute" },
      wrap(awful.spawn.easy_async, "wpctl set-mute @DEFAULT_SINK@ toggle", refresh_volume_widget),
    },
  }
  map_append(volume)

  local brightness = {
    {
      { {}, "XF86MonBrightnessDown" },
      wrap(awful.spawn.easy_async, "xbacklight -dec 10", refresh_brightness_widget),
    },
    {
      { {}, "XF86MonBrightnessUp" },
      wrap(awful.spawn.easy_async, "xbacklight -inc 10", refresh_brightness_widget),
    },
  }
  map_append(brightness)

  local utils = {
    {
      { { modkey }, "b" },
      wrap(awful.spawn.spawn, browser_cmd),
    },
    {
      { { modkey, "Ctrl" }, "l" },
      wrap(awful.spawn.spawn, lock_screen_cmd),
    },
  }
  map_append(utils)

  ---@param scrot_type "selection"|"window"|"all"|"ocr"
  local scrot_new = function(scrot_type)
    if scrot_type ~= "ocr" then
      local flag = ""
      if scrot_type == "selection" then
        flag = "-s"
      end
      if scrot_type == "window" then
        flag = "-u"
      end

      local dir = (os.getenv("XDG_PICTURES_DIR") or os.getenv("HOME") .. "/Pictures") .. "/scrot"
      gears.filesystem.make_directories(dir)
      local path = dir .. "/" .. os.date("%Y-%m-%d_%H-%M-%S") .. "_scrot.png"

      awful.spawn.easy_async(
        -- Avoid file descriptor inheritance by redirecting stdout and stderr
        string.format("scrot -e 'xclip -sel c -t image/png < $f >/dev/null 2>&1' --line mode=edge %q %s", path, flag),
        function()
          naughty
            .notification({
              message = "",
              icon = path,
              icon_size = 300,
            })
            :connect_signal("destroyed", function(_, reason)
              if reason == 2 then
                awful.spawn.spawn(string.format("xdg-open %q", path))
              end
            end)
        end
      )
    else
      local path = "/tmp/scrot_ocr_" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".png"

      awful.spawn.easy_async(
        -- Avoid file descriptor inheritance by redirecting stdout and stderr
        string.format(
          "scrot -e 'tesseract $f stdout 2>/dev/null | xclip -sel c >/dev/null 2>&1' --line mode=edge %q -s",
          path
        ),
        function()
          naughty.notification({ message = "OCR performed, text copied" })
        end
      )
    end
  end

  local screenshots = {
    {
      { { modkey }, "F1" },
      wrap(scrot_new, "selection"),
    },
    {
      { { modkey }, "F2" },
      wrap(scrot_new, "window"),
    },
    {
      { { modkey }, "F3" },
      wrap(scrot_new, "all"),
    },
    {
      { { modkey }, "F4" },
      wrap(scrot_new, "ocr"),
    },
  }
  map_append(screenshots)
end
setup_global_bindings()

awful.spawn.spawn(compositor_cmd)
