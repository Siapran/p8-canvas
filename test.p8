pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include canvas.lua

do
	local canvas = make_canvas(0x80, 0xa0, 0)

	canvas.update(42, 42, 2, 1, function()
		pset(42, 42, 7)
		pset(43, 42, 8)
		pset(44, 42, 9)
	end)

	assert(canvas.pget(42, 42) == 7)
	assert(canvas.pget(43, 42) == 8)
	assert(canvas.pget(44, 42) == 0)
	assert(canvas.pget(256, 12973) == 0)
end

do
	local canvas = make_canvas(0x80, 0xa0, 0)

	srand()
	canvas.update(0, 0, 32, 32, function()
		for y=0,31 do
			for x=0,31 do
				pset(x,y,rnd(16)&-1)
			end
		end
	end)

	srand()
	for y=0,31 do
		for x=0,31 do
			assert(canvas.pget(x,y) == rnd(16)&-1)
		end
	end
end

print("all tests passed", 7)
