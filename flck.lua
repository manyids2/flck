local P = require("external.inspect")
local Cairo = require("oocairo")

local IMG_WD = 512
local IMG_HT = 256

-- surface and context
local surface = Cairo.image_surface_create("rgb24", IMG_WD, IMG_HT)
local cr = Cairo.context_create(surface)

-- White background.
cr:set_source_rgb(1, 0, 0)
cr:paint()

-- As a test of different ways to write the output, this particular example
-- program writes the finished PNG file through a Lua filehandle.
local fh = assert(io.open("arc.png", "wb"))
surface:write_to_png(fh)
fh:close()
print("hello there")
