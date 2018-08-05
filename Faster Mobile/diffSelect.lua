--include scene library and button library
local composer = require("composer")
scene = composer.newScene()

--forward declarations
local background

local easy, medium, hard
local eExp, mExp, hExp

function scene:create(event)
	local sceneGroup = self.view

	background = display.newImageRect("Tiles/Background.png", 1280, 832)
	background.x = display.contentWidth / 2; background.y = display.contentHeight / 2
	background:rotate(90)
	sceneGroup:insert(background)
	
	easy = display.newText{
		text = "EASY",
		font = "HelveticaNeue-BoldItalic",
		fontSize = 75,
		x = display.contentCenterX, y = 250
	}
	easy.touch = function(self, event)
		if event.phase == "began" then
			composer.setVariable("difficulty", "easy")
			composer.gotoScene("GameScreen", "fade", 500)
			easy:removeEventListener("touch")
		end
	end
	easy:addEventListener("touch", easy)
	easy:setFillColor(0, 1, 0)
	
	eExp = display.newText{
		text = "Gain a life after each level",
		x = display.contentCenterX,
		y = 300,
		font = native.systemFontBold,
		fontSize = 30,
	}
	
	medium = display.newText{
		text = "MEDIUM",
		font = "HelveticaNeue-BoldItalic",
		fontSize = 75,
		x = display.contentCenterX, y = display.contentCenterY
	}
	medium.touch = function(self, event)
		if event.phase == "began" then
			composer.setVariable("difficulty", "medium")
			composer.gotoScene("GameScreen", "fade", 500)
			medium:removeEventListener("touch")
		end
	end
	medium:addEventListener("touch", medium)
	medium:setFillColor(0, 0, 1)
	
	mExp = display.newText{
		text = "Lives never come back",
		x = display.contentCenterX,
		y = display.contentCenterY + 50,
		font = native.systemFontBold,
		fontSize = 30,
	}
	
	hard = display.newText{
		text = "HARD",
		font = "HelveticaNeue-BoldItalic",
		fontSize = 75,
		x = display.contentCenterX, y = display.contentHeight - 300
	}
	hard.touch = function(self, event)
		if event.phase == "began" then
			composer.setVariable("difficulty", "hard")
			composer.setVariable("lives", 10) --set lives to half
			composer.gotoScene("GameScreen", "fade", 500)
			hard:removeEventListener("touch")
		end
	end
	hard:addEventListener("touch", hard)
	hard:setFillColor(1, 0, 0)
	
	hExp = display.newText{
		text = "You have half as many lives",
		x = display.contentCenterX,
		y = display.contentHeight - 250,
		font = native.systemFontBold,
		fontSize = 30,
	}
	
	sceneGroup:insert(easy)
	sceneGroup:insert(eExp)
	sceneGroup:insert(medium)
	sceneGroup:insert(mExp)
	sceneGroup:insert(hard)
	sceneGroup:insert(hExp)
end

function scene:show(event)
	if event.phase == "will" then
		composer.removeScene("menu")
	end
end

function scene:hide(event)
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