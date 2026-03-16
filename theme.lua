local awful = require("awful")
local gears = require("gears")
local gfs = require("gears.filesystem")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")

local dpi = xresources.apply_dpi

local config_dir = gfs.get_configuration_dir()
local themes_path = gfs.get_themes_dir()

local theme = {}

theme.font = "JetBrains Mono 10"
theme.icon_theme = "Papirus-Dark"

theme.bg_normal = "#1a1b26"
theme.bg_focus = "#24283b"
theme.bg_urgent = "#f7768e"
theme.bg_minimize = "#1f2335"
theme.bg_systray = theme.bg_focus

theme.fg_normal = "#c0caf5"
theme.fg_focus = "#ffffff"
theme.fg_urgent = "#1a1b26"
theme.fg_minimize = "#7a839f"

theme.blue = "#7aa2f7"
theme.cyan = "#7dcfff"
theme.green = "#9ece6a"
theme.red = "#f7768e"
theme.panel = "#24283b"
theme.panel_alt = "#1f2335"

theme.useless_gap = dpi(8)
theme.border_width = dpi(2)
theme.border_normal = "#2f3549"
theme.border_focus = theme.blue
theme.border_marked = theme.red
theme.border_radius = dpi(10)
theme.wibar_height = dpi(30)

theme.menu_height = dpi(24)
theme.menu_width = dpi(180)
theme.notification_bg = theme.panel
theme.notification_fg = theme.fg_normal
theme.notification_border_width = dpi(1)
theme.notification_border_color = theme.blue
theme.notification_shape = function(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, theme.border_radius)
end

theme.taglist_bg_focus = theme.blue
theme.taglist_fg_focus = theme.bg_normal
theme.taglist_bg_occupied = theme.panel
theme.taglist_fg_occupied = theme.fg_normal
theme.taglist_bg_empty = theme.panel_alt
theme.taglist_fg_empty = "#7a839f"
theme.tasklist_bg_focus = theme.panel
theme.tasklist_fg_focus = theme.fg_normal
theme.tasklist_bg_normal = theme.panel_alt
theme.tasklist_fg_normal = theme.fg_normal

theme.layout_tile = themes_path .. "default/layouts/tilew.png"
theme.layout_tileleft = themes_path .. "default/layouts/tileleftw.png"
theme.layout_fairv = themes_path .. "default/layouts/fairvw.png"
theme.layout_max = themes_path .. "default/layouts/maxw.png"
theme.wallpaper = config_dir .. "wallpaper.svg"

local function rounded(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, theme.border_radius)
end

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function make_textbox()
    return wibox.widget({
        font = theme.font,
        valign = "center",
        widget = wibox.widget.textbox,
    })
end

local function make_pill(widget, fg, bg)
    return wibox.widget({
        {
            widget,
            left = dpi(10),
            right = dpi(10),
            top = dpi(4),
            bottom = dpi(4),
            widget = wibox.container.margin,
        },
        fg = fg or theme.fg_normal,
        bg = bg or theme.panel_alt,
        shape = rounded,
        widget = wibox.container.background,
    })
end

local function make_network_widget()
    local textbox = make_textbox()

    awful.widget.watch(
        {
            "sh",
            "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION device status | " ..
            "awk -F: '$2 == \"connected\" { print $1 \":\" $3; found = 1; exit } " ..
            "END { if (!found) print \"offline\" }'",
        },
        15,
        function(widget, stdout)
            local value = trim(stdout)
            if value == "" or value == "offline" then
                widget:set_text("NET offline")
                return
            end

            local kind, name = value:match("([^:]+):(.*)")
            if kind == "wifi" then
                widget:set_text("NET " .. (name ~= "" and name or "wifi"))
            elseif kind == "ethernet" then
                widget:set_text("NET wired")
            else
                widget:set_text("NET " .. value:gsub(":", " "))
            end
        end,
        textbox
    )

    return make_pill(textbox, theme.cyan, theme.panel_alt)
end

