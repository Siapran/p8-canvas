# p8-canvas
![demo](./img/demo.gif)

p8-canvas is an infinite canvas implementation for pico-8:
```lua
-- (cache area, render area, transparency color)
-- multiple canvas instances can use the same render area
local canvas = make_canvas(0x80, 0xa0, 0)

-- update one corner of the canvas
canvas.update(-10000, 15000, 32, 32, function()
    circfill(-10000 + 16, 15000 + 16, 6, 7)
end)

-- in a galaxy far, far away...
canvas.update(20000, 0, 32, 32, function()
    circfill(20000 + 16, 16, 6, 7)
end)

camera(-10000, 15000)
canvas.draw() -- draws screen region by default (with camera offset applied)
canvas.draw(-10000, 15000, 32, 32) -- draws an arbitrary region (may be offscreen)

camera(20000-64, -64)
canvas.draw()
```
possible uses:
- destructible terrain
- blood splatters
- snow tracks
- drawing program?

notes:
- maximum _safe_ update region size is 120x120, because of tile stradling
- if you _know_ your region is tile aligned, then 128x128 is fine
- drawing region can be as big as you like
- this implementation works best for a panning view of the canvas: the more tiles can be reused from one frame to the next, the less cpu time it will take
- don't use `camera` in the update function
- you can have multiple canvases! just make sure they each have their own cache region
- the cache and render regions should be picked from `0x0, 0x60, 0x80, 0xa0, 0xc0, 0xe0` (see the [remapping section of the pico-8 manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#Remapping_Graphics_and_Map_Data))

under the hood:
- canvas is stored as a sparse tilemap in Lua memory
- tiles are unpacked into a sprite cache in RAM as needed when drawing
- not much else, really, there's a couple clever things done with strings and tables but that's it
