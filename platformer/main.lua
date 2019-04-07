package.path = package.path .. ";../noise.lua"

require "cairo"
require "imlib2"
require "noise"

-- Worldgen config
SEED = 8008135
FIDELITY = 5 -- The number of pixels per square, lower = higher resolution

SEA_LEVEL = 45 -- The number of pixels at which the sea should start

-- Conky config
WIDTH = 2560
HEIGHT = 1440

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

-- Convert hex codes to conky rgb values (0 to 1)
function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255, tonumber("0x" .. hex:sub(5, 6)) /
    255
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

  render_sea()
  render_terrain()
  render_character()
end

function render_sea()
  local red, green, blue = hex_to_rgb("#22aaff")
  cairo_set_source_rgba(cr, red, green, blue, 1)

  cairo_rectangle(cr, 0, HEIGHT - (SEA_LEVEL * FIDELITY), WIDTH, SEA_LEVEL * FIDELITY)
  cairo_fill(cr)
  cairo_stroke(cr)
end

function render_terrain()
  -- TILE_TYPES = {
  --   [1] = {
  --     "type": ""
  --   }
  -- }

  for i = 1, WIDTH, FIDELITY do
    for j = HEIGHT, 1, -FIDELITY do
    local red, green, blue = hex_to_rgb("#22aaff")
      print(noise(i, j))
    -- cairo_set_source_rgba(cr, 1 / i * 1000, 1 / j * 1000, 1 / (j*i) * 1000, 1)
  
    -- cairo_rectangle(cr, i, j, FIDELITY, FIDELITY)
    -- cairo_fill(cr)
    -- cairo_stroke(cr)
    end
  end
end

function render_character()
  local cx = conky_parse("${exec cat /tmp/conky/platformer/x}")
  local cy = conky_parse("${exec cat /tmp/conky/platformer/y}")

  cairo_set_source_rgba(cr, COLOR_PRIMARY_R, COLOR_PRIMARY_G, COLOR_PRIMARY_B, 1)

  cairo_set_line_width(cr, 10)
  cairo_arc(cr, cx, cy, 5, 0, 2 * math.pi)
  cairo_stroke(cr)
end
