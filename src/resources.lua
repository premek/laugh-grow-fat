local res = {
  palette = {
    on = {0.1,0.1,0.1},
    off = {108/255,117/255,71/255},
    bg = {181/255,194/255,181/255}
  },

  img = {
	bg = love.graphics.newImage("img/bg.jpg"),
	pot = love.graphics.newImage("img/pot.png"),
	splosh = love.graphics.newImage("img/splosh.png"),
	cook = love.graphics.newImage("img/cook.png"),
	food = {
	  love.graphics.newImage("img/f1.png"),
	  love.graphics.newImage("img/f2.png"),
	  love.graphics.newImage("img/f3.png"),
	  love.graphics.newImage("img/f4.png"),
	  love.graphics.newImage("img/f5.png"),
	  love.graphics.newImage("img/f6.png"),
	  love.graphics.newImage("img/f7.png"),
	}
  },

  font = {
    lcd = love.graphics.setNewFont( 'font/cedders_segment7/Segment7Standard.otf', 25)
  },

  music = {
    love.audio.newSource('music/loop.wav', 'static' )
  },
  sfx = {
    hit = {"hit.wav"},
    fail = {"fail.wav"},
    move = {"move.wav", vol=0.5},
    gameover = {"gameover.wav"},
  }
}

res.music[1]:setLooping( true )
res.music[1]:setVolume(.8)
res.music[1]:play()

for k, v in pairs(res.sfx) do
  print("Loading sfx", k, v[1])
  v.src = love.audio.newSource( 'sfx/'..v[1], 'static' )
  if v.vol then v.src:setVolume(v.vol) end
  if v.loop then v.src:setLooping(true) end
end

return res
