pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include canvas.lua

local canvas = make_canvas(0x80, 0xa0, 0)

canvas.update(42, 42, 2, 1, function()
	pset(42, 42, 7)
	pset(43, 42, 8)
	pset(44, 42, 9)
end)

assert(canvas.pget(42, 42) == 7)
assert(canvas.pget(43, 42) == 8)
assert(canvas.pget(44, 42) == 0)

print"all tests passed"
