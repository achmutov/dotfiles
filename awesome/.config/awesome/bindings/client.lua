local awful = require("awful")
local gears = require("gears")

return {
    keys = gears.table.join(
        awful.key({ modkey,           },    "f",        function (c) c.fullscreen = not c.fullscreen; c:raise() end),
        awful.key({ modkey,           },    "q",        function (c) c:kill()                         end),
        awful.key({ modkey, "Control" },    "space",    awful.client.floating.toggle                     ),
        awful.key({ modkey, "Control" },    "Return",   function (c) c:swap(awful.client.getmaster()) end),
        awful.key({ modkey,           },    "o",        function (c) c:move_to_screen()               end),
        awful.key({ modkey,           },    "t",        function (c) c.ontop = not c.ontop            end),
        awful.key({ modkey,           },    "n",        function (c) c.minimized = true                 end),
        awful.key({ modkey,           },    "m",        function (c) c.maximized = not c.maximized; c:raise() end),
        awful.key({ modkey, "Control" },    "m",        function (c) c.maximized_vertical = not c.maximized_vertical; c:raise() end),
        awful.key({ modkey, "Shift"   },    "m",        function (c) c.maximized_horizontal = not c.maximized_horizontal; c:raise() end)
    ),
    buttons = gears.table.join(
        awful.button({          }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true})                                end),
        awful.button({ modkey   }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}) awful.mouse.client.move(c)     end),
        awful.button({ modkey   }, 3, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}) awful.mouse.client.resize(c)   end)
    )
}
