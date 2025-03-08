function make_canvas(cache_bank, render_bank, transparency)

	local function write_tile(tile, dst)
		local off = 1
		for i=1,8 do
			poke(dst, ord(tile, off, 4))
			dst += 64
			off += 4
		end
	end

	local cache_addr, render_addr, empty_tile, tiles, cache, list =
		cache_bank<<8, render_bank<<8, chr(transparency | transparency<<4),
		{}, {}, {}

	for i=1,5 do
		empty_tile..=empty_tile
	end

	list.next, list.prev = list, list

	local function push_node(node)
		node.prev, node.next = list, list.next
		list.next, node.next.prev = node, node
	end

	for i=0,255 do
		push_node{false, i, cache_addr | i<<5 & 0xfe00 | i<<2 & 0x3c}
	end

	local function pushed_ctx(bank, fn)
		return function(...)
			local pclip, pcam, pbank = $0x5f20, $0x5f28, @bank
			fn(...)
			poke4(0x5f28, pcam)
			poke4(0x5f20, pclip)
			poke(bank, pbank)
		end
	end

	local function draw_impl(cx, cy, w, h, sx, sy)
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
				if tile then
					local node = cache[tile]
					if not node then
						node = list.prev
						write_tile(tile, node[3])
						node[1], cache[tile], cache[node[1]] = tile, node
					end
					node.prev.next, node.next.prev = node.next, node.prev
					push_node(node)
					spr(node[2], x, y)
				end
			end
		end
	end

	return {
		draw = pushed_ctx(0x5f54, function(sx, sy, w, h, dx, dy)
			if (not sx) return draw_impl(%0x5f28, %0x5f2a, 128, 128, 0, 0)
			return draw_impl(
				sx, sy, w or 128, h or 128, (dx or 0)-%0x5f28, (dy or 0)-%0x5f2a)
		end),
		update = pushed_ctx(0x5f55, function(x, y, w, h, draw)
			local tx, ty, tw, th = x&-8, y&-8, mid(w+7,120), mid(h+7,120)
			camera(tx, ty)
			poke(0x5f55, render_bank)

			local function iter(fn)
				for y=0,th,8 do
					local yoff, sy = y<<6, ty+y>>>16
					for x=0,tw,8 do
						fn(tx+x|sy, render_addr | yoff | x>>>1)
					end
				end
			end

			iter(function(idx, addr)
				write_tile(tiles[idx] or empty_tile, addr)
			end)

			clip(x&7, y&7, w, h, true)
			draw()

			iter(function(idx, addr)
				local tile = ""
				for i=1,8 do
					tile ..= chr(peek(addr, 4))
					addr += 64
				end
				tiles[idx] = tile ~= empty_tile and tile or nil
			end)
		end),
		pget = function(x, y)
			return ord(
				tiles[x&-8 | y>>>16 & 0x0.fff8] or empty_tile,
				(y<<2 & 0x1c | x>>>1 & 0x03) + 1) >>> (x<<2 & 0x4) & 15
		end,
		tiles = tiles
	}

end
