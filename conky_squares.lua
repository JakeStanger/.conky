require "cairo"
require "imlib2"

COLOR_PRIMARY_R = 0.773
COLOR_PRIMARY_G = 0.784
COLOR_PRIMARY_B = 0.776

COLOR_SECONDARY_R = 0.177
COLOR_SECONDARY_G = 0.169
COLOR_SECONDARY_B = 0.200

COLOR_TERTIARY_R = 0.604
COLOR_TERTIARY_G = 0.584
COLOR_TERTIARY_B = 0.682

FONT_REGULAR = "Josefin Slab"
FONT_MONOSPACE = "Source Code Pro"

function round(x, n)
    n = math.pow(10, n or 0)
    x = x * n
    if x >= 0 then
        x = math.floor(x + 0.5)
    else
        x = math.ceil(x - 0.5)
    end
    return x / n
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function image(im)
    local x
    x = (im.x or 0)
    local y
    y = (im.y or 0)
    local w
    w = (im.w or 0)
    local h
    h = (im.h or 0)
    local file
    file = tostring(im.file)
    if file == nil then
        print("set image file")
    end

    local show = imlib_load_image(file)
    if show == nil then
        return
    end

    imlib_context_set_image(show)

    if tonumber(w) == 0 then
        width = imlib_image_get_width()
    else
        width = tonumber(w)
    end
    if tonumber(h) == 0 then
        height = imlib_image_get_height()
    else
        height = tonumber(h)
    end

    imlib_context_set_image(show)
    local scaled =
        imlib_create_cropped_scaled_image(0, 0, imlib_image_get_width(), imlib_image_get_height(), width, height)
    imlib_free_image()
    imlib_context_set_image(scaled)
    imlib_render_image_on_drawable(x, y)
    imlib_free_image()
    show = nil
end

