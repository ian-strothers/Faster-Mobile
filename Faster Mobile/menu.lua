local composer = require( "composer" )
local scene = composer.newScene()

local gameNetwork = require("gameNetwork")
--------------------------------------------

-- forward declarations and other locals
local background

local playBtn
local logoText
local scoresBtn
local tutorialBtn
local muteBtn
local muteSlash

function scene:create( event )
	local sceneGroup = self.view

	background = display.newImage("Tiles/Background.png", true)
	background.x = display.contentWidth / 2; background.y = display.contentHeight / 2
	background:rotate(90)

	logoText = display.newText{
		text = "Faster",
		x = display.contentWidth/2,
		y = display.contentHeight/2 - 100,
		font = "Didot-Italic",
		fontSize = 200,
		align = "center"
	}
	logoText:setFillColor(0, 1, 0)

	-- create a widget button (which will loads GameScreen.lua on release)
	playBtn = display.newText{
		text ="Play Game",
		font = native.systemFont,
		fontSize = 45,
		x = display.contentWidth/2, y = display.contentHeight-400
	}
	playBtn.touch = function()
		composer.gotoScene( "diffSelect", "fade", 500 )
		playBtn:removeEventListener("touch")
	end	-- event listener function
	playBtn:addEventListener("touch", playBtn)
	playBtn:setFillColor(0, 1, 1)

	scoresBtn = display.newText{
		text = "High Scores",
		font = native.systemFont,
		fontSize = 45,
		x = display.contentWidth / 2, y = display.contentHeight - 275
	}
	scoresBtn.touch = function()
		composer.gotoScene("Leaderboards", "fade", 500)
		scoresBtn:removeEventListener("touch")
	end --event listener
	scoresBtn:addEventListener("touch", scoresBtn)
	scoresBtn:setFillColor(0, 1, 1)

	tutorialBtn = display.newText{
		text = "Tutorial",
		font = native.systemFont,
		fontSize = 45,
		x = display.contentWidth / 2, y = display.contentHeight - 150
	}
	tutorialBtn.touch = function()
		composer.gotoScene("Tutorial", "fade", 500)
		tutorialBtn:removeEventListener("touch")
	end --event listener
	tutorialBtn:addEventListener("touch", tutorialBtn)
	tutorialBtn:setFillColor(0, 1, 1)

	muteBtn = display.newImageRect("Tiles/Mute.png", 32, 32)
	muteBtn.x = display.contentWidth - 50; muteBtn.y = 50
	muteBtn.tap = function()
		if audio.getVolume() == 0 then
			audio.setVolume(1)
			muteSlash.isVisible = false

			local path = system.pathForFile("mute.txt", system.DocumentsDirectory)

			local file = io.open(path, "w")
			file:write("false")
		else
			audio.setVolume(0)
			muteSlash.isVisible = true

			local path = system.pathForFile("mute.txt", system.DocumentsDirectory)

			local file = io.open(path, "w")
			file:write("true")
		end
	end
	muteBtn:addEventListener("tap", muteBtn)

	muteSlash = display.newLine(muteBtn.x - 15, muteBtn.y - 15, muteBtn.x + 15, muteBtn.y + 15)
	muteSlash:setStrokeColor(1, 0, 0)
	muteSlash.strokeWidth = 4

	local path = system.pathForFile("mute.txt", system.DocumentsDirectory)
	local file = io.open(path, "r")

	if path and file then
		if file:read("*l") == "true" then
			muteSlash.isVisible = true
			audio.setVolume(0)
		else
			muteSlash.isVisible = false
			audio.setVolume(1)
		end
	else
		muteSlash.isVisible = false
		audio.setVolume(1)
	end

	--all display objects must be inserted into group
	sceneGroup:insert(background)
	sceneGroup:insert(logoText)
	sceneGroup:insert(playBtn)
	sceneGroup:insert(scoresBtn)
	sceneGroup:insert(tutorialBtn)
	sceneGroup:insert(muteBtn)
	sceneGroup:insert(muteSlash)
end

function scene:show( event )
	if event.phase == "will" then
		--some resetting
		composer.removeScene("lose")
		composer.removeScene("Leaderboards")
		composer.removeScene("Tutorial")
		composer.removeScene("GameScreen")
		composer.removeScene("pause")
		composer.setVariable("lives", nil)
		composer.setVariable("roomsComplete", 0)
		composer.setVariable("map", false)
		composer.setVariable("difficulty", "")
	elseif event.phase == "did" then
		--initialize game center
		if composer.getVariable("loggedIn") == nil and system.getInfo("platformName") ~= "Android" --[[and system.getInfo("environment") ~= "simulator"]] then --specifically check for loggedIn's existence
			native.showAlert("Game Center", "Do you want to log into Game Center?", {"No", "Yes"}, function(event)
				if event.action == "clicked" and event.index == 2 then
					gameNetwork.init("gamecenter", function(event)
						if event.data then
							composer.setVariable("loggedIn", true)
						else
							composer.setVariable("loggedIn", false)
						end
					end)
				else
					composer.setVariable("loggedIn", false)
				end
			end)
		else
			composer.setVariable("loggedIn", false)
		end
	end
end

function scene:destroy( event )
	local sceneGroup = self.view

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.

	if creditsBtn then
		creditsBtn:removeSelf()
		creditsBtn = nil
	end

	if scoresBtn then
		scoresBtn:removeSelf()
		scoresBtn = nil
	end

	if playBtn then
		playBtn:removeSelf()
		playBtn = nil
	end

	if logoText then
		logoText:removeSelf()
		logoText = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-----------------------------------------------------------------------------------------

return scene