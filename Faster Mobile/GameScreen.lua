local composer = require( "composer" )
local scene = composer.newScene()

local gameNetwork = require("gameNetwork")

--local ads = require("ads")

-- include Corona's "physics" library
local physics = require("physics")
physics.start(); physics.pause()
physics.setGravity(0, 20)
--physics.setDrawMode("hybrid")
--------------------------------------------

--include the random level generator
local RLG = require("RLG")

local levelComplete = false
local switching = false

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

--local functions for performance
local mRand = math.random

--music
local currentTrack
local tracks = {"SciFi.ogg", "Dystopic-Technology", "Dark-Techno", "Sci-Fi-Open"}

local background
local background2 --black in the play area and tile background everywhere else

local leftArrow
local rightArrow
local upArrow

local pause

local isPaused = false

local lives, roomsComplete, highScore
local livesText, roomsCompleteText, highScoreText

--external reference to the player object
local player
--player and enemy sprite sheet data
local characterImageData = {width = 32, height = 32, numFrames = 8, sheetContentWidth = 128, sheetContentHeight = 64}
local imageSheet = graphics.newImageSheet("Tiles/Character.png", characterImageData)
local sequenceData = {
	{name = "right", start = 1, count = 4, time = 500},
	{name = "left" , start = 5, count = 4, time = 500}
}

local entities = {} --holds all entities on screen

local map

--0 = blank tile
--1 = std tile
--2 = player
--3 = enemy
--4 = spike
--5 = falling tile
--6 = rising tile
--7 = flamethrower
--8 = cannon
--9 = exit portal

local function orient(map, x, y) --function to orient certain tiles based on surrounding tiles
	if map[y][x-1] == 1 then
		return 0
	elseif map[y-1][x] == 1 then
		return 90
	elseif map[y][x+1] == 1 then
		return 180
	elseif map[y+1][x] == 1 then
		return 270
	end
end

local function resume()
	composer.removeScene("pause")
	timer.performWithDelay(10, function() isPaused = false; end)
	audio.resume() --resume music
	physics.start() --resume physics
end

