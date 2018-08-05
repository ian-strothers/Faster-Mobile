--include scene library and button library
local composer = require("composer")
scene = composer.newScene()

--forward declarations
local background

local player, exit, enemy, stdTile, upTile, downTile, cannon, flamethrower, arrow1, arrow2, arrow3
local playerText, exitText, obstacleText, tileText, arrowText, goodLuck

local credits
local back

function scene:create(event)
	local sceneGroup = self.view

	background = display.newImageRect("Tiles/Background.png", 1280, 832) --the tile background
	background.x = display.contentWidth / 2; background.y = display.contentHeight / 2
	background:rotate(90)
	sceneGroup:insert(background)

	--tutorial images and text---------------------------------------
	player = display.newImageRect("Tiles/TutPlayer.png", 32, 32)
	player:setFillColor(0.03, 0.78, 1)
	player:scale(1.5, 1.5)
	player.x = 150; player.y = 120
	sceneGroup:insert(player)

	playerText = display.newText{
		text = "This is you.",
		font = native.systemFont,
		fontSize = 20,
		x = 150, y = 50
	}
	sceneGroup:insert(playerText)
	-----------------------------------------------------------------
	exit = display.newImageRect("Tiles/ExitPortal.png", 20, 32)
	exit:scale(1.5, 1.5)
	exit.x = display.contentWidth - 150; exit.y = 120
	sceneGroup:insert(exit)

	exitText = display.newText{
		text = "Your goal is to reach this.",
		font = native.systemFont,
		fontSize = 20,
		x = display.contentWidth - 150, y = 50
	}
	sceneGroup:insert(exitText)
	-----------------------------------------------------------------
	arrow1 = display.newImageRect("Tiles/Arrow.png", 128, 128)
	arrow1.x = display.contentCenterX - 70; arrow1.y = 250
	arrow1:rotate(180)
	arrow1.alpha = 0.6
	sceneGroup:insert(arrow1)

	arrow2 = display.newImageRect("Tiles/Arrow.png", 128, 128)
	arrow2.x = display.contentCenterX + 70; arrow2.y = 250
	arrow2.alpha = 0.6
	sceneGroup:insert(arrow2)

	arrow3 = display.newImageRect("Tiles/UpArrow.png", 384, 128)
	arrow3.x = display.contentCenterX; arrow3.y = 400
	arrow3.alpha = 0.6
	sceneGroup:insert(arrow3)

	arrowText = display.newText{
		text = "Tap these arrows to move in the direction that they point.",
		font = native.systemFont,
		fontSize = 20,
		x = display.contentCenterX, y = 500
	}
	sceneGroup:insert(arrowText)
	-----------------------------------------------------------------
	stdTile = display.newImageRect("Tiles/StdTile.png", 32, 32)
	stdTile:scale(1.5, 1.5)
	stdTile.x = display.contentCenterX - 60; stdTile.y = 600
	sceneGroup:insert(stdTile)

	downTile = display.newImageRect("Tiles/DownTile.png", 32, 32)
	downTile:scale(1.5, 1.5)
	downTile.x = display.contentCenterX; downTile.y = 600
	sceneGroup:insert(downTile)

	upTile = display.newImageRect("Tiles/UpTile.png", 32, 32)
	upTile:scale(1.5, 1.5)
	upTile.x = display.contentCenterX + 60; upTile.y = 600
	sceneGroup:insert(upTile)

	tileText = display.newText{
		text = "These tiles are safe.",
		font = native.systemFont,
		fontSize = 20,
		x = display.contentCenterX, y = 650
	}
	sceneGroup:insert(tileText)
	-----------------------------------------------------------------
	spike = display.newImageRect("Tiles/Spike.png", 32, 32)
	spike:scale(1.5, 1.5)
	spike.x = display.contentCenterX - 90; spike.y = 750
	sceneGroup:insert(spike)

	enemy = display.newImageRect("Tiles/Enemy.png", 32, 32)
	enemy:scale(1.5, 1.5)
	enemy.x = display.contentCenterX - 30; enemy.y = 750
	sceneGroup:insert(enemy)

	flamethrower = display.newImageRect("Tiles/FlameThrower.png", 32, 32)
	flamethrower:scale(1.5, 1.5)
	flamethrower.x = display.contentCenterX + 30; flamethrower.y = 750
	sceneGroup:insert(flamethrower)

	cannon = display.newImageRect("Tiles/CannonBarrel.png", 28, 32)
	cannon:scale(1.5, 1.5)
	cannon.x = display.contentCenterX + 90; cannon.y = 750
	sceneGroup:insert(cannon)

	obstacleText = display.newText{
		text = "These tiles will kill you.",
		font = native.systemFont,
		fontSize = 20,
		x = display.contentCenterX; y = 800
	}
	sceneGroup:insert(obstacleText)
	-----------------------------------------------------------------

	back = display.newText{
		text = "Back",
		font = native.systemFont,
		fontSize = 30,
		x = 40, y = display.contentHeight - ((100) + 20) --set y to just above the ad height or screenHeight - 90
	}
	back.touch = function()
		composer.gotoScene("menu", "fade", 500)
		back:removeEventListener("touch")
	end --event listener
	back:addEventListener("touch", back)
	back:setFillColor(0, 1, 0)
	sceneGroup:insert(back)
end

function scene:show(event)
	if event.phase == "will" then
		composer.removeScene("menu")
	elseif event.phase == "did" then
	end
end

function scene:destroy(event)
	local sceneGroup = self.view

	if back then
		back:removeSelf()
		back = nil
	end

	if credits then
		credits:removeSelf()
		credits = nil
	end
end

--add listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene