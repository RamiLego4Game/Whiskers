local gamera = require("libraries.gamera")
local gamestate = require("libraries.gamestate")
local tween = require("libraries.tween")

local World = require("whiskers.world")
local Kitten = require("whiskers.kitten")
local Pellet = require("whiskers.pellet")
local Powerup = require("whiskers.powerup")

local screenWidth, screenHeight = love.graphics.getDimensions()

local gameState = {}

--The world dimensions
gameState.worldWidth = 20*_pixelsToMeterFactor --The width of the world, 20 meters
gameState.worldHeight = gameState.worldWidth * (screenHeight / screenWidth) --The height of the world, depends on the screen ratio

--The pellet spawner timer
gameState.pelletSpawnerInitialTimer = 15
gameState.pelletSpawnerTimer = 10

--The powerup spawner timer
gameState.powerupSpawnerInitialTimer = 15
gameState.powerupSpawnerTimer = 10

gameState.keyControls = {
	z = 1,
	x = 2,
	c = 3,
	v = 4
}

gameState.touchControls = {}

function gameState:init()
	for i=1, 4 do
		local btn = {}
		btn.image = _image["button"..i]
		
		btn.imageSize = btn.image:getDimensions()
		btn.size = 85
		btn.scale = btn.size / btn.imageSize
		
		btn.down = false
		btn.enabled = true
		
		if i == 1 then  --Bottom Left
			btn.x1, btn.y1 = 0, screenHeight-btn.size
			btn.x2, btn.y2 = btn.size, screenHeight
		elseif i == 2 then --Bottom Right
			btn.x1, btn.y1 = screenWidth-btn.size, screenHeight-btn.size
			btn.x2, btn.y2 = screenWidth, screenHeight
		elseif i == 3 then --Top Right
			btn.x1, btn.y1 = screenWidth-btn.size, 0
			btn.x2, btn.y2 = screenWidth, btn.size
		else --Top Left
			btn.x1, btn.y1 = 0, 0
			btn.x2, btn.y2 = btn.size, btn.size
		end
		
		self.touchControls[i] = btn
	end
end

function gameState:enter()
	print("--==Game State Entered==--")
	
	love.graphics.setBackgroundColor(70/255,70/255,70/255, 1)

	self.world = World(self.worldWidth, self.worldHeight)
	
	self.camera = gamera.new(0,0, self.worldWidth, self.worldHeight)
	self.camera:setScale(screenWidth/self.worldWidth)
	
	for i=1, 4 do self.world:spawnKitten(i) end
	
	self:playMusic()
	
	self.pelletSpawnerTimerr = self.pelletSpawnerInitialTimer
	self.powerupSpawnerTimerr = self.powerupSpawnerInitialTimer
	
	self.lightningTween, self.lightningTween2 = nil, nil
end

function gameState:leave()
	love.audio.stop() --Stop all the audio which is being played by this state
end

function gameState:draw(vx,vy,vw,vh)
	self.camera:enable()
	
	self.world:draw()
	
	self.camera:disable()
	
	self.world:drawLightning()
	
	self:drawButtons()
end

function gameState:drawButtons()
	
	for id,btn in pairs(self.touchControls) do
		
		if btn.down then
			love.graphics.setColor(170/255,170/255,170/255,200/255)
		else
			love.graphics.setColor(1,1,1,200/255)
		end
		
		love.graphics.draw(
			btn.image,
			btn.x1,
			btn.y1,
			0,
			btn.scale,
			btn.scale
		)
	end
	
end

function gameState:update(dt)
	self.world:update(dt) --Update the whiskers world
	
	--Check scales
	local kittens = self.world:getKittens()
	for i=1,4 do
		if kittens[i].size >= Kitten.maximumSize then
			local kittensList = {}
			for j=1,4 do
				kittens[j].imageScale = kittens[j].size/kittens[j].imageSize --Make sure the image scale is the final value, because of tweens
				kittensList[j] = kittens[j]
			end
			gamestate.switch(_states["score"], kittensList)
			return
		end
	end
	
	--Pellet Timer
	self.pelletSpawnerTimerr = self.pelletSpawnerTimerr - dt
	if self.pelletSpawnerTimerr <= 0 then
		self.pelletSpawnerTimerr = self.pelletSpawnerTimer
		self.world:spawnPellet()
	end
	
	--Powerup Timer
	self.powerupSpawnerTimerr = self.powerupSpawnerTimerr - dt
	if self.powerupSpawnerTimerr <= 0 then
		self.powerupSpawnerTimerr = self.powerupSpawnerTimer
		self.world:spawnPowerup()
	end
end

function gameState:keypressed(key,scancode,isrepeat)
	local id = self.keyControls[key]
	if id then
		if self.world.kittens[id] then
			self.world.kittens[id]:turn()
			self.touchControls[id].down = true
		end
	end
end

function gameState:keyreleased(key,scancode,isrepeat)
	local id = self.keyControls[key]
	if id then
		if self.world.kittens[id] then
			self.touchControls[id].down = false
		end
	end
end

function gameState:playMusic()
	if not _DEBUG then
		_music["mapleLeafRag"]:play()
	end
end

function gameState:mousepressed(x,y,button,istouch)
	if istouch then return end
	self.world:spawnPellet(self.camera:toWorld(x,y))
end

function gameState:touchpressed(id,x,y,dx,dy,pressure)
	for id,btn in pairs(self.touchControls) do
		if not btn.touchid then
			if btn.x1 <= x and btn.y1 <= y and btn.x2 >= x and btn.y2 >= y then
				btn.touchid = id
				btn.down = true
				self.world.kittens[id]:turn()
				break
			end
		end
	end
end

function gameState:touchreleased(id,x,y,dx,dy,pressure)
	for id,btn in pairs(self.touchControls) do
		if btn.touchid and btn.touchid == id then
			if btn.x1 <= x and btn.y1 <= y and btn.x2 >= x and btn.y2 >= y then
				btn.touchid = nil
				btn.down = false
				break
			end
		end
	end
end

return gameState