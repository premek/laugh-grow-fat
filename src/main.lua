local res = require 'resources'
local lg = love.graphics

local _=false
local X=true

local lives=3
local score=88888
local pots={X,X,X,X,X,X,X}
local sploshes={X,X,X,X,X,X,X}
local foods={
	{X,X,X,X,X,X,X},
	{X,X,X,X,X,X,X},
	{X,X,X,X,X,X,X},
	{X,X,X,X,X,X,X},
	{X,X,X,X,X,X,X}}

function love.load()
end

local playing = false
local gameover = false


local slowness = nil
local emptyLines = nil



function reset()
lives=3
score=0	
pots={_,_,_,X,_,_,_}
sploshes={_,_,_,_,_,_,_}
foods={
	{_,_,_,_,_,_,_},
	{_,_,_,_,_,_,_},
	{_,_,_,_,_,_,_},
	{_,_,_,_,_,_,_},
	{_,_,_,_,_,_,_}}
end



local lx = 173
local ly = 130
local potw = 22
function love.draw()
	lg.setColor(1,1,1)	
	lg.draw(res.img.bg, 0, 0)

	lg.setFont(res.font.lcd)
	lg.setColor(res.palette.on)
	lg.printf(score, 0, 105, 335, 'right')

	for line,v in ipairs(foods) do
		for food, visible in ipairs(v) do
			if visible then lg.draw(res.img.food[food], lx, ly+(line-1)*34) end
		end
	end
	
	for pot, visible in ipairs(pots) do
		if visible then lg.draw(res.img.pot, lx+5+(pot-1)*potw, 310) end
	end
	for splosh, visible in ipairs(sploshes) do
		if visible then lg.draw(res.img.splosh, lx+5+(splosh-1)*potw, 335) end
	end
	for cook=0, lives-1 do	
		lg.draw(res.img.cook, lx+cook*25, 100)
	end

end


local t=0
local currentEmptyLines=999

function love.update(dt)
	if not playing then return end
	t=t+dt

	slowness = math.max(0.1, 1-score/170)
	emptyLines = math.max(0, math.ceil(4-(score+30)/50))

	if t<slowness then return end
	t=t-slowness
	--print(score, slowness, emptyLines)

	sploshes={_,_,_,_,_,_,_}

	for pos, foodPresent in ipairs(foods[#foods]) do
		if foodPresent then
			if pots[pos] then
				score = score+1 
				res.sfx.hit.src:play()
			else
				sploshes[pos] = X				
				lives = lives - 1
				if lives == 0 then 
					playing=false
					gameover=true 
					res.sfx.gameover.src:play()
				else
					res.sfx.fail.src:play()
				end
			end
		end
	end

	table.remove(foods, #foods)
	currentEmptyLines = currentEmptyLines + 1
	table.insert(foods, 1, {_,_,_,_,_,_,_})

	if currentEmptyLines > emptyLines then
		foods[1][love.math.random(7)] = X
		currentEmptyLines=0
	end
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
	
	if not playing and not gameover then 
		reset()
		playing = true

  	elseif key == 'left' then
		if not pots[1] then
			--res.sfx.move.src:play()
			table.remove(pots, 1)
			table.insert(pots, _)
		end
  	elseif key == 'right' then
		if not pots[#pots] then
			--res.sfx.move.src:play()
			table.remove(pots, #pots)
			table.insert(pots, 1, _)
		end
  	end
end
