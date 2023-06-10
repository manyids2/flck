local Cairo = require("oocairo")
local kitty = require("kitty")

local IMG_WD = 256
local IMG_HT = 64

-- surface and context
local surface = Cairo.image_surface_create("rgb24", IMG_WD, IMG_HT)
local cr = Cairo.context_create(surface)

-- White background.
cr:set_source_rgb(1, 1, 1)
cr:paint()

-- program writes the finished PNG file through a Lua filehandle.
local fh = assert(io.open("arc.png", "wb"))
surface:write_to_png(fh)
fh:close()

print(kitty._VERSION)
