local conf = require('conf').t
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



local function reset()
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
playing = true
end

local lx = 173
local ly = 130
local potw = 22
function love.draw()
	local lgw, lgh = lg.getDimensions()
	local sx = lgw/conf.window.width
	local sy = lgh/conf.window.height
	local scale = math.min(1, math.min(sx, sy))
	lgw, lgh = lgw/scale, lgh/scale
	lg.scale(scale, scale)

	local x0 = math.floor(math.max(0, (lgw-res.img.bg:getWidth())/2))
	local y0 = math.floor(math.max(0, (lgh-res.img.bg:getHeight())/2))
	lg.setColor(1,1,1)
	lg.draw(res.img.bg, x0, y0)

	lg.setFont(res.font.lcd)
	lg.setColor(res.palette.on)
	lg.printf(score, x0, y0+105, 335, 'right')

	for line,v in ipairs(foods) do
		for food, visible in ipairs(v) do
			if visible then lg.draw(res.img.food[food], x0+lx, y0+ly+(line-1)*34) end
		end
	end

	for pot, visible in ipairs(pots) do
		if visible then lg.draw(res.img.pot, x0+lx+5+(pot-1)*potw, y0+310) end
	end
	for splosh, visible in ipairs(sploshes) do
		if visible then lg.draw(res.img.splosh, x0+lx+5+(splosh-1)*potw, y0+335) end
	end
	for cook=0, lives-1 do
		lg.draw(res.img.cook, x0+lx+cook*25, y0+100)
	end

end


local t=0
local currentEmptyLines=999

function love.update(dt)
	if not playing then return end
	t=t+dt

	slowness = math.max(0.1, 0+70/(score+100))
	emptyLines = math.max(0, math.ceil(4-(score+30)/40))

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

local function left()
	if not pots[1] then
		--res.sfx.move.src:play()
		table.remove(pots, 1)
		table.insert(pots, _)
	end
end

local function right()
	if not pots[#pots] then
		--res.sfx.move.src:play()
		table.remove(pots, #pots)
		table.insert(pots, 1, _)
	end
end


function love.keypressed(key)
	if key == 'escape' then love.event.quit()
	elseif not playing and not gameover then reset()
	elseif key == 'left' then left()
	elseif key == 'right' then right() end
end

function love.mousereleased(x, _y, button)
   if button == 1 then
	if not playing and not gameover then reset()
	elseif x<lg:getWidth()*0.45 then left()
	elseif x>lg:getWidth()*0.55 then right() end
   end
end

function love.joystickreleased(_joystick, button)
	if not playing and not gameover then reset() end
	if button == 4 or button == 5 or button == 7 then left() end
	if button == 2 or button == 6 or button == 8 then right() end
end

function love.joystickhat(_joystick, _hat, direction )
	if not playing and not gameover then reset() end
	if direction == 'l' then left() end
	if direction == 'r' then right() end
end

--[[ breaks android
function love.joystickaxis(_joystick, axis, value )
	if not playing and not gameover then reset()
	elseif axis == 1 then
		if value < 0 then left() end
		if value > 0 then right() end
	end
end
--]]
