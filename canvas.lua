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
		return node
	end

	local function canv_draw(cx, cy, w, h, sx, sy)
		local clipbak, cambak, gfxbak = $0x5f20, $0x5f28, @0x5f54
		poke(0x5f54, cache_bank)
		clip(sx, sy, w, h, true)
		
		local ox, oy = cx-sx, cy-sy
		local x0, y0, x1, y1 =
			@0x5f20+ox&-8, @0x5f21+oy&-8, @0x5f22+ox-1&-8, @0x5f23+oy-1&-8
		local tw = x1-x0
		camera(ox-x0, oy-y0)

		for y=0,y1-y0,8 do
			local sy = y0+y>>>16
			for x=0,tw,8 do
				local tile = tiles[x0+x|sy]
				if (tile) spr(cached_tile(tile).sprnum, x, y)
			end
		end
		
		poke4(0x5f28, cambak)
		poke4(0x5f20, clipbak)
		poke(0x5f54, gfxbak)
	end

	return {
		draw = function(sx, sy, w, h, dx, dy)
			if (not sx) return canv_draw(%0x5f28, %0x5f2a, 128, 128, 0, 0)
			return canv_draw(
				sx, sy, w or 128, h or 128, (dx or 0)-%0x5f28, (dy or 0)-%0x5f2a)
		end,
		update = function(x, y, w, h, draw)
			local tx, ty, tw, th = x&-8, y&-8, mid(w+7,120), mid(h+7,120)

			local clipbak, cambak, vidbak = $0x5f20, $0x5f28, @0x5f55
			camera(tx, ty)
			poke(0x5f55, render_bank)

			local function iter(fn)
				for y=0,th,8 do
					local yoff, sy = y << 6, ty+y>>>16
					for x=0,tw,8 do
						fn(tx+x|sy, render_addr | yoff | x >>> 1)
					end
				end
			end

			iter(function(idx, addr)
				write_tile(tiles[idx] or empty_tile, addr)
			end)

			clip(x&7, y&7, w, h, true)
			draw()

			iter(function(idx, addr)
				local tile = read_tile(addr)
				tiles[idx] = tile ~= empty_tile and tile or nil
			end)
			
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
