local class = require("middleclass")
local Cairo = require("oocairo")
local ffi = require("ffi")

ffi.cdef([[

typedef struct line {
  int r;
  char buf[256];
} line;
typedef struct kdata {
  int iid;
  int offset;
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

int kitty_send_rgba(int id, const char *color_pixels,
                       int width, int height, int compression);

]])

local kitty = ffi.load("./kitty.so")

local Flck = class("Flck") -- 'Flck' is the class' name

function Flck:initialize()
	local size = kitty.kitty_get_size()
	self.millis = 10
	self.xpixel = size.xpixel
	self.ypixel = size.ypixel
	self.row = size.row
	self.col = size.col
	self.keystroke = nil
	self.pos = { x = 0, y = 0 }
	self.colors = {
		w = { r = 0, b = 0, g = 0 },
		a = { r = 1, b = 0, g = 0 },
		s = { r = 0, b = 1, g = 0 },
		d = { r = 0, b = 0, g = 1 },
	}
	self.now = "w"
	self.dirty = true
	self.exit = false
	self.im_id = 1
	self.compression = 0

	-- surface and context
	self.surface = Cairo.image_surface_create("argb32", self.xpixel, self.ypixel)
	self.cr = Cairo.context_create(self.surface)
end

function Flck:show_image()
	local data = self.surface:get_data()
	local cdata = ffi.new("char[?]", string.len(data) + 1)
	ffi.copy(cdata, data)

	kitty.kitty_set_position(0, 0)
	kitty.kitty_send_rgba(self.im_id, cdata, self.xpixel, self.ypixel, self.compression)
	kitty.kitty_set_position(0, 0)
end

function Flck:render()
	if not self.dirty then
		return
	end
	local cr = self.cr
	cr:set_source_rgb(0.8, 0.8, 0.8)
	cr:paint()

	local r, g, b
	r = self.colors[self.now].r * 0.8
	g = self.colors[self.now].g * 0.8
	b = self.colors[self.now].b * 0.8

	-- Gradient background.
	-- local grad = Cairo.pattern_create_linear(0, 0, self.xpixel, self.ypixel)
	local min = math.min(self.xpixel, self.ypixel)
	local PI = 2 * math.asin(1)
	local x, y, radius = self.xpixel / 2, self.ypixel / 2, (min / 2) - (min * 0.1)

	cr:set_source_rgb(r, g, b)
	cr:arc(x, y, radius, 0, PI * 2)
	cr:fill()

	self:show_image()

	self.dirty = false
end

function Flck:mount()
	kitty.kitty_clear_screen(self.row)
	kitty.kitty_setup_termios()
	kitty.kitty_hide_cursor()
	self:poll_events()
end

function Flck:unmount()
	-- drain kitty responses
	self:poll_events()

	-- restore cursor position then show cursor
	kitty.kitty_show_cursor()
	kitty.kitty_set_position(self.pos.x, self.pos.y)
	kitty.kitty_restore_termios()

	kitty.kitty_clear_screen(self.row)
end

function Flck:run()
	for _ = 1, 1000 do
		if self.exit then
			break
		end

		kitty.kitty_set_position(self.pos.x, self.pos.y - self.ypixel)
		self:render()
		self:poll_events()
	end
end

function Flck:poll_events()
	local r = kitty.kitty_recv_term(self.millis)
	local n = ffi.sizeof(r.buf)
	local buf = ffi.string(r.buf, n)
	local key = tostring(string.sub(buf, 1, 1))
	if key == "q" then
		self.exit = true
	elseif key == "w" then
		self.now = "w"
		self.dirty = true
	elseif key == "a" then
		self.now = "a"
		self.dirty = true
	elseif key == "s" then
		self.now = "s"
		self.dirty = true
	elseif key == "d" then
		self.now = "d"
		self.dirty = true
	end
end

local flck = Flck:new()

flck:mount()
flck:run()
flck:unmount()