local function make_volume_widget()
    local textbox = make_textbox()

    awful.widget.watch(
        {
            "sh",
            "-c",
            "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || " ..
            "amixer get Master 2>/dev/null | tail -n 1",
        },
        5,
        function(widget, stdout)
            local raw = trim(stdout)
            local wpctl_volume = raw:match("Volume:%s+(%d+%.?%d*)")

            if wpctl_volume then
                local pct = math.floor((tonumber(wpctl_volume) * 100) + 0.5)
                local muted = raw:match("%[MUTED%]") ~= nil
                if muted then
                    widget:set_text("VOL mute")
                else
                    widget:set_text(string.format("VOL %d%%", pct))
                end
                return
            end

            local amixer_pct = raw:match("%[(%d+)%%%]")
            local amixer_muted = raw:match("%[off%]") ~= nil
            if amixer_pct then
                if amixer_muted then
                    widget:set_text("VOL mute")
                else
                    widget:set_text("VOL " .. amixer_pct .. "%")
                end
            else
                widget:set_text("VOL ?")
            end
        end,
        textbox
    )

    return make_pill(textbox, theme.blue, theme.panel_alt)
end

local function make_battery_widget()
    local textbox = make_textbox()

    awful.widget.watch(
        {
            "sh",
            "-c",
            "if [ -d /sys/class/power_supply/BAT0 ]; then " ..
            "printf \"%s %s\" \"$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)\" " ..
            "\"$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)\"; " ..
            "fi",
        },
        30,
        function(widget, stdout)
            local pct, status = trim(stdout):match("(%d+)%s+(%a+)")
            if not pct then
                widget:set_text("")
                return
            end

            local suffix = ""
            if status == "Charging" then
                suffix = "+"
            elseif status == "Full" then
                suffix = "="
            end

            widget:set_text(string.format("BAT %s%%%s", pct, suffix))
        end,
        textbox
    )

    return make_pill(textbox, theme.green, theme.panel_alt)
end

local function make_clock_widget()
    local clock = wibox.widget({
        format = "%a %d %b  %H:%M",
        font = theme.font,
        widget = wibox.widget.textclock,
    })

    return make_pill(clock, theme.fg_normal, theme.panel_alt)
end

local function make_systray_widget()
    local systray = wibox.widget.systray()
    systray:set_base_size(dpi(18))

    return make_pill(systray, theme.fg_normal, theme.panel_alt)
end

function theme.set_wallpaper(s)
    if theme.wallpaper then
        gears.wallpaper.maximized(theme.wallpaper, s, true)
    end
end

function theme.setup_screen(s, taglist_buttons, tasklist_buttons)
    theme.set_wallpaper(s)

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
        end)
    ))

    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        layout = {
            spacing = dpi(8),
            layout = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    id = "text_role",
                    widget = wibox.widget.textbox,
                },
                left = dpi(12),
                right = dpi(12),
                top = dpi(4),
                bottom = dpi(4),
                widget = wibox.container.margin,
            },
            id = "background_role",
            shape = rounded,
            widget = wibox.container.background,
        },
    })

    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        layout = {
            spacing = dpi(8),
            layout = wibox.layout.flex.horizontal,
        },
        widget_template = {
            {
                {
                    {
                        id = "icon_role",
                        resize = true,
                        widget = wibox.widget.imagebox,
                    },
                    left = dpi(10),
                    right = dpi(6),
                    widget = wibox.container.margin,
                },
                {
                    id = "text_role",
                    widget = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            id = "background_role",
            shape = rounded,
            widget = wibox.container.background,
        },
    })

    local left_layout = wibox.layout.fixed.horizontal()
    left_layout.spacing = dpi(8)
    left_layout:add(s.mytaglist)

    local right_layout = wibox.layout.fixed.horizontal()
    right_layout.spacing = dpi(8)
    right_layout:add(make_network_widget())
    right_layout:add(make_volume_widget())
    right_layout:add(make_battery_widget())

    if s == awful.screen.preferred() then
        right_layout:add(make_systray_widget())
    end

    right_layout:add(make_pill(s.mylayoutbox, theme.blue, theme.panel_alt))
    right_layout:add(make_clock_widget())

    s.mywibar = awful.wibar({
        position = "top",
        screen = s,
        height = theme.wibar_height,
        bg = theme.bg_normal,
        fg = theme.fg_normal,
    })

    s.mywibar:setup({
        {
            left_layout,
            left = dpi(10),
            right = dpi(10),
            top = dpi(6),
            bottom = dpi(6),
            widget = wibox.container.margin,
        },
        {
            s.mytasklist,
            left = dpi(12),
            right = dpi(12),
            top = dpi(6),
            bottom = dpi(6),
            widget = wibox.container.margin,
        },
        {
            right_layout,
            left = dpi(10),
            right = dpi(10),
            top = dpi(6),
            bottom = dpi(6),
            widget = wibox.container.margin,
        },
        layout = wibox.layout.align.horizontal,
    })
end

return theme
