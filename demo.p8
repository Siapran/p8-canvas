pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include canvas.lua

local function rand(n)
	return rnd(n)&-1
end

local canvas = make_canvas(0x80, 0x60, 0)
local canvas2 = make_canvas(0xa0, 0x60, 0)
local canvas3 = make_canvas(0xc0, 0x60, 0)

local canv_list = {canvas3, canvas2, canvas}
local palettes = {{4, 9, 10}, {1, 13, 12}, {2, 8, 14}}

poke(0x5f36,0x2)
local frame = 0

function _update()
	for i=1,3 do
		local canv = canv_list[i]
		local t = time() + i*2
		canv.cx = -64 + sin(t/6) * 128
		canv.cy = -64 + cos(t/6) * 128

		if frame % 3 == i - 1 then
			local x, y = canv.cx + 16 + rand(96), canv.cy + 16 + rand(96)
			local r = rand(16) + 8
			local c = rand(palettes[i])

			local x0, y0, w, h = x-r, y-r, 2*r+1, 2*r+1
			canv.update(x0, y0, w, h, function()
				circfill(x, y, r, c)
			end)
		end
	end
	frame += 1	
end

function count_tiles(canv)
	local res = 0
	for k,_ in pairs(canv.tiles) do
		res += 1
	end
	return res
end

function _draw()
	cls()

	-- alternatively: 	
	-- camera(canvas.cx, canvas.cy)
	-- canvas.draw()

	local tiles = 0

	for canv in all(canv_list) do
		canv.draw(canv.cx, canv.cy, 128, 128, 0, 0)
		tiles += count_tiles(canv)
	end

	print("mem usage: " .. stat(0), 2, 2, 7)
	print("tile count: " .. tiles)
end

