---@diagnostic disable: undefined-global
local gears = require("gears")
local wibox = require("wibox")
require("awful.autofocus")

local batteryarc_widget = require("awesome-wm-widgets.batteryarc-widget.batteryarc")
local brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")
local volume_widget = require('awesome-wm-widgets.pactl-widget.volume')

local util = require("util")
local client_bindings = require("bindings.client")

local constants = require("constants")
local beautiful = require("beautiful")
beautiful.init(constants.themes_path .. constants.theme .. "/theme.lua")
local rounded_rect_shape = function(cr, width, height)
    ---@diagnostic disable-next-line undefined-global
    gears.shape.rounded_rect(cr, width, height, 10)
end
beautiful.notification_font = "JetBrainsMono Nerd Font"
beautiful.notification_shape = rounded_rect_shape
beautiful.notification_border_color = "#04b56b"
beautiful.notification_border_width = 4



local awful = require("awful")
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.fair,
    awful.layout.suit.max.fullscreen,
}

local menubar = require("menubar")
menubar.utils.terminal = terminal


local taglist_buttons = gears.table.join(
    awful.button({          }, 1, function(t) t:view_only() end),
    awful.button({ modkey   }, 1,
        function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
    awful.button({          }, 3, awful.tag.viewtoggle),
    awful.button({ modkey   }, 3,
        function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1,
        function (c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                "request::activate",
                "tasklist",
                {raise = true}
                )
            end
        end),
    awful.button({ }, 3, function() awful.menu.client_list({ theme = { width = 250 } })    end),
    awful.button({ }, 4, function() awful.client.focus.byidx(1)                            end),
    awful.button({ }, 5, function() awful.client.focus.byidx(-1)                           end)
)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    util.set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- CHANGE: LAUNCHER NOT NEEDED
            -- mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,

            -- CUSTOM WIDGETS
            volume_widget{widget_type='arc'},
            brightness_widget{program='xbacklight', timeout=1},
            batteryarc_widget(),

            awful.widget.keyboardlayout(),
            wibox.widget.systray(),
            wibox.widget.textclock(),
            s.mylayoutbox,
        },
    }
end)

awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = client_bindings.keys,
                     buttons = client_bindings.buttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }  -- CUSTOM CHANGE: TITLEBARS DISABLED
    },
}
