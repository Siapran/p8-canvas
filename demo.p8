pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include canvas.lua

local function rand(n)
	return rnd(n)&-1
end

local canvas = make_canvas(0x80, 0xa0, 0)

poke(0x5f36,0x2)
local cx, cy
local frame = 0

function _update()
	cx = -64 + sin(t()/10) * 128
	cy = -64 + cos(t()/10) * 128

	if frame % 4 == 0 then
		local x, y = cx + 16 + rand(96), cy + 16 + rand(96)
		local r = rand(16) + 8
		local c = rand{2, 8, 14}

		local x0, y0, w, h = x-r, y-r, 2*r+1, 2*r+1
		canvas.update(x0, y0, w, h, function()
			circfill(x, y, r, c)
		end)
	end
	frame += 1	
end

function count_tiles()
	local res = 0
	for k,_ in pairs(canvas.tiles) do
		res += 1
	end
	return res
end

function _draw()
	cls()
	
	camera(cx, cy)
	-- canvas.draw(cx, cy, 128, 128)
	canvas.draw()

	camera()
	print("mem usage: " .. stat(0), 2, 2, 7)
	print("tile count: " .. count_tiles())
end
