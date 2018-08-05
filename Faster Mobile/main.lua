-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include the Corona "composer" module
local composer = require("composer")
local audio = require("audio")

-- set the audio mix mode to allow sounds from the app to mix with other sounds from the device
audio.setSessionProperty(audio.MixMode, audio.AmbientMixMode)

--multitouch must be activated
system.activate("multitouch")

math.randomseed(os.time())

-- load menu screen
composer.gotoScene("menu")