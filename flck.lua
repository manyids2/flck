local Cairo = require("oocairo")

local ffi = require("ffi")
ffi.cdef([[
void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);

typedef struct line line;
typedef struct kdata kdata;
typedef struct pos pos;

void kitty_set_position(int x, int y);
void kitty_hide_cursor();
void kitty_show_cursor();
pos kitty_get_position();
void kitty_setup_termios();
void kitty_restore_termios();

]])

local function sleep(s)
	ffi.C.poll(nil, 0, s * 1000)
end

local kitty = ffi.load("./kitty.so")

kitty.kitty_setup_termios()

sleep(1.0)

kitty.kitty_restore_termios()

-- local IMG_WD = 256
-- local IMG_HT = 64
--
-- -- surface and context
-- local surface = Cairo.image_surface_create("rgb24", IMG_WD, IMG_HT)
-- local cr = Cairo.context_create(surface)
--
-- -- White background.
-- cr:set_source_rgb(1, 1, 1)
-- cr:paint()
--
-- -- program writes the finished PNG file through a Lua filehandle.
-- local fh = assert(io.open("arc.png", "wb"))
-- surface:write_to_png(fh)
-- fh:close()
