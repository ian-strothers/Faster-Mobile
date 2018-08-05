--include scene library and button library
composer = require("composer")
scene = composer.newScene()

--local ads = require("ads")

--forward declarations
local background

local leaderboard
local back

function scene:create(event)
	local sceneGroup = self.view

	--ads.show("banner", {x = 0, y = display.contentHeight - 50, interval = 30}) --show ad

	background = display.newImage("Tiles/Background.png", display.contentWidth / 2, display.contentHeight / 2)
	background:rotate(90)
	sceneGroup:insert(background)

	leaderboards = display.newText{
		text = "Scores:",
		x = display.contentWidth / 2, y = 150,
		font = native.getFontNames()[196],
		fontSize = 50,
		align = "center"
	}

	local scores = {} --stores score text
	local path = system.pathForFile("highScoreData.txt", system.DocumentsDirectory) --load high scores from file

	local file = io.open(path, "r")

	if file then
		local i = 1
		for line in file:lines() do --create the text based on data from files
			if i <= 5 then
				scores[#scores + 1] = display.newText{
		 			text = i .. ": " .. string.upper(line),
		 			x = display.contentWidth / 2 - 80, y = 80 * i + 150,
		 			font = native.systemFont,
		 			fontSize = 30,
	     		}
	     		scores[#scores]:setFillColor((math.random(0, 255) + 128) / 255, (math.random(0, 255) + 128) / 255, (math.random(0, 128) + 128) / 255) --random color
	     		scores[#scores].anchorX = 0

	     		sceneGroup:insert(scores[#scores])

	     		i = i + 1 --i must be manually incremented
	    	end
		end

		file:close()
	end

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

	sceneGroup:insert(leaderboards)
	sceneGroup:insert(back)
end

function scene:show(event)
	if event.phase == "will" then
		composer.removeScene("menu")
	elseif event.phase == "did" then
	end
end

function scene:hide(event)
	if event.phase == "did" then
		--ads.hide()
		--ads.setCurrentProvider("admob") --reset the current app provider if it failed previously
	end
end

function scene:destroy(event)
	sceneGroup = self.view

	if back then
		back:removeSelf()
		back = nil
	end

	if leaderboards then
		leaderboards:removeSelf()
		leaderboards = nil
	end
end

--add listeners
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene