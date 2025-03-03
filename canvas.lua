function make_canvas(cache_bank, render_bank, transparency)
	local cache_addr = cache_bank << 8
	local render_addr = render_bank << 8

	local function dup(x, n)
		if (n > 0) return x, dup(x, n-1)
	end
	local empty_tile = chr(dup(transparency | (transparency << 4), 32))

	local function read_tile(src, w, h)
		local function read(acc, src, h)
			if (h > 0) return read(acc .. chr(peek(src, w)), src + 64, h-1)
			return acc
		end
		return read("", src, h)
	end

	local function write_tile(tile, dst, w, h)
		local off = 1
		for i=0,h-1 do
			poke(dst + (i << 6), ord(tile, off, w))
			off += w
		end
	end

	local tiles, cache, old, new = {}, {}, {}, {}
	new.next = old
	old.prev = new

	local function set_newest(node)
		node.next = new.next
		node.next.prev = node
		new.next = node
		node.prev = new
	end

	local function cut_node(node)
		node.prev.next = node.next
		node.next.prev = node.prev
	end

	for i=0,255 do
		set_newest{ sprnum = i,
			addr = cache_addr | ((i & -16) << 5) | ((i & 15) << 2)}
	end

	local function cached_tile(tile)
		local node = cache[tile]
		if not node then
			node = old.prev
			if (node.owner) cache[node.owner] = nil
			write_tile(tile, node.addr, 4, 8)
			node.owner = tile
			cache[tile] = node
		end
		cut_node(node)
		set_newest(node)
		return node.sprnum
	end

	local function cam_aware_clip(x, y, w, h, clip_prev)
		clip(x - %0x5f28, y - %0x5f2a, w, h, clip_prev)
	end

	local function draw_impl(x0, y0, x1, y1)
		local gfxbak = @0x5f54
		poke(0x5f54, cache_bank)
		for y=y0,y1,8 do
			for x=x0,x1,8 do
				local tile = tiles[y | (x >>> 16)]
				if (tile) spr(cached_tile(tile), x, y)
			end
		end
		poke(0x5f54, gfxbak)
	end

	local function canv_draw(x, y, w, h)
		if (not h) return canv_draw(%0x5f28, %0x5f2a, 128, 128)
		local clipbak = $0x5f20
		cam_aware_clip(x, y, w, h, true)
		draw_impl(x&-8, y&-8, (x+w)&-8, (y+h)&-8)
		poke4(0x5f20, clipbak)
	end

	return {
		draw = canv_draw,
		update = function(x, y, w, h, draw)
			local x0, y0, x1, y1 = x&-8, y&-8, (x+w)&-8, (y+h)&-8
			local cambak = $0x5f28
			camera(x0, y0)
			local clipbak = $0x5f20
			clip()
			local vidbak = @0x5f55
			poke(0x5f55, render_bank)

			rectfill(x0, y0, x1+8, y1+8, 0)
			draw_impl(x0, y0, x1, y1)
			cam_aware_clip(x, y, w, h, true)
			draw()

			x1, y1 = mid(x1, 0x8000, x0+120), mid(y1, 0x8000, y0+120)
			for y=y0,y1,8 do
				local yoff = (y-y0) << 6
				for x=x0,x1,8 do
					local addr = render_addr | yoff | ((x-x0) >>> 1)
					local tile = read_tile(addr, 4, 8)
					 tiles[y | (x >>> 16)] = tile ~= empty_tile and tile or nil
				end
			end
			
			poke(0x5f55, vidbak)
			poke4(0x5f28, cambak)
			poke4(0x5f20, clipbak)
		end
	}

end
