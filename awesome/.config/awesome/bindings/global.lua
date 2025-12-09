---@diagnostic disable: undefined-global
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")

local globalkeys = gears.table.join(
    -- Volume
    awful.key({ }, "XF86AudioLowerVolume",  function() awful.spawn.with_shell("pactl -- set-sink-volume @DEFAULT_SINK@ -10%")   end),
    awful.key({ }, "XF86AudioRaiseVolume",  function() awful.spawn.with_shell("pactl -- set-sink-volume @DEFAULT_SINK@ +10%")   end),
    awful.key({ }, "XF86AudioMute",         function() awful.spawn.with_shell("pactl set-sink-mute @DEFAULT_SINK@ toggle")      end),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessDown", function() awful.util.spawn("xbacklight -dec 10")   end),
    awful.key({ }, "XF86MonBrightnessUp",   function() awful.util.spawn("xbacklight -inc 10")   end),

    -- screenshots
    awful.key({         },  "Print", scrot_full),
    awful.key({ modkey, },  "Print", scrot_selection),
    awful.key({ "Shift" },  "Print", scrot_window),
    awful.key({ "Ctrl"  },  "Print", scrot_delay),

    -- Lock screen
    awful.key({ modkey, "Ctrl" }, "l", function() awful.util.spawn("xsecurelock") end),


    -- Navigation (large scale)
    awful.key({ modkey }, "Left",   awful.tag.viewprev),
    awful.key({ modkey }, "Right",  awful.tag.viewnext),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),

    -- Navigation (small scale)
    awful.key({ modkey }, "j", function() awful.client.focus.byidx( 1) end),
    awful.key({ modkey }, "k", function() awful.client.focus.byidx(-1) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function() awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function() awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return",  function() awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",       awesome.restart),
    awful.key({ modkey, "Shift"   }, "q",       awesome.quit),

    awful.key({ modkey,           }, "l",     function() awful.tag.incmwfact( 0.01)          end),
    awful.key({ modkey,           }, "h",     function() awful.tag.incmwfact(-0.01)          end),
    awful.key({ modkey,           }, "[",     function() awful.client.incwfact(-0.02)        end),
    awful.key({ modkey,           }, "]",     function() awful.client.incwfact( 0.02)        end),
    awful.key({ modkey, "Shift"   }, "h",     function() awful.tag.incnmaster( 1, nil, true) end),
    awful.key({ modkey, "Shift"   }, "l",     function() awful.tag.incnmaster(-1, nil, true) end),
    awful.key({ modkey, "Control" }, "h",     function() awful.tag.incncol( 1, nil, true)    end),
    awful.key({ modkey, "Control" }, "l",     function() awful.tag.incncol(-1, nil, true)    end),
    awful.key({ modkey,           }, "space", function() awful.layout.inc( 1)                end),
    awful.key({ modkey, "Shift"   }, "space", function() awful.layout.inc(-1)                end),

    awful.key({ modkey, "Control" }, "n",
        function ()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                "request::activate", "key.unminimize", {raise = true}
                )
            end
        end),

    awful.key({ modkey }, "p", function() menubar.show() end),
    awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end),
    awful.key({ modkey }, "x",
        function ()
            awful.prompt.run {
                prompt       = "Run Lua code: ",
                textbox      = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end)
)

local function screen_tag(func, i)
    return function ()
        local screen = awful.screen.focused()
        local tag = screen.tags[i]
        if tag then
            func(tag)
        end
    end
end

local function client_tag(func, i)
    return function ()
        if client.focus then
            local tag = client.focus.screen.tags[i]
            if tag then
                func(tag)
            end
        end
    end
end

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey },                       "#" .. i + 9, screen_tag(awful.tag.viewonly, i)),
        awful.key({ modkey, "Control" },            "#" .. i + 9, screen_tag(awful.tag.viewtoggle, i)),
        awful.key({ modkey, "Shift" },              "#" .. i + 9, client_tag(function(tag) client.focus:move_to_tag(tag) end, i)),
        awful.key({ modkey, "Control", "Shift" },   "#" .. i + 9, client_tag(function(tag) client.focus:toggle_tag(tag) end, i))
    )
end

local mymainmenu = awful.menu({
    items = {
        { "restart",    awesome.restart },
        { "quit",       awesome.quit    },
    }
})
local globalbuttons = awful.button({ }, 3, function() mymainmenu:toggle() end)

root.keys(globalkeys)
root.buttons(globalbuttons)