function init_cairo()
    if conky_window == nil then
        return false
    end

    local cs =
        cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )

    cr = cairo_create(cs)

    cairo_select_font_face(cr, FONT_REGULAR, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    return true
end

function conky_main()
    if (not init_cairo()) then
        return
    end

    local cx, cy = 1860, 200
    local height = 22
    local width = 90
    local gap = 20

    local radius = 15
    local start_angle = -math.pi / 2

    -- CPU GRAPHS
    local num_cpus = 8
    for i = 1, num_cpus / 2, 1 do
        for j = 1, num_cpus / 4, 1 do
            local cpu = 0.05 + tonumber(conky_parse("${cpu cpu" .. i * j .. "}") / 100.0) * 0.95

            cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
            cairo_arc(cr, cx + ((j - 1) * (height + gap)), cy + (i - 1) * (height + gap), radius, 0, 2 * math.pi)
            cairo_stroke(cr)
            cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
            cairo_arc(
                cr,
                cx + ((j - 1) * (height + gap)),
                cy + (i - 1) * (height + gap),
                radius,
                start_angle,
                start_angle + 2 * math.pi * (cpu)
            )
            cairo_stroke(cr)

            cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
            local label = round(cpu, 2) * 100 .. "%"

            local extents = cairo_text_extents_t:create()
            tolua.takeownership(extents)
            cairo_text_extents(cr, label, extents)

            cairo_move_to(cr, cx - extents.width / 2 + ((j - 1) * (height + gap)), cy + (i - 1) * (height + gap) + 5)
            cairo_show_text(cr, label)
            cairo_stroke(cr)
        end
    end

    -- MEMORY
    cx = 1920 - 35
    cy = 390

    -- local memmax = tonumber(conky_parse("$memmax"):sub(1, -4))

    -- print(conky_parse("$memperc"))
    -- local mem = memmax - tonumber(conky_parse("$memeasyfree"):sub(1, -4))
    -- local memperc = mem / memmax

    -- print(memperc)
    local memperc = tonumber(conky_parse("${exec free | grep Mem | awk '{print $3/$2}'}"))
    -- local _ = mem .. " GiB"

    cairo_set_line_width(cr, 10)

    local label = "Memory " .. round(memperc * 100, 0) .. "%"
    radius = 25

    cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
    cairo_arc(cr, cx, cy, radius, 0, 2 * math.pi)
    cairo_stroke(cr)
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_arc(cr, cx, cy, radius, start_angle, start_angle + 2 * math.pi * memperc)
    cairo_stroke(cr)

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    local extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_text_extents(cr, label, extents)

    cairo_move_to(cr, cx - extents.width / 2, cy + radius + 17)
    cairo_show_text(cr, label)
    cairo_stroke(cr)

    -- cairo_move_to(cr, cx + width, cy - 35)
    -- cairo_rel_line_to(cr, 0, -height)
    -- cairo_rel_line_to(cr, -width * memperc, 0)
    -- cairo_rel_line_to(cr, 0, height)
    -- cairo_fill(cr)

    -- cairo_move_to(cr, cx + width + 5, cy - 42)
    -- cairo_show_text(cr, round(memperc * 100, 0) .. "%")

    -- cairo_destroy(cr)
    -- cairo_surface_destroy(cs)

    -- cr = nil
end

-- FILE SYSTEM
function conky_fs_main()
    if (not init_cairo()) then
        return
    end

    -- FILE SYSTEM
    local cx, cy = 1920 - 35, 480
    local height = 11
    local width = 195

    local radius = 25
    local gap = 2 * radius + 25

    local start_angle = -math.pi / 2

    local mounts = {}
    mounts[1] = {"Root", "/"}
    mounts[2] = {"Hard Drive", "/home/jake/HDD"}
    mounts[3] = {"Media", "/home/jake/Media"}

    cairo_set_line_width(cr, 10)

    for i = 1, tablelength(mounts), 1 do
        local drive_perc = tonumber(conky_parse("${fs_used_perc " .. mounts[i][2] .. "}"))

        cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
        -- cairo_move_to(cr, cx, cy + (i - 1) * (height + gap))
        cairo_arc(cr, cx, cy + (i - 1) * (height + gap), radius, 0, 2 * math.pi)
        cairo_stroke(cr)
        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
        cairo_arc(
            cr,
            cx,
            cy + (i - 1) * (height + gap),
            radius,
            start_angle,
            start_angle + 2 * math.pi * (drive_perc / 100)
        )
        cairo_stroke(cr)
        -- cairo_rel_line_to(cr, 0, height)
        -- cairo_rel_line_to(cr, -width * drive_perc / 100, 0)
        -- cairo_rel_line_to(cr, 0, -height)
        -- cairo_fill(cr)

        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
        local label = mounts[i][1] .. ": " .. drive_perc .. "%"

        local extents = cairo_text_extents_t:create()
        tolua.takeownership(extents)
        cairo_text_extents(cr, label, extents)

        cairo_move_to(cr, cx - extents.width / 2, cy + (i - 1) * (height + gap) + radius + 17)
        cairo_show_text(cr, label)
        cairo_stroke(cr)
    end

    local pattern = "%'"
    local replace = ""

    -- ALBUM INFO
    local artist_title = string.gsub(conky_parse("$mpd_artist"), pattern, replace)
    local album_title = string.gsub(conky_parse("$mpd_album"), pattern, replace)

    if artist_title and album_title then
        conky_parse(
            "${exec python3 /home/jake/.config/conky/album_art.py '" .. artist_title .. "' '" .. album_title .. "'}"
        )
    end

    local is_paused = conky_parse("$mpd_status") == "Paused"

    --cairo_select_font_face(cr, font2, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    cx, cy = 1550, 30

    cairo_set_font_size(cr, 15)
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_move_to(cr, cx, cy)
    local song_title = conky_parse("$mpd_title")
    if is_paused then
        song_title = song_title .. " (Paused)"
    end
    cairo_show_text(cr, song_title)
    cairo_stroke(cr)

    cairo_move_to(cr, cx, cy + 20)
    cairo_show_text(cr, album_title)
    cairo_stroke(cr)

    cairo_move_to(cr, cx, cy + 40)
    cairo_show_text(cr, artist_title)
    cairo_stroke(cr)

    -- PROGRESS BAR
    local bar_height = cy + 80
    cairo_move_to(cr, cx, bar_height)
    cairo_set_line_width(cr, 3)

    local LENGTH = 370

    local duration_raw = split(conky_parse("$mpd_length"), ":", 2)
    if duration_raw[1] and duration_raw[2] then
        local duration = tonumber(duration_raw[1]) * 60 + tonumber(duration_raw[2])

        if duration ~= 0 then
            local elapsed_raw = split(conky_parse("$mpd_elapsed"), ":", 2)
            local elapsed = tonumber(elapsed_raw[1]) * 60 + tonumber(elapsed_raw[2])

            cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
            cairo_line_to(cr, cx + LENGTH, bar_height)
            cairo_stroke(cr)

            cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
            cairo_move_to(cr, cx, bar_height)
            cairo_move_to(cr, cx, bar_height)

            cairo_line_to(cr, cx + (elapsed / duration) * LENGTH, bar_height)
            cairo_stroke(cr)

            cairo_arc(cr, cx + (elapsed / duration) * LENGTH, bar_height, 5, 0, 2 * math.pi)
            cairo_fill(cr)
            cairo_stroke(cr)
        end
    end

    -- Next song
    local next_song = conky_parse("${exec mpc playlist | head -n 2 | tail -n 1}")

    local extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_text_extents(cr, next_song, extents)

    cairo_set_source_rgba(cr, COLOR_TERTIARY_R, COLOR_TERTIARY_G, COLOR_TERTIARY_B, 1)
    cairo_move_to(cr, 1920 - extents.width - 5, cy + 110)
    cairo_show_text(cr, next_song)
    cairo_stroke(cr)

    -- Playlist duration
    local playlist_duration = conky_parse("${exec /home/jake/.config/conky/mpd/playlist_duration.sh}")

    extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_text_extents(cr, playlist_duration, extents)

    cairo_set_source_rgba(cr, COLOR_TERTIARY_R, COLOR_TERTIARY_G, COLOR_TERTIARY_B, 1)
    cairo_move_to(cr, 1920 - extents.width - 5, cy + 130)
    cairo_show_text(cr, playlist_duration)
    cairo_stroke(cr)

    --  ALBUM COVER
    if artist_title and album_title then
        image(
            {
                x = 1390,
                y = cy - 20,
                h = 150,
                w = 150,
                file = "/home/jake/.cache/conky/data/thumbs/" .. artist_title .. " - " .. album_title
            }
        )
    end

    

    -- LYRICS
    local lyrics = split(conky_parse("${exec /home/jake/.config/conky/mpd/lyrics.sh}"), "\n")
    
    cx, cy = 20, 160
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_move_to(cr, cx, cy)

    for i in next, lyrics do
        if(lyrics[i]:match(("%[(.+)%]"))) then cairo_set_source_rgba(cr, COLOR_TERTIARY_R, COLOR_TERTIARY_G, COLOR_TERTIARY_B, 1)
        else cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1) end
        cairo_move_to(cr, cx, cy + i*21)
        cairo_show_text(cr, lyrics[i])
    end
    

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr = nil
end

function conky_clock()
    if (not init_cairo()) then
        return
    end

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    -- CLOCK
    local date_table = os.date("*t")

    local hours = date_table["hour"]
    local minutes = date_table["min"]
    local seconds = date_table["sec"]

    local DAYS = {
        [1] = "Sunday",
        [2] = "Monday",
        [3] = "Tuesday",
        [4] = "Wednesday",
        [5] = "Thursday",
        [6] = "Friday",
        [7] = "Saturday"
    }

    local MONTHS = {
        [1] = "January",
        [2] = "February",
        [3] = "March",
        [4] = "April",
        [5] = "May",
        [6] = "June",
        [7] = "July",
        [8] = "August",
        [9] = "September",
        [10] = "October",
        [11] = "November",
        [12] = "December"
    }

    local day = DAYS[date_table["wday"]]
    local month = MONTHS[date_table["month"]]
    local mday = tostring(date_table["day"])
    if string.len(mday) == 1 then
        mday = "0" .. mday
    end

    local hours_str = tostring(hours)
    if string.len(hours_str) == 1 then
        hours_str = "0" .. hours_str
    end

    local minutes_str = tostring(minutes)
    if string.len(minutes_str) == 1 then
        minutes_str = "0" .. minutes_str
    end

    local seconds_str = tostring(seconds)
    if string.len(seconds_str) == 1 then
        seconds_str = "0" .. seconds_str
    end

    local time_main = hours_str .. ":" .. minutes_str

    local font_size = 120
    local font_size_med = 50
    local font_size_small = 30

    -- local x = 1920 / 2 - 150
    -- local y = (1080 / 2) + 33

    local x = 20
    local y = 100

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    cairo_move_to(cr, x, y)
    cairo_set_font_size(cr, font_size)
    cairo_show_text(cr, time_main)
    cairo_stroke(cr)

    local extents = cairo_text_extents_t:create()
    tolua.takeownership(extents)
    cairo_text_extents(cr, time_main, extents)

    cairo_move_to(cr, x + extents.width + 20, y)
    cairo_set_font_size(cr, font_size_med)
    cairo_show_text(cr, seconds_str)
    cairo_stroke(cr)

    cairo_move_to(cr, x, y + 40)
    cairo_set_font_size(cr, font_size_small)
    cairo_show_text(cr, day .. " - " .. mday .. " " .. month)

    -- ==== Old circle clock ===

    -- local center_x = 1730
    -- local center_y = 200
    -- local radius = 170

    -- local font_size = radius / 5.5

    -- cairo_move_to(cr, center_x - font_size * 2.5, center_y + font_size / 2.5)
    -- cairo_set_font_size(cr, font_size)
    -- cairo_show_text(cr, hours_str .. ':' .. minutes_str .. ':' .. seconds_str)
    -- cairo_stroke(cr)

    -- if hours > 12 then hours = hours - 12 end

    -- local line_width = radius/8
    -- local start_angle = -math.pi / 2

    -- local end_angle = start_angle + ((hours + minutes / 60 + seconds / 3600) / 12) * 2 * math.pi
    -- cairo_set_line_width(cr, line_width)
    -- cairo_arc(cr, center_x, center_y, radius, start_angle, end_angle)
    -- cairo_stroke(cr)

    -- local end_angle = start_angle + ((minutes + seconds / 60) / 60) * 2 * math.pi
    -- cairo_set_line_width(cr, line_width)
    -- cairo_arc(cr, center_x, center_y, radius * 0.8, start_angle, end_angle)
    -- cairo_stroke(cr)

    -- if seconds == 0 then seconds = 60 end
    -- local end_angle = start_angle + (seconds / 60) * 2 * math.pi
    -- cairo_set_line_width(cr, line_width)
    -- cairo_arc(cr, center_x, center_y, radius * 0.6, start_angle, end_angle)
    -- cairo_stroke(cr)
end

function conky_server_uptime()
    if (not init_cairo()) then
        return
    end

    -- SERVER SERVICE STATUSES
    local start_x, start_y = 1910, 730

    local services =
        "mysql nginx sslh mpd pmv rstanger expressvpn sonarr radarr lidarr jackett ombi plexmediaserver deluged deluged-web"
    -- Script: systemctl status $service | grep Active | cut -d '(' -f2 | cut -d ')' -f1

    local statuses = split(conky_parse("${exec ssh media-server systemd-status " .. services .. "}"), "\n")

    local service_table = split(services, " ")

    cairo_set_font_size(cr, 15)

    for i in next, service_table do
        local service = service_table[i]
        local status = statuses[i]

        local y = start_y + 20 * (i - 1)

        if (status == "running") then
            cairo_set_source_rgba(cr, 0.55, 0.58, 0.25, 1)
        else
            cairo_set_source_rgba(cr, 0.647, 0.26, 0.26, 1)
        end
        cairo_arc(cr, start_x, y - 4, 4, 0, 2 * math.pi)
        cairo_fill(cr)
        cairo_stroke(cr)

        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

        local extents = cairo_text_extents_t:create()
        tolua.takeownership(extents)
        cairo_text_extents(cr, service, extents)

        cairo_move_to(cr, start_x - extents.width - 7, y)
        cairo_show_text(cr, service)
        cairo_stroke(cr)
    end

    -- SERVER UPTIME
    -- local days = conky_parse("${exec ssh media-server uptime | awk -F'( |,|:)+' '{print $6,$7}' }")
    -- if tonumber(split(days, " ")[1]) < 10 then
    --     days = "0" .. days
    -- end

    -- start_x = 1004
    -- start_y = 635

    -- local font_size = 30

    -- cairo_move_to(cr, start_x, start_y)
    -- cairo_set_font_size(cr, 30)
    -- cairo_show_text(cr, days)
    -- cairo_stroke(cr)

    -- cairo_move_to(cr, start_x, start_y + font_size * 1.9)
    -- cairo_show_text(cr, "without an accident")
    -- cairo_stroke(cr)

    -- cairo_set_line_width(cr, 4)
    -- cairo_rectangle(cr, start_x - font_size / 2.7, start_y - font_size * 1.2, font_size * 1.9, font_size * 1.85)
    -- cairo_stroke(cr)
end

function conky_calendar()
    if (not init_cairo()) then
        return
    end

    conky_parse("${exec python3 /home/jake/.config/conky/google_calendar.py}")

    local font_size = 15
    local start_x, start_y = 20, 170

    cairo_set_font_size(cr, font_size)

    local events = conky_parse("${exec cat /tmp/conky/calendar_events}")
    local event_table = split(events, "\n")

    for i in next, event_table do
        local split = split(event_table[i], "||")
        local date = split[1]
        local name = split[2]

        cairo_move_to(cr, start_x, start_y + (font_size + 3) * i)
        cairo_set_source_rgba(cr, COLOR_TERTIARY_R, COLOR_TERTIARY_G, COLOR_TERTIARY_B, 1)
        cairo_show_text(cr, date)
        cairo_stroke(cr)

        cairo_move_to(cr, start_x + 70, start_y + (font_size + 3) * i)
        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
        cairo_show_text(cr, name)
    end
end
