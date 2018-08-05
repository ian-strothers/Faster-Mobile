--This scene acts as an intermediary to destroy and reset "GameScreen" after death or level completion

--include scene library and button library
composer = require("composer") 
scene = composer.newScene()

ads = require("ads")

RLG = require("RLG")

function scene:show(event)
	if event.phase == "did" then
		composer.removeScene("GameScreen")
		if composer.getVariable("switchCause") == "complete" then
			composer.setVariable("map", RLG.run())
		end

		composer.gotoScene("GameScreen", "fade", 500)
	end
end

--add listeners
scene:addEventListener("show", scene)

return scene