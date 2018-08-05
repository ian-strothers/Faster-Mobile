--This scene overlays a pause menu

--include scene library and button library
composer = require("composer") 
scene = composer.newScene()

local background
local resume
local quit

function scene:create(event)
	local sceneGroup = self.view
	
	background = display.newRect(0, 0, display.contentWidth, display.contentHeight) --create black backdrop for the overlay
	background.anchorX = 0; background.anchorY = 0
	background:setFillColor(0, 0.8)
	sceneGroup:insert(background)

	resume = display.newText{ --the resume button
		text = "Resume",
		font = "Georgia-BoldItalic",
		fontSize = 40,
		x = display.contentWidth / 2, y = 400,
	}
	sceneGroup:insert(resume)
	
	quit = display.newText{ --the quit button
		text = "Quit",
		font = "Georgia-BoldItalic", 
		fontSize = 40,
		x = display.contentWidth / 2, y = 500,
	}
	sceneGroup:insert(quit)
end

function scene:show(event)
	local sceneGroup = self.view
	local parent = event.parent
	
	if event.phase == "will" then	
		resume.touch = function() --resume the game
			composer.hideOverlay("fade", 200)
			event.params.resumeGame()
		end
		resume:addEventListener("touch", resume)
		
		quit.touch = function() --quit the game
			audio.stop() --stop and destroy audio
			audio.dispose()
			--composer.hideOverlay("fade", 200)
			composer.removeScene("menu")
			timer.performWithDelay(100, function() composer.gotoScene("menu", "fade", 500); end)
		end
		quit:addEventListener("touch", quit)
	end
end

--add listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)

return scene