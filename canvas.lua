function make_canvas(cache_bank, render_bank, transparency)
	local cache_addr, render_addr = cache_bank<<8, render_bank<<8

	local function dup(x, n)
		if (n > 0) return x, dup(x, n-1)
	end
	local empty_tile = chr(dup(transparency | transparency<<4, 32))

	local function read_tile(src)
		local res = ""
		for i=1,8 do
			res ..= chr(peek(src, 4))
			src += 64
		end
		return res
	end

	local function write_tile(tile, dst)
		local off = 1
		for i=1,8 do
			poke(dst, ord(tile, off, 4))
			dst += 64
			off += 4
		end
	end

	local tiles, cache, list = {}, {}, {}
	list.next, list.prev = list, list

	local function push_node(node)
		node.prev, node.next = list, list.next
		list.next, node.next.prev = node, node
	end

	local function remove_node(node)
		node.prev.next, node.next.prev = node.next, node.prev
	end

	for i=0,255 do
		push_node{ sprnum = i,
			addr = cache_addr | i<<5 & 0xfe00 | i<<2 & 0x3c }
	end

	local function cached_tile(tile)
		local node = cache[tile]
		if not node then
			node = list.prev
			if (node.owner) cache[node.owner] = nil
			write_tile(tile, node.addr)
			node.owner = tile
			cache[tile] = node
		end
		remove_node(node)
		push_node(node)
		return node.sprnum
	end



	local function draw_impl(x0, y0, x1, y1)
		local gfxbak = @0x5f54
		poke(0x5f54, cache_bank)
		for y=y0,y1,8 do
			local sy = y>>>16
			for x=x0,x1,8 do
				local tile = tiles[x|sy]
				if (tile) spr(cached_tile(tile), x, y)
			end
		end
		poke(0x5f54, gfxbak)
	end

	local function canv_draw(cx, cy, w, h, sx, sy)
		local ox, oy = cx-sx, cy-sy
		local clipbak, cambak = $0x5f20, $0x5f28
		clip(sx, sy, w, h, true)
		camera(ox, oy)
		draw_impl(@0x5f20+ox&-8, @0x5f21+oy&-8, @0x5f22+ox-1, @0x5f23+oy-1)
		poke4(0x5f28, cambak)
		poke4(0x5f20, clipbak)
	end

	return {
		draw = function(sx, sy, w, h, dx, dy)
			if (not sx) return canv_draw(%0x5f28, %0x5f2a, 128, 128, 0, 0)
			return canv_draw(
				sx, sy, w or 128, h or 128, (dx or 0)-%0x5f28, (dy or 0)-%0x5f2a)
		end,
		update = function(x, y, w, h, draw)
			local x0, y0, x1, y1 = x&-8, y&-8, (x+w+7&-8)-1, (y+h+7&-8)-1

			local clipbak, cambak, vidbak = $0x5f20, $0x5f28, @0x5f55
			clip()
			camera(x0, y0)
			poke(0x5f55, render_bank)

			rectfill(x0, y0, x1, y1, 0)
			draw_impl(x0, y0, x1, y1)
			clip(x-%0x5f28, y-%0x5f2a, w, h, true)
			draw()

			for y=y0,y1,8 do
				local yoff, sy = y-y0 << 6, y>>>16
				for x=x0,x1,8 do
					local tile = read_tile(render_addr | yoff | x-x0 >>> 1)
					tiles[x|sy] = tile ~= empty_tile and tile or nil
				end
			end
			
			poke(0x5f55, vidbak)
			poke4(0x5f28, cambak)
			poke4(0x5f20, clipbak)
		end,
		pget = function(x, y)
			local tile = tiles[x&-8 | y>>>16 & 0x0.fff8]
			if tile then
				return ord(tile, (y<<2 & 0x1c | x>>>1 & 0x03) + 1)
					>>> (x<<2 & 0x4) & 15
			end
			return transparency
		end,
		tiles = tiles
	}

end
