require 'cairo'
require 'imlib2'

COLOR_PRIMARY_R = 0.773
COLOR_PRIMARY_G = 0.784
COLOR_PRIMARY_B = 0.776

COLOR_SECONDARY_R = 0.177
COLOR_SECONDARY_G = 0.169
COLOR_SECONDARY_B = 0.200

function round(x, n)
    n = math.pow(10, n or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end


function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end


function sleep(a)
    local sec = tonumber(os.clock() + a);
    while (os.clock() < sec) do
    end
end


function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0 -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then
            break
        end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
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
    if file == nil then print("set image file") end

    local show = imlib_load_image(file)
    if show == nil then return end

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
    local scaled = imlib_create_cropped_scaled_image(0, 0, imlib_image_get_width(), imlib_image_get_height(), width, height)
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

    local cs = cairo_xlib_surface_create(conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height)

    cr = cairo_create(cs)

    local font = "Source Code Pro"

    cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    return true
end

function conky_main()
    if (not init_cairo()) then
        return
    end

    local cx, cy = 1805, 520
    local height = 22
    local width = 90
    local gap = 5

    -- CPU GRAPHS
    local num_cpus = 8
    for i = 1, num_cpus, 1 do
        local cpu = 0.05 + tonumber(conky_parse('${cpu cpu' .. i .. '}') / 100.0) * 0.95

        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
        cairo_move_to(cr, cx + width + gap, cy + (i -1 ) * (height + gap))
        cairo_rel_line_to(cr, 0, -height)
        cairo_rel_line_to(cr, -width * cpu, 0)
        cairo_rel_line_to(cr, 0, height)
        cairo_fill(cr)
        cairo_move_to(cr, cx + width + gap + 5, cy + (i -1 ) * (height + gap) - 7)
        cairo_show_text(cr, round(cpu, 2) * 100 .. "%")
    end

    -- MEMORY
    local memmax = tonumber(conky_parse("$memmax"):sub(1, -4))
    local mem = memmax - tonumber(conky_parse('$memeasyfree'):sub(1, -4))
    local memperc = mem / memmax
    local _ = mem .. " GiB"

    cairo_move_to(cr, cx + width, cy - 35)
    cairo_rel_line_to(cr, 0, -height)
    cairo_rel_line_to(cr, -width * memperc, 0)
    cairo_rel_line_to(cr, 0, height)
    cairo_fill(cr)

    cairo_move_to(cr, cx + width + 5, cy - 42)
    cairo_show_text(cr, round(memperc * 100, 0) .. "%")

    cairo_destroy(cr)
    cairo_surface_destroy(cs)

    cr = nil
end




-- FILE SYSTEM
function conky_fs_main()
    if (not init_cairo()) then
        return
    end

    -- FILE SYSTEM
    local cx, cy = 1920, 410
    local height = 11
    local width = 195
    local gap = 3

    local mounts = {}
    mounts[1] = { "Root", "/" }
    mounts[2] = { 'Hard Drive', '/home/jake/HDD' }
    mounts[3] = { 'Media', '/home/jake/Media' }

    for i = 1, tablelength(mounts), 1 do
        local drive_perc = tonumber(conky_parse("${fs_used_perc " .. mounts[i][2] .. "}"))

        cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
        cairo_move_to(cr, cx, cy + (i - 1) * (height + gap))
        cairo_rel_line_to(cr, 0, height)
        cairo_rel_line_to(cr, -width * drive_perc / 100, 0)
        cairo_rel_line_to(cr, 0, -height)
        cairo_fill(cr)

        cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
        local label = mounts[i][1] .. ': ' .. drive_perc .. '%'
        cairo_move_to(cr, cx - string.len(label) * 6 - 5, cy + (i - 1) * (height + gap) + height / 2 + 3)
        cairo_show_text(cr, label)
    end

    -- ALBUM INFO
    local artist_title = conky_parse("$mpd_artist")
    local album_title = conky_parse("$mpd_album")
    conky_parse("${exec python /home/jake/.conky/album_art.py '" .. artist_title .. "' '" .. album_title .. "'}")

    local isPaused = conky_parse("$mpd_status") == "Paused"

    --cairo_select_font_face(cr, font2, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    local cx, cy = 1150, 170

    cairo_set_font_size(cr, 15)
    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_move_to(cr, cx, cy)
    local song_title = conky_parse("$mpd_title")
    if isPaused then song_title = song_title .. " (Paused)" end
    cairo_show_text(cr, song_title)
    cairo_stroke(cr)

    cairo_move_to(cr, cx, cy + 20)
    cairo_show_text(cr, album_title)
    cairo_stroke(cr)

    cairo_move_to(cr, cx, cy + 40)
    cairo_show_text(cr, artist_title)
    cairo_stroke(cr)

    --  ALBUM COVER
    image({ x = 990, y = 160, h = 150, w = 150, file = '/home/jake/.conky/data/thumbs/' .. artist_title .. ' - ' ..album_title})

    -- PROGRESS BAR
    local bar_height = cy + 80
    cairo_move_to(cr, cx, bar_height)

    local LENGTH = 370
    local duration_raw = split(conky_parse("$mpd_length"), ":", 2)
    local duration = tonumber(duration_raw[1]) * 60 + tonumber(duration_raw[2])
    if duration ~= 0 then
        local elapsed_raw = split(conky_parse("$mpd_elapsed"), ':', 2)
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
    local center_x = 1730
    local center_y = 200
    local radius = 170

    local font_size = radius / 5.5

    local date_table = os.date('*t')

    local hours = date_table['hour']
    local minutes = date_table['min']
    local seconds = date_table['sec']

    local hours_str = tostring(hours)
    if string.len(hours_str) == 1 then hours_str = '0' .. hours_str end

    local minutes_str = tostring(minutes)
    if string.len(minutes_str) == 1 then minutes_str = '0' .. minutes_str end

    local seconds_str = tostring(seconds)
    if string.len(seconds_str) == 1 then seconds_str = '0' .. seconds_str end

    cairo_move_to(cr, center_x - font_size * 2.5, center_y + font_size / 2.5)
    cairo_set_font_size(cr, font_size)
    cairo_show_text(cr, hours_str .. ':' .. minutes_str .. ':' .. seconds_str)
    cairo_stroke(cr)

    if hours > 12 then hours = hours - 12 end


    local line_width = radius/8
    local start_angle = -math.pi / 2

    local end_angle = start_angle + ((hours + minutes / 60 + seconds / 3600) / 12) * 2 * math.pi
    cairo_set_line_width(cr, line_width)
    cairo_arc(cr, center_x, center_y, radius, start_angle, end_angle)
    cairo_stroke(cr)

    local end_angle = start_angle + ((minutes + seconds / 60) / 60) * 2 * math.pi
    cairo_set_line_width(cr, line_width)
    cairo_arc(cr, center_x, center_y, radius * 0.8, start_angle, end_angle)
    cairo_stroke(cr)

    if seconds == 0 then seconds = 60 end
    local end_angle = start_angle + (seconds / 60) * 2 * math.pi
    cairo_set_line_width(cr, line_width)
    cairo_arc(cr, center_x, center_y, radius * 0.6, start_angle, end_angle)
    cairo_stroke(cr)
end

function conky_server_uptime()
    if (not init_cairo()) then
        return
    end

    -- SERVER UPTIME
    local days = conky_parse('${exec ssh media-server uptime | awk -F\'( |,|:)+\' \'{if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0,"days"}\' }')
    if tonumber(split(days, " ")[1]) < 10 then
        days = '0' .. days
    end

    local start_x = 1000
    local start_y = 60

    local font_size = 30

    cairo_move_to(cr, start_x, start_y)
    cairo_set_font_size(cr, 30)
    cairo_show_text(cr, days)
    cairo_stroke(cr)

    cairo_move_to(cr, start_x, start_y+font_size*1.9)
    cairo_show_text(cr, 'without an accident')
    cairo_stroke(cr)

    cairo_set_line_width(cr, 4);
    cairo_rectangle(cr, start_x-font_size/2.7, start_y-font_size*1.2, font_size*1.9, font_size*1.85);
    cairo_stroke(cr);
end

function conky_calendar()
    if (not init_cairo()) then
        return
    end

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

    local width = 1000
    local height = 800

    local start_x = 200
    local start_y = 200

    local DAYS = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }

    cairo_set_line_width(cr, 7);
    for i = 1, 5 do --Weeks
        for j = 1, 7 do  --Days
            cairo_rectangle(cr, start_x+(width/7)*(j-1), start_y+(height/5)*(i-1), width/7, height/5);
            cairo_stroke(cr);
        end
    end
end