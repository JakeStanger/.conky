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


function sleep (a)
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
      maxNb = 0    -- No limit
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
  x=nil
  x=(im.x or 0)
  y=nil
  y=(im.y or 0)
  w=nil
  w=(im.w or 0)
  h=nil
  h=(im.h or 0)
  file=nil
  file=tostring(im.file)
  if file==nil then print("set image file") end

  local show = imlib_load_image(file)
  if show == nil then return end

  imlib_context_set_image(show)

  if tonumber(w)==0 then
    width=imlib_image_get_width()
  else
    width=tonumber(w)
  end
  if tonumber(h)==0 then
    height=imlib_image_get_height()
  else
    height=tonumber(h)
  end

  imlib_context_set_image(show)
  local scaled=imlib_create_cropped_scaled_image(0, 0, imlib_image_get_width(), imlib_image_get_height(), width, height)
  imlib_free_image()
  imlib_context_set_image(scaled)
  imlib_render_image_on_drawable(x, y)
  imlib_free_image()
  show=nil
end


function init_cairo()
  if conky_window == nil then
    return false
  end

  cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height)

  cr = cairo_create(cs)

  font = "Source Code Pro"

  cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
  cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

  return true
end

function conky_main()
  if (not init_cairo()) then
    return
  end


  local cx,cy = 10, 980
  local height = 90
  local width = 22
  local gap = 5

  -- CPU GRAPHS
  local num_cpus = 8
  for i = 1, num_cpus, 1 do
    local cpu = 0.05 + tonumber(conky_parse('${cpu cpu' .. i .. '}') / 100.0) * 0.95

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_move_to(cr, cx + (i-1)*(width + gap), cy + height)
    cairo_rel_line_to(cr, width, 0)
    cairo_rel_line_to(cr, 0, -height*cpu)
    cairo_rel_line_to(cr, -width, 0)
    cairo_fill(cr)
    cairo_move_to(cr, cx + (i-1)*(width + gap), cy + height +  10)
    cairo_show_text(cr, round(cpu, 2)*100 .. "%")
  end

  -- MEMORY
  local memmax = tonumber(conky_parse("$memmax"):sub(1, -4))
  local mem = memmax - tonumber(conky_parse('$memeasyfree'):sub(1, -4))
  local memperc = mem / memmax
  mem_string = mem .. " GiB"

  cairo_move_to(cr, 240, cy + height)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -height*memperc)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)

  cairo_move_to(cr, 240, 1080)
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
  local cx,cy = 475, 980
  local height = 11
  local width = 195
  local gap = 3

 local mounts = {}
 mounts[1] = {"Root", "/"}
 mounts[2] = {'Hard Drive', '/home/jake/HDD'}
 mounts[3] = {'Music', '/home/jake/Media/Music'}
 mounts[4] = {'Movies', '/home/jake/Media/Movies'}
 mounts[5] = {'Television', '/home/jake/Media/Television'}
 mounts[6] = {'Photos', '/home/jake/Media/Photos'}
 mounts[7] = {'Downloads', '/home/jake/Media/Downloads'}

  for i =1, tablelength(mounts), 1 do
    drive_perc = tonumber(conky_parse("${fs_used_perc " .. mounts[i][2] .. "}"))

    cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
    cairo_move_to(cr, cx, cy + (i-1)*(height+gap))
    cairo_rel_line_to(cr, 0, height)
    cairo_rel_line_to(cr, -width * drive_perc / 100 , 0)
    cairo_rel_line_to(cr, 0, -height)
    cairo_fill(cr)

    cairo_set_source_rgba(cr, COLOR_SECONDARY_R, COLOR_SECONDARY_G, COLOR_SECONDARY_B, 1)
    label = mounts[i][1] .. ': ' .. drive_perc .. '%'
    cairo_move_to(cr, cx - string.len(label)*6 - 5, cy + (i-1)*(height+gap) + height / 2 + 3)
    cairo_show_text(cr, label)
  end

	-- ALBUM INFO

  conky_parse("${exec python ~/.conky/currentSong.py}")

  local isPaused = conky_parse("${exec cat ~/.conky/data/paused}") == "True"

	--cairo_select_font_face(cr, font2, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

  local cx, cy = 1560, 990

	cairo_set_font_size(cr, 15)
	cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)
	cairo_move_to(cr, cx, cy)
	local song_title = conky_parse("${exec cat ~/.conky/data/track}")
	if isPaused then song_title = song_title .. " (Paused)" end
	cairo_show_text(cr, song_title)
	cairo_stroke(cr)

	cairo_move_to(cr, cx, cy + 20)
	local album_title = conky_parse("${exec cat ~/.conky/data/album}")
	cairo_show_text(cr, album_title)
	cairo_stroke(cr)

	cairo_move_to(cr, cx, cy + 40)
	local artist_title = conky_parse("${exec cat ~/.conky/data/artist}")
	cairo_show_text(cr, artist_title)
	cairo_stroke(cr)

  --  ALBUM COVER
   image({x=1455, y=980, h=100, w=100, file='/home/jake/.conky/data/thumbs/' .. album_title})

   -- PROGRESS BAR
   cairo_move_to(cr, cx, cy + 80)

   LENGTH = 350
   local duration = tonumber(conky_parse("${exec cat ~/.conky/data/duration}"))
   if duration ~= 0 then
     duration = round(duration / 1000, 0)
     local start_time = round(tonumber(conky_parse("${exec cat ~/.conky/data/startTime}")), 0)
     local elapsed = os.time() - start_time

     cairo_line_to (cr, cx+ (elapsed/duration)*LENGTH, cy + 80)
     cairo_stroke(cr)

     cairo_arc (cr, cx+ (elapsed/duration)*LENGTH, cy + 80, 5, 0, 2*math.pi)
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
  date_table = os.date('*t')

  hours = date_table['hour']
  minutes = date_table['min']
  seconds = date_table['sec']

  hours_str = tostring(hours)
  if string.len(hours_str) == 1 then hours_str = '0' .. hours_str end

  minutes_str = tostring(minutes)
  if string.len(minutes_str) == 1 then minutes_str = '0' .. minutes_str end

  seconds_str = tostring(seconds)
  if string.len(seconds_str) == 1 then seconds_str = '0' .. seconds_str end

  cairo_move_to(cr, 1100, 750)
  cairo_set_font_size(cr, 75)
  cairo_show_text(cr, hours_str .. ':' .. minutes_str .. ':' .. seconds_str)
  cairo_stroke(cr)

  if hours > 12 then hours = hours - 12 end

  center_x=1280
  center_y=720
  radius=400
  start_angle=-math.pi/2

  end_angle=start_angle+((hours + minutes/60 + seconds /3600) / 12)*2*math.pi
  cairo_set_line_width(cr, 50)
  cairo_arc (cr,center_x,center_y,radius,start_angle,end_angle)
  cairo_stroke (cr)

  end_angle=start_angle+((minutes + seconds/60) / 60)*2*math.pi
  cairo_set_line_width(cr, 50)
  cairo_arc (cr,center_x,center_y,radius * 0.8,start_angle,end_angle)
  cairo_stroke (cr)

  if seconds == 0 then seconds = 60 end
  end_angle=start_angle+(seconds / 60)*2*math.pi
  cairo_set_line_width(cr, 50)
  cairo_arc (cr,center_x,center_y,radius*0.6,start_angle,end_angle)
  cairo_stroke (cr)
end

function conky_server_uptime()
	if (not init_cairo()) then
    return
  end

	-- SERVER UPTIME
  days = split(string.sub(conky_parse('${exec ssh media-server uptime}'), 14), ' ')[1]

	cairo_move_to(cr, 50, 80)
	cairo_set_font_size(cr, 50)
  cairo_show_text(cr, days .. " days")
  cairo_stroke(cr)

	cairo_move_to(cr, 50, 150)
  cairo_show_text(cr, 'without an accident')
  cairo_stroke(cr)

	cairo_set_line_width (cr, 5);
	cairo_rectangle (cr, 40, 35, 80, 55);
	cairo_stroke (cr);

end