local function endGame()
	if roomsComplete ~= 0 then --do not save score of zero
		local path = system.pathForFile("highScoreData.txt", system.DocumentsDirectory) --load high scores from file

		local file = io.open(path, "r") --open in read mode to get previous score

		local scores = {}

		if file then
			for line in file:lines() do --insert all previous scores into table for sorting
				scores[#scores + 1] = line
			end

			scores[#scores + 1] = roomsComplete .. " " .. composer.getVariable("difficulty") --add new score to table along with difficulty

			table.sort(scores, function(x, y) --sort new score into correct pos in table
				return tonumber(x:match("%d+")) > tonumber(y:match("%d+"))
			end)

			file:close()
		end

		file = io.open(path, "w") --open in write mode to rewrite scores

		if file then

			for i = 1, #scores do --loop through score
				file:write(scores[i] .. "\n") --write score
			end

			file:close()
		end
	end

	if composer.getVariable("loggedIn") then --upload to game center/google play
		local difficultyCode --the leaderboard ID of the proper leaderboard
		if composer.getVariable("difficulty") == "easy" then
			difficultyCode = "FasterMobileEasy"
		elseif composer.getVariable("difficulty") == "medium" then
			difficultyCode = "FasterMobileMedium"
		else
			difficultyCode = "FasterMobileHard"
		end

		gameNetwork.request("setHighScore", {localPlayerScore = {category = difficultyCode, value = roomsComplete}}) --set high score on game center
	end
end

--initialization functions
local function initPlayer()
	player = display.newSprite(imageSheet, sequenceData)

	player:setFillColor(0.03, 0.78, 1)

	player.name = "Player"

	player.isAlive = true

	physics.addBody(player, "dynamic", {density = 1.65, friction = 0.0, bounce = 0, radius = 15},
		{shape = {13, 12, 13, 15, -13, 15, -13, 12}, isSensor = true, filter = {groupIndex = -1}}, --onGround sensor
		{shape = {-15, -1, 0, -1, -0, 1, -15, 1}, isSensor = true, filter = {groupIndex = -1}}, --left sensor
		{shape = {15, -1, 0, -1, 0, 1, 15, 1}, isSensor = true, filter = {groupIndex = -1}},--right sensor
		{shape = {5, -15, 5, -12, -5, -12, -5, -15}, isSensor = true, filter = {groupIndex = -1}}) --top sensor

	player.isFixedRotation = true

	player.vx = 0; player.vy = 0 --x and y velocity
	player.onGround = 0 --whether or not the player is touching the ground (number used to detect how many tiles the player is on)
	player.topColl = false --used to detect whether the player should be crushed
	player.isJumping = false
	player.isOn = {StdTile = 0, UpTile = 0, DownTile = 0}

	player.collision = function(self, event) -- player's collision
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		if event.phase == "began" then
			if event.other.name == "Spike" or
				event.other.name == "Enemy" or
				event.other.name == "CannonBall" or
				event.other.name == "FlameThrower" and event.selfElement == 1 then
				self.isAlive = false
			elseif event.other.name == "ExitPortal" then
				levelComplete = true
			end
		end

		if self.topColl and self.isOn["UpTile"] > 0 then
			self.isAlive = false
		end

		if event.selfElement == 2 then --only allow collision on the ground sensor
			if event.phase == "began" then --if the player hits a tile increment onGround
				if event.other.name == "StdTile" then --keep track of the tiles the player is standing on
					self.isOn["StdTile"] = self.isOn["StdTile"] + 1
				elseif event.other.name == "DownTile" and event.otherElement == 1 then
					self.isOn["DownTile"] = self.isOn["DownTile"] + 1
				elseif event.other.name == "UpTile" and event.otherElement == 1 then
					self.isOn["UpTile"] = self.isOn["UpTile"] + 1
				end

				self.onGround = self.onGround + 1
				self.isJumping = false
			elseif event.phase == "ended" then --if the player leaves a tile decrement onGround (clamp to positive)
				if event.other.name == "StdTile" then --keep track of the tiles the player is standing on
					self.isOn["StdTile"] = self.isOn["StdTile"] - 1
				elseif event.other.name == "DownTile" and event.otherElement == 1 then
					self.isOn["DownTile"] = self.isOn["DownTile"] - 1
				elseif event.other.name == "UpTile" and event.otherElement == 1 then
					self.isOn["UpTile"] = self.isOn["UpTile"] - 1
				end

				timer.performWithDelay(10, function() self.onGround = self.onGround - 1; if self.onGround < 0 then self.onGround = 0 end; end)
			end
		elseif event.selfElement == 3 and event.phase ~= "ended" then
			timer.performWithDelay(10, function() player.x = event.other.x + 31; end)
		elseif event.selfElement == 4 and event.phase ~= "ended" then
			timer.performWithDelay(10, function() player.x = event.other.x - 31; end)
		elseif event.selfElement == 5 then
			if event.phase == "began" then
				self.topColl = true
			elseif event.phase == "ended" then
				self.topColl = false
			end
		end
	end
	player:addEventListener("collision", player)
end

local function initEnemy()
	local object = display.newImageRect("Tiles/Enemy.png", 32, 32)

	physics.addBody(object, "dynamic", {radius = 15, isSensor = false, filter = {groupIndex = -1}}) --enemies cannot collide
	object.isFixedRotation = true; object.gravityScale = 0

	object.vel = 100

	object.moveAxis = math.random(0, 1) --decide which axis to move on (0 = x, 1 = y)

	object.name = "Enemy"

	object.collision = function(self, event)
		--only detect element one to stop multiple collisions from one contact
		if event.phase == "began" and event.other.name ~= "FlameThrower" and event.other.name ~= "Enemy" and event.otherElement == 1 then
			self.vel = -self.vel
		end
	end
	object:addEventListener("collision", object)

	return object
end

local function initSpike()
	local object = display.newImageRect("Tiles/Spike.png", 32, 32)

	object.name = "Spike"

	physics.addBody(object, "static", {density = 1.5, friction = 0.0, bounce = 0})

	return object
end

local function initDTile()
	local object = display.newImageRect("Tiles/DownTile.png", 32, 32)

	object.name = "DownTile"
	object.validContact = false
	object.onGround = false

	physics.addBody(object, "static", {density = 0, friction = 0.0, bounce = 0, shape = {-15, -15, 15, -15, 15, 16, -15, 16}},
		{shape = {-14, -15, 14, -15, 14, 0, -14, 0}, isSensor = true})
	object.gravityScale = 0; object.isFixedRotation = true

	object.preCollision = function(self, event) --force stop the player if it touches DownTile while it is falling
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		if player.isOn["UpTile"] < 1 and player.isOn["StdTile"] < 1 and not player.isJumping then --prevent DownTile "pulling" the player off of a tile
			player.y = object.y - 30
			player.gravityScale = 0
		end

		if event.other.name == "Player" and player.onGround > 0 then
			if player.isOn["DownTile"] == 2 then
				self.y = event.other.y + 30
			end
		end

		if self.bodyType == "dynamic" and select(2, self:getLinearVelocity()) < 0 then
			timer.performWithDelay(10, function() if not player.isAlive or levelComplete then return end; event.other:setLinearVelocity(0, 0); end)
		end
	end
	object:addEventListener("preCollision", object)

	object.collision = function(self, event) --DownTile's collision
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		if event.other.name == "Player" and event.selfElement == 2 and event.otherElement == 2 then --if colliding with player
			if event.phase == "began" then
				self.validContact = true
				timer.performWithDelay(1, function() self.bodyType = "dynamic"; end) --allow movement
			elseif event.phase == "ended" then
				timer.performWithDelay(10, function() self.validContact = false; end) --stop downward movement
				self.onGround = false
			end
		elseif event.other.bodyType == "static" and event.other.name ~= "FlameThrower" and event.selfElement == 1 then --if the tile touches the ground, stop it
			if event.phase == "began" then
				self.onGround = true
			elseif event.phase == "ended" then
				self.onGround = false
			end
		end
	end
	object:addEventListener("collision", object)

	return object
end

local function initUTile()
	local object = display.newImageRect("Tiles/UpTile.png", 32, 32)

	object.name = "UpTile"
	object.validContact = false

	physics.addBody(object, "static", {density = 0, friction = 0.0, bounce = 0, shape = {-15, -16, 15, -16, 15, 16, -15, 16}},
		{shape = {-14, -16, 14, -16, 14, 0, -14, 0}, isSensor = true})
	object.gravityScale = 0; object.isFixedRotation = true

	object.preCollision = function(self, event) --force stop the player if it touches UpTile while it is falling
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		if self.bodyType == "dynamic" and select(2, self:getLinearVelocity()) > 0 then
			timer.performWithDelay(10, function() if not player.isAlive or levelComplete then return end; event.other:setLinearVelocity(0, 0); end)
		end
	end
	object:addEventListener("preCollision", object)

	object.collision = function(self, event)
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		if event.other.name == "Player" and event.selfElement == 2 and event.otherElement == 2 then --only react to player collision
			if event.phase == "began" then
				self.validContact = true
				timer.performWithDelay(10, function() self.bodyType = "dynamic"; end) --cannot edit physics properties during collision
			elseif event.phase == "ended" then
				--to make sure the player is really off the tile, force delay before ending contact
				timer.performWithDelay(10, function() self.validContact = false; end)
			end
		end
	end
	object:addEventListener("collision", object)

	return object
end

local function initFlameThrower(map, x, y, sceneGroup)
	local object = display.newImageRect("Tiles/FlameThrower.png", 32, 32)
	object.x = display.contentCenterX + (x - 10) * 32 - 16; object.y = y * 32 + (90)

	object.orientation = orient(map, x, y)
	object:rotate(object.orientation)

	object.name = "FlameThrower"

	physics.addBody(object, "static", {shape = {16, 0, 47, 14, 47, -14}, isSensor = true})
	object.isBodyActive = false

	timer.performWithDelay(2000, function(event)
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			timer.cancel(event.source)
			return
		end

		object.isBodyActive = not object.isBodyActive;

		for i = 1, 25 do
			object.fire[i].isVisible = not object.fire[i].isVisible
		end
	end, -1) --cycle between the fire's off and on state every 2 seconds(2000 milliseconds)

	object.fire = {} --stores the fire(not actual physics body for performance, approximation used instead)
	for i = 1, 25 do
		object.fire[i] = display.newRect(0, 0, 2, 2)
		sceneGroup:insert(object.fire[i])

		--determine starting pos for fire
		if object.orientation == 0 then
			object.fire[i].x = object.x + 15; object.fire[i].y = object.y
			object.fire[i].stX = object.x + 15; object.fire[i].stY = object.y
		elseif object.orientation == 90 then
			object.fire[i].x = object.x; object.fire[i].y = object.y + 15
			object.fire[i].stX = object.x; object.fire[i].stY = object.y + 15
		elseif object.orientation == 180 then
			object.fire[i].x = object.x - 15; object.fire[i].y = object.y
			object.fire[i].stX = object.x - 15; object.fire[i].stY = object.y
		elseif object.orientation == 270 then
			object.fire[i].x = object.x; object.fire[i].y = object.y - 15
			object.fire[i].stX = object.x; object.fire[i].stY = object.y - 15
		end

		--randomly make each particle red, yellow, or orange and give it a random opacity
		local random = mRand(0, 2)
		if random == 0 then
			object.fire[i]:setFillColor(1, 0, 0, mRand(0, 255) / 255) --red
		elseif random == 1 then
			object.fire[i]:setFillColor(1, 1, 0, mRand(0, 255) / 255) --yellow
		elseif random == 2 then
			object.fire[i]:setFillColor(1, 0.5, 0, mRand(0, 255) / 255) --orange
		end

		--use orientation to decide the velocity of the fire
		if object.orientation == 0 then
			object.fire[i].velocity = {x = mRand(100, 300) / 100, y = mRand(0, 200) * 0.006 - 0.6}
		elseif object.orientation == 90 then
			object.fire[i].velocity = {x = mRand(0, 200) * 0.006 - 0.6, y = mRand(100, 300) / 100}
		elseif object.orientation == 180 then
			object.fire[i].velocity = {x = -mRand(100, 300) / 100, y = mRand(0, 200) * 0.006 - 0.6}
		elseif object.orientation == 270 then
			object.fire[i].velocity = {x = mRand(0, 200) * 0.006 - 0.6, y = -mRand(100, 300) / 100}
		end

		object.fire[i].isVisible = false --fire invisible while body is inactive
	end

	return object
end

local function initCannon(map, x, y, sceneGroup)
	local object = display.newImageRect("Tiles/Cannon.png", 32, 32)
	object.x = display.contentCenterX + (x - 10) * 32 - 16; object.y = y * 32 + (90)

	object.orientation = orient(map, x, y)
	object:rotate(object.orientation)

	object.barrel = display.newImageRect("Tiles/CannonBarrel.png", 32, 32)
	sceneGroup:insert(object.barrel)
	object.barrel:rotate(object.orientation)

	if object.orientation == 0 then
		object.barrel.anchorX = 0; object.barrel.anchorY = 0.5
		object.barrel.x = object.x - 16; object.barrel.y = object.y
	elseif object.orientation == 90 then
		object.barrel.anchorX = 0; object.barrel.anchorY = 0.5
		object.barrel.x = object.x; object.barrel.y = object.y - 16
	elseif object.orientation == 180 then
		object.barrel.anchorX = 0; object.barrel.anchorY = 0.5
		object.barrel.x = object.x + 16; object.barrel.y = object.y
	elseif object.orientation == 270 then
		object.barrel.anchorX = 0; object.barrel.anchorY = 0.5
		object.barrel.x = object.x; object.barrel.y = object.y + 16
	end

	object.ball = display.newRect(0, 0, 3, 3)
	sceneGroup:insert(object.ball)

	if object.orientation == 0 then
		object.ball.x = object.x - 14; object.ball.y = object.y
	elseif object.orientation == 90 then
		object.ball.x = object.x; object.ball.y = object.y - 14
	elseif object.orientation == 180 then
		object.ball.x = object.x + 14; object.ball.y = object.y
	elseif object.orientation == 270 then
		object.ball.x = object.x; object.ball.y = object.y + 14
	end

	object.ball.origX = object.ball.x; object.ball.origY = object.ball.y
	object.ball:setFillColor(1, 0, 0)
	physics.addBody(object.ball, "dynamic", {density = 0, friction = 0, bounce = 0, filter = {groupIndex = -1}})
	object.ball.gravityScale = 0; object.ball.isFixedRotation = true

	object.l1 = {x = object.ball.origX, y = object.ball.origY} --line used for cannon barrel rotating and cannon firing
	object.l2 = {}

	object.ball.fired = false

	object.name = "Cannon"

	object.ball.name = "CannonBall"

	object.ball.collision = function(self, event)--local collision for reliability (global collision creates problems when CannonBall is not operand 1)
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		self:setLinearVelocity(0, 0)
		self.fired = false
		timer.performWithDelay(10, function() self.x = self.origX; self.y = self.origY; end)
	end

	object.ball:addEventListener("collision", object.ball)

	return object
end

--initializes entities in the level from the generated map
local function initEntities(sceneGroup)
	for i = 1, #map do
		for j = 1, #map[i] do
			if map[i][j] == 1 then --StdTile
				entities[#entities+1] = display.newImageRect("Tiles/StdTile.png", 32, 32)
				entities[#entities].name = "StdTile"
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)
				physics.addBody(entities[#entities], "static", {density = 1.5, friction = 0.0, bounce = 0, shape = {-15, -15, 15, -15, 15, 15, -15, 15}})

			elseif map[i][j] == 2 then --Player
				initPlayer()
				entities[#entities+1] = player--external reference to player
				player.x = display.contentCenterX + (j - 10) * 32 - 16; player.y = i * 32 + (90)

			elseif map[i][j] == 3 then --Enemy
				entities[#entities+1] = initEnemy()
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)

			elseif map[i][j] == 4 then --Spike
				entities[#entities+1] = initSpike()
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)

			elseif map[i][j] == 5 then --DownTile
				entities[#entities+1] = initDTile()
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)
				entities[#entities].origX = entities[#entities].x; entities[#entities].origY = entities[#entities].y

			elseif map[i][j] == 6 then --UpTile
				entities[#entities+1] = initUTile()
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)
				entities[#entities].origX = entities[#entities].x; entities[#entities].origY = entities[#entities].y

			elseif map[i][j] == 7 then --FlameThrower
				entities[#entities+1] = initFlameThrower(map, j, i, sceneGroup)

			elseif map[i][j] == 8 then --Cannon
				entities[#entities+1] = initCannon(map, j, i, sceneGroup)

			elseif map[i][j] == 9 then --ExitPortal
				entities[#entities+1] = display.newImageRect("Tiles/ExitPortal.png", 20, 32)
				entities[#entities].x = display.contentCenterX + (j - 10) * 32 - 16; entities[#entities].y = i * 32 + (90)
				entities[#entities].name = "ExitPortal"
				physics.addBody(entities[#entities], "static", {density = 1.0, friction = 0.0, bounce = 0})
			end
		end
	end

	return entities
end

--initialize input arrows
local function initArrows()
	--left arrow button
	leftArrow = display.newImage("Tiles/Arrow.png", 100, display.contentHeight - 100)
	leftArrow:setFillColor(1, 0.8)
	leftArrow.rotation = 180
	leftArrow.touch = function(self, event) --if button is pressed, move left
		if event.phase == "began" then --if there is a touch move left
			display.getCurrentStage():setFocus(self, event.id)
			player.vx = -200
			leftArrow.alpha = 0.8 --increase alpha when the button is touched
		elseif event.phase == "ended" or event.phase == "canceled" then --if it is released stop
			display.getCurrentStage():setFocus(nil)
			player.vx = 0
			leftArrow.alpha = 1
		end

		return true
	end
	leftArrow:addEventListener("touch", leftArrow)

	--right arrow button
	rightArrow = display.newImage("Tiles/Arrow.png", 280, display.contentHeight - 100)
	rightArrow:setFillColor(1, 0.8)
	rightArrow.touch = function(self, event) --if button is pressed, move right
		if event.phase == "began" then --if there is a touch move right
			display.getCurrentStage():setFocus(self, event.id)
			player.vx = 200
			rightArrow.alpha = 0.8
		elseif event.phase == "ended" or event.phase == "canceled" then --if it is released stop
			display.getCurrentStage():setFocus(nil)
			player.vx = 0
			rightArrow.alpha = 1
		end

		return true
	end
	rightArrow:addEventListener("touch", rightArrow)

	--up arrow button
	upArrow = display.newImage("Tiles/Arrow.png", display.contentWidth - 100, display.contentHeight - 100)
	upArrow:rotate(270)
	upArrow:setFillColor(1, 0.8)
	upArrow.touch = function(self, event) --if button is pressed, jump and stop further jumping
		if not player.isAlive or levelComplete then --if the game is not active, cancel function
			return
		end

		print("jumping", player.onGround)

		if player.onGround > 0 and not player.isJumping then --if player is on the ground
			player.gravityScale = 1
			player:setLinearVelocity(select(1, player:getLinearVelocity()), 0)
			player:applyForce(0, -950, player.x, player.y) --apply jumping force
			player.isJumping = true
		end

		if event.phase == "began" then
			upArrow.alpha = 0.8
		elseif event.phase == "ended" then
			upArrow.alpha = 1
		end

		return true
	end
	upArrow:addEventListener("touch", upArrow)
end
-------------------------

--functions to update all entities
local function updatePlayer()
	--move the player in the x direction with out disturbing the y movement
	player:setLinearVelocity(player.vx, select(2, player:getLinearVelocity()))

	if player.vx > 0 then
		if player.sequence ~= "right" then
			player:setSequence("right")
		end
		player:play()
	elseif player.vx < 0 then
		if player.sequence ~= "left" then
			player:setSequence("left")
		end
		player:play()
	else
		player:pause()

		if player.sequence == "right" then
			player:setFrame(4) --standing position right
		elseif player.sequence == "left" then
			player:setFrame(4) --standing position left
		end
	end
end

local function updateEnemy(object)
	if object.moveAxis == 0 then
		object:setLinearVelocity(object.vel, 0)
	elseif object.moveAxis == 1 then
		object:setLinearVelocity(0, object.vel)
	end

	object:rotate(object.vel / 50) --rotate depending on movement direction
end

local function updateDTile(object)
	if object.validContact then --if the player is on top
		object.linearDamping = 10
		if object.onGround then
			object:setLinearVelocity(0, 0)
		else
			object:setLinearVelocity(0, 150)
		end

		if not player.isJumping then --keep player on tile
			if player.isOn["UpTile"] < 1 and player.isOn["StdTile"] < 1 then --prevent DownTile "pulling" the player off of a tile
				player.y = object.y - 30
				player.gravityScale = 0
			end

			if player.isOn["UpTile"] < 1 and player.isOn["StdTile"] < 1 and player.isOn["DownTile"] == 2 then
				object.y = player.y + 30
			end
		end

	elseif object.y > object.origY then --if the player is not on the tile move up until back at origin pos
		object.bodyType = "dynamic"
		timer.performWithDelay(10, function() object:setLinearVelocity(0, -150); end)
		if player.onGround == 0 then player.gravityScale = 1; end --reset player gravity
	else
		object:setLinearVelocity(0, 0) --when at origin pos, stop
		object.y = object.origY --small realignment
		object.bodyType = "static"
		if player.onGround == 0 then player.gravityScale = 1; end --reset player gravity
	end

	object.x = object.origX --tile must stay fixed on x axis
end

local function updateUTile(object)
	if object.validContact then --if the player is on the til
		object.linearDamping = 10
		object:setLinearVelocity(0, -200) --move up

		if not player.isJumping then --stop player gravity if it is not trying to jump
			player.y = object.y - 31
			player.gravityScale = 0
		end
	elseif object.y < object.origY then --otherwise, move down
		object:setLinearVelocity(0, 200)
		if player.onGround == 0 then player.gravityScale = 1 end
	end

	if object.y > object.origY - 1 and not object.validContact then
		object.y = object.origY
		object.bodyType = "static"
		if player.onGround == 0 then player.gravityScale = 1 end
	end

	if object.y > object.origY then --stop at the original position
		object.y = object.origY
		object:setLinearVelocity(0, 0)
		object.bodyType = "static"
		if player.onGround == 0 then player.gravityScale = 1 end
	end

	object.x = object.origX --keep the tile on it's x axis
end

local function updateFlameThrower(object)
	for i = 1, 25 do
		object.fire[i]:translate(object.fire[i].velocity.x, object.fire[i].velocity.y)

		--reset the fire after it travels 32 pixels
		if object.orientation == 0 then
			if object.fire[i].x - object.fire[i].stX >= 32 then object.fire[i].x = object.fire[i].stX; object.fire[i].y = object.fire[i].stY; end
		elseif object.orientation == 90 then
			if object.fire[i].y - object.fire[i].stY >= 32 then object.fire[i].x = object.fire[i].stX; object.fire[i].y = object.fire[i].stY; end
		elseif object.orientation == 180 then
			if object.fire[i].x - object.fire[i].stX <= -32 then object.fire[i].x = object.fire[i].stX; object.fire[i].y = object.fire[i].stY; end
		elseif object.orientation == 270 then
			if object.fire[i].y - object.fire[i].stY <= -32 then object.fire[i].x = object.fire[i].stX; object.fire[i].y = object.fire[i].stY; end
		end
	end
end

local function updateCannon(object)
	object.l2.x = player.x; object.l2.y = player.y --set the second point of the line to the player's position

	local deltaX = object.l2.x - object.l1.x; local deltaY = object.l2.y - object.l1.y --get triangle sides

	local velocity = {x = 0, y = 0}

	if not object.ball.fired then
		object.ball.fired = true

		timer.performWithDelay(1000, function(event)
			if not player.isAlive or levelComplete then --if the game is not active, cancel function
				timer.cancel(event.source)
				return
			end

			object.l2.x = player.x; object.l2.y = player.y --set the second point of the line to the player's position

			--these calculations must be updated
			local deltaX = object.l2.x - object.l1.x; local deltaY = object.l2.y - object.l1.y --get triangle sides

			--normalize cannonball velocity
			velocity.x = deltaX / math.sqrt(math.pow(deltaX, 2) + math.pow(deltaY, 2))
			velocity.y = deltaY / math.sqrt(math.pow(deltaX, 2) + math.pow(deltaY, 2))

			object.ball:setLinearVelocity(velocity.x * 150, velocity.y * 150)
		end)
	end

	local deltaAngle = math.deg(math.atan2(deltaY, deltaX)) --get angle between 0 and the player

	object.barrel.rotation = deltaAngle --set barrel rotation to delta angle
end

--call all update functions
local function updateGame()
	if not isPaused then
		for i = 1, #entities do
			if entities[i].name == "Player" then
				updatePlayer()
			elseif entities[i].name == "Enemy" then
				updateEnemy(entities[i])
			elseif entities[i].name == "DownTile" then
				updateDTile(entities[i])
			elseif entities[i].name == "UpTile" then
				updateUTile(entities[i])
			elseif entities[i].name == "FlameThrower" then
				updateFlameThrower(entities[i])
			elseif entities[i].name == "Cannon" then
				updateCannon(entities[i])
			end
		end
	end

	livesText.text = "Lives: " .. lives
	roomsCompleteText.text = "Room: " .. roomsComplete

	if not player.isAlive and not switching then
		switching = true

		lives = lives - 1

		if lives <= 0 then --end the game if the player is out of lives
			composer.setVariable("roomsComplete", roomsComplete)
			composer.setVariable("lives", lives)
			composer.setVariable("switchCause", "complete")
			endGame()
			timer.performWithDelay(100, function() composer.gotoScene("lose", "fade", 250) end) --allow for processes to finish
		else
			composer.setVariable("roomsComplete", roomsComplete)
			composer.setVariable("lives", lives)
			composer.setVariable("switchCause", "death")
			composer.setVariable("map", map)
			timer.performWithDelay(100, function() composer.gotoScene("inter", "fade", 250) end) --allow for processes to finish
		end

		--remove runtime listeners
		Runtime:removeEventListener("enterFrame", updateGame)
	elseif levelComplete and not switching then
		switching = true

		roomsComplete = roomsComplete + 1

		--add to lives if on easy
		if composer.getVariable("difficulty") == "easy" then
			lives = lives + 1
		end

		composer.setVariable("roomsComplete", roomsComplete)
		composer.setVariable("lives", lives)
		composer.setVariable("switchCause", "complete")
		timer.performWithDelay(100, function() composer.gotoScene("inter", "fade", 250); end)

		--remove runtime listeners
		Runtime:removeEventListener("enterFrame", updateGame)
	end
end
----------------------------------

function scene:create(event)
	local sceneGroup = self.view

	--ads.show("banner")

	--initialize
	local path = system.pathForFile("highScoreData.txt", system.DocumentsDirectory) --load high scores from file

	local file = io.open(path, "r")
	if file then --only execute if the file exists
		for line in file:lines() do --loop through high scores
			if line:match("%a+") == composer.getVariable("difficulty") then --if the score's difficulty matches the current difficulty
				highScore = tonumber(line:match("%d+"))--use that score
				break
			end
		end

		file:close()
	else --otherwise create a new file
		file = io.open(path, "w")
		file:write("0 easy\n")
		file:write("0 medium\n")
		file:write("0 hard\n")
		file:close()
	end

	highScore = highScore or 0 --ensure that high score has a value

	------------------------------------------------------------------------------
	background = display.newImageRect("Tiles/Background.png", 1280, 832) --the tile background
	background.x = display.contentWidth / 2; background.y = display.contentHeight / 2 - 10
	background:rotate(90)
	sceneGroup:insert(background)
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	background2 = display.newRect(display.contentCenterX, 106, 640, 640) --black backdrop over play area
	background2.anchorY = 0
	background2:setFillColor(0)
	sceneGroup:insert(background2)
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	pause = display.newImageRect("Tiles/Pause.png", 32, 32) --pause button
	pause.x = display.contentCenterX + 250; pause.y = 160
	pause:setFillColor(1, 0.7)
	pause.touch = function(self, event)
		isPaused = true
		self.justPressed = true
		timer.performWithDelay(10, function() self.justPressed = false; end)
		physics.pause() --pause physics
		audio.pause() --pause the music
		composer.showOverlay("Pause", {isModal = true, effect = "fade", time = 200, params = {resumeGame = resume}})
	end
	pause:addEventListener("touch", pause)
	sceneGroup:insert(pause)
	------------------------------------------------------------------------------

	--(saved var states not available on first load)
	lives = composer.getVariable("lives") or 20
	roomsComplete = composer.getVariable("roomsComplete") or 0

	livesText = display.newText{
		text = "Lives: " .. tostring(lives),
		x = 100,
		y = 770,
		font = native.systemFont,
		fontSize = 35,
		align = "center"
	}
	livesText:setFillColor(0, 1, 0)
	sceneGroup:insert(livesText)

	roomsCompleteText = display.newText{
		text = "Room: " .. roomsComplete,
		x = display.contentCenterX - 30,
		y = 770,
		font = native.systemFont,
		fontSize = 35,
		align = "center"
	}
	roomsCompleteText:setFillColor(1, 1, 0)
	sceneGroup:insert(roomsCompleteText)

	highScoreText = display.newText{
		text = "High Score: " .. highScore,
		x = display.contentWidth - 125,
		y = 770,
		fontSize = 35,
		align = "center"
	}
	highScoreText:setFillColor(1, 0, 0)
	sceneGroup:insert(highScoreText)

	--create the map
	map = composer.getVariable("map") or RLG.run() --give map an initial value

	local tempEntities = initEntities(sceneGroup) --initialize entities

	-- all display objects must be inserted into group
	for i = 1, #tempEntities do
		sceneGroup:insert(tempEntities[i])
	end

	initArrows() --initialize the input buttons
	sceneGroup:insert(leftArrow)
	sceneGroup:insert(rightArrow)
	sceneGroup:insert(upArrow)

	if audio.getVolume() ~= 0 then currentTrack = audio.loadStream("Music/" .. tracks[mRand(1, #tracks)]); end --load first audio track
end

function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		composer.removeScene("inter")
		composer.removeScene("menu")
		composer.removeScene("diffSelect")

		audio.resume() --ensure audio is playing

		if not audio.isChannelPlaying(1) and audio.getVolume() ~= 0 then audio.play(currentTrack, { --play background music
			channel = 1,
			loops = -1,
			fadeIn = 2000,
			onComplete = function(event)
				audio.dispose(currentTrack) --dispose of old track
				currentTrack = audio.loadStream("Music/" .. tracks[mRand(1, #tracks)]) --load new track
			end
		}); end
	elseif phase == "did" then
		physics.start()
	end
end

function scene:hide(event)
	local sceneGroup = self.view

	local phase = event.phase

	if phase == "did" then
		composer.setVariable("currTrack", currentTrack) --add global reference to allow audio to be destroyed in lose scene
		physics.stop() --stop physics
	end
end

function scene:destroy(event)
	local sceneGroup = self.view

	for i = 1, #entities do
		entities[i]:removeSelf()
		entities[i] = nil
	end

	leftArrow:removeSelf()
	leftArrow = nil

	rightArrow:removeSelf()
	rightArrow = nil

	upArrow:removeSelf()
	upArrow = nil

	package.loaded[physics] = nil
	physics = nil
end

------------------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

Runtime:addEventListener("enterFrame", updateGame)
------------------------------------------------------------------------------------------

return scene
