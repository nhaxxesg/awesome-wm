local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")

require("awful.hotkeys_popup.keys")

return function(config)
    local modkey = config.modkey or "Mod4"
    local terminal = config.terminal or "x-terminal-emulator"
    local launcher = config.launcher or "rofi -show drun"
    local editor_cmd = config.editor_cmd or terminal

    local taglist_buttons = gears.table.join(
        awful.button({}, 1, function(t)
            t:view_only()
        end),
        awful.button({ modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
        awful.button({}, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({}, 4, function(t)
            awful.tag.viewnext(t.screen)
        end),
        awful.button({}, 5, function(t)
            awful.tag.viewprev(t.screen)
        end)
    )

    local tasklist_buttons = gears.table.join(
        awful.button({}, 1, function(c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal("request::activate", "tasklist", { raise = true })
            end
        end),
        awful.button({}, 3, function()
            awful.menu.client_list({ theme = { width = 320 } })
        end),
        awful.button({}, 4, function()
            awful.client.focus.byidx(1)
        end),
        awful.button({}, 5, function()
            awful.client.focus.byidx(-1)
        end)
    )

    local globalkeys = gears.table.join(
        awful.key(
            { modkey },
            "Return",
            function()
                awful.spawn(terminal)
            end,
            { description = "open terminal", group = "launcher" }
        ),
        awful.key(
            { modkey },
            "d",
            function()
                awful.spawn(launcher)
            end,
            { description = "open app launcher", group = "launcher" }
        ),
        awful.key(
            { modkey },
            "s",
            function()
                hotkeys_popup.show_help(nil, awful.screen.focused())
            end,
            { description = "show help", group = "awesome" }
        ),
        awful.key(
            { modkey, "Control" },
            "r",
            awesome.restart,
            { description = "reload awesome", group = "awesome" }
        ),
        awful.key(
            { modkey, "Shift" },
            "e",
            function()
                awesome.quit()
            end,
            { description = "quit awesome", group = "awesome" }
        ),
        awful.key(
            { modkey },
            "space",
            function()
                awful.layout.inc(1)
            end,
            { description = "next layout", group = "layout" }
        ),
        awful.key(
            { modkey, "Shift" },
            "space",
            function()
                awful.layout.inc(-1)
            end,
            { description = "previous layout", group = "layout" }
        ),
        awful.key(
            { modkey },
            "Tab",
            function()
                awful.client.focus.history.previous()
                if client.focus then
                    client.focus:raise()
                end
            end,
            { description = "focus previous client", group = "client" }
        ),
        awful.key(
            { modkey },
            "h",
            function()
                awful.client.focus.bydirection("left")
            end,
            { description = "focus left", group = "client" }
        ),
        awful.key(
            { modkey },
            "j",
            function()
                awful.client.focus.bydirection("down")
            end,
            { description = "focus down", group = "client" }
        ),
        awful.key(
            { modkey },
            "k",
            function()
                awful.client.focus.bydirection("up")
            end,
            { description = "focus up", group = "client" }
        ),
        awful.key(
            { modkey },
            "l",
            function()
                awful.client.focus.bydirection("right")
            end,
            { description = "focus right", group = "client" }
        ),
        awful.key(
            { modkey, "Shift" },
            "h",
            function()
                awful.client.swap.bydirection("left")
            end,
            { description = "swap left", group = "client" }
        ),
        awful.key(
            { modkey, "Shift" },
            "j",
            function()
                awful.client.swap.bydirection("down")
            end,
            { description = "swap down", group = "client" }
        ),
        awful.key(
            { modkey, "Shift" },
            "k",
            function()
                awful.client.swap.bydirection("up")
            end,
            { description = "swap up", group = "client" }
        ),
        awful.key(
            { modkey, "Shift" },
            "l",
            function()
                awful.client.swap.bydirection("right")
            end,
            { description = "swap right", group = "client" }
        ),
        awful.key(
            { modkey, "Control" },
            "h",
            function()
                awful.tag.incmwfact(-0.03)
            end,
            { description = "shrink master area", group = "layout" }
        ),
        awful.key(
            { modkey, "Control" },
            "l",
            function()
                awful.tag.incmwfact(0.03)
            end,
            { description = "grow master area", group = "layout" }
        ),
        awful.key(
            { modkey, "Control" },
            "j",
            function()
                awful.client.incwfact(-0.05)
            end,
            { description = "shrink focused client factor", group = "layout" }
        ),
        awful.key(
            { modkey, "Control" },
            "k",
            function()
                awful.client.incwfact(0.05)
            end,
            { description = "grow focused client factor", group = "layout" }
        ),
        awful.key(
            { modkey },
            "f",
            function()
                if client.focus then
                    client.focus.fullscreen = not client.focus.fullscreen
                    client.focus:raise()
                end
            end,
            { description = "toggle fullscreen", group = "client" }
        ),
        awful.key(
            { modkey, "Shift" },
            "q",
            function()
                if client.focus then
                    client.focus:kill()
                end
            end,
            { description = "close focused client", group = "client" }
        ),
        awful.key(
            {},
            "Print",
            function()
                awful.spawn.with_shell(
                    "if command -v flameshot >/dev/null 2>&1; then " ..
                    "flameshot gui; " ..
                    "elif command -v maim >/dev/null 2>&1; then " ..
                    "maim -s | xclip -selection clipboard -t image/png; " ..
                    "fi"
                )
            end,
            { description = "take screenshot", group = "launcher" }
        ),
        awful.key(
            { modkey },
            "p",
            function()
                awful.spawn(editor_cmd .. " " .. awesome.conffile)
            end,
            { description = "edit config", group = "awesome" }
        )
    )

    for i = 1, 9 do
        globalkeys = gears.table.join(
            globalkeys,
            awful.key(
                { modkey },
                "#" .. i + 9,
                function()
                    local screen = awful.screen.focused()
                    local tag = screen.tags[i]
                    if tag then
                        tag:view_only()
                    end
                end,
                { description = "view tag " .. i, group = "tag" }
            ),
            awful.key(
                { modkey, "Shift" },
                "#" .. i + 9,
                function()
                    if client.focus then
                        local tag = client.focus.screen.tags[i]
                        if tag then
                            client.focus:move_to_tag(tag)
                            tag:view_only()
                        end
                    end
                end,
                { description = "move client to tag " .. i, group = "tag" }
            )
        )
    end

    local clientkeys = gears.table.join()

    local clientbuttons = gears.table.join(
        awful.button({}, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
        end),
        awful.button({ modkey }, 1, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ modkey }, 3, function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    return {
        globalkeys = globalkeys,
        clientkeys = clientkeys,
        clientbuttons = clientbuttons,
        taglist_buttons = taglist_buttons,
        tasklist_buttons = tasklist_buttons,
    }
end
