local inspect = require("inspect")
local class = require("middleclass")
local Cairo = require("oocairo")

local ffi = require("ffi")
ffi.cdef([[

typedef struct line {
  size_t r;
  char buf[256];
} line;
typedef struct kdata {
  int iid;
  size_t offset;
  struct line data;
} kdata;
typedef struct pos {
  int x, y;
} pos;
typedef struct ksize {
  int row, col, xpixel, ypixel;
} ksize;

ksize kitty_get_size();
void kitty_set_position(int x, int y);
void kitty_hide_cursor();
void kitty_show_cursor();
pos kitty_get_position();
void kitty_setup_termios();
void kitty_restore_termios();
void kitty_clear_screen(int lh);
line kitty_recv_term(int timeout);
kdata kitty_parse_response(line l);

]])

local kitty = ffi.load("./kitty.so")

local Flck = class("Flck") -- 'Flck' is the class' name

function Flck:initialize()
	local size = kitty.kitty_get_size()
	self.millis = 1000
	self.xpixel = size.xpixel
	self.ypixel = size.ypixel
	self.row = size.row
	self.col = size.col
	self.dirty = true
	self.keystroke = nil
	self.pos = { x = 0, y = 0 }
	self.exit = false
end

function Flck:render()
	if not self.dirty then
		return
	end
	-- surface and context
	local surface = Cairo.image_surface_create("rgb24", self.xpixel, self.ypixel)
	local cr = Cairo.context_create(surface)

	-- White background.
	cr:set_source_rgb(1, 1, 1)
	cr:paint()

	-- -- program writes the finished PNG file through a Lua filehandle.
	-- local fh = assert(io.open("arc.png", "wb"))
	-- surface:write_to_png(fh)
	-- fh:close()
	self.dirty = false
end

function Flck:mount()
	kitty.kitty_setup_termios()
	kitty.kitty_hide_cursor()
	-- self:poll_events()
end

function Flck:unmount()
	-- drain kitty responses
	-- self:poll_events()

	-- restore cursor position then show cursor
	kitty.kitty_show_cursor()
	kitty.kitty_set_position(self.pos.x, self.pos.y)
	kitty.kitty_restore_termios()

	-- kitty.kitty_clear_screen(self.row)
end

function Flck:run()
	for _ = 1, 10 do
		self:render()
		kitty.kitty_set_position(self.pos.x, self.pos.y - self.ypixel)
		self:poll_events()

		if self.exit then
			break
		end
	end
end

function Flck:poll_events()
	local r = kitty.kitty_recv_term(self.millis)
	local n = ffi.sizeof(r.buf)
	local buf = ffi.string(r.buf, n)
	local key = tostring(string.sub(buf, 1, 1))
	if key == "q" then
		self.exit = true
	end
end

local flck = Flck:new()

flck:mount()
flck:run()
flck:unmount()
