--include scene library
local composer = require("composer")
scene = composer.newScene()

--local ads = require("ads")

composer.removeScene("GameScreen")

--forward declarations
local loseText, loseTextExp
local okay

function scene:create(event)
	local sceneGroup = self.view

	loseText = display.newText{
		text = "You Lose!",
		x = display.contentWidth / 2, y = display.contentHeight / 2,
		font = native.getFontNames()[math.random(1, 199)],
		fontSize = 50
	}
	loseText:setFillColor(math.random(0, 255) / 255, math.random(0, 255) / 255, math.random(0, 255) / 255) --random color
	sceneGroup:insert(loseText)

	loseTextExp = display.newText{
		text = "You survived: " .. composer.getVariable("roomsComplete") .. " rooms.",
		x = display.contentWidth / 2, y = display.contentHeight / 2 + 100,
		font = native.systemFont,
		fontSize = 25
	}
	if composer.getVariable("roomsComplete") == 1 then loseTextExp.text = loseTextExp.text:gsub("rooms", "room") end
	sceneGroup:insert(loseTextExp)

	okay = display.newText{
		text = "Okay",
		font = native.systemFont,
		fontSize = 30,
		x = 75, y = display.contentHeight - ((100) + 20) --set y to just above the ad height or screenHeight - 90
	}
	okay.touch = function()
		composer.gotoScene("menu", "fade", 500)
		okay:removeEventListener("touch")
	end	-- event listener function
	okay:addEventListener("touch", okay)
	okay:setFillColor(0, 1, 0)
	sceneGroup:insert(okay)
end

function scene:show(event)
	if event.phase == "did" then
		--some reseting
		composer.setVariable("lives", 20)
		composer.setVariable("roomsComplete", 0)

		--ads.show("banner", {x = 0, y = display.contentHeight - 50, interval = 30}) --show ad
	end
end

function scene:hide(event)
	if event.phase == "did" then
		audio.stop() --force stop audio
		--ads.hide()
		--ads.setCurrentProvider("admob") --reset the current app provider if it failed previously
	end
end

function scene:destroy(event)
	audio.dispose(composer.getVariable("currTrack")) --destroy track
end

--add listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene