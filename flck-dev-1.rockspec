package = "flck"
version = "dev-1"
source = {
	url = "https://github.com/manyids2/flck.git",
	tag = "dev-1",
}
description = {
	summary = "fzf-lua-cairo-kitty",
	homepage = "https://github.com/manyids2/flck.git",
	license = "MIT/X11",
	detailed = [[
fzf-lua-cairo-kitty
]],
}
dependencies = {
	"lua >= 5.1, <= 5.4",
	"middleclass",
	"inspect",
	"oocairo",
  "luv"
}
external_dependencies = {}
build = {
	type = "builtin",
	modules = {
		flck = "flck.lua",
		kitty = {
			sources = { "kitty/kitty.c" },
		},
	},
}
