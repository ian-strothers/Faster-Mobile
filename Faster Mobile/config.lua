if string.sub(system.getInfo("model"), 1, 4) == "iPad" then
	application = {
		content = {
			width = 768,
			height = 1024, 
			scale = "letterbox",
			fps = 60,
		
    	    imageSuffix = {
			    ["@2x"] = 2,
			    --["@15x"] = 1.5,
			}
		}    
	}
elseif string.sub(system.getInfo("model"), 1, 2) == "iP" and display.pixelHeight > 960 then
	application = {
		content = {
			width = 640,
			height = 1136, 
			scale = "letterbox",
			fps = 60,
		
    	    imageSuffix = {
			    ["@2x"] = 2,
			    --["@15x"] = 1.5,
			}
		}    
	}
elseif string.sub(system.getInfo("model"), 1, 2) == "iP" then
	application = {
		content = {
			width = 640,
			height = 960, 
			scale = "letterbox",
			fps = 60,
		
    	    imageSuffix = {
			    ["@2x"] = 2,
			    --["@15x"] = 1.5,
			}
		}    
	}
--[[elseif display.pixelHeight / display.pixelWidth > 1.72 then
	application = {
		content = {
			width = 640,
			height = 1140, 
			scale = "letterbox",
			fps = 60,
		
    	    imageSuffix = {
			    ["@2x"] = 2,
			    --["@15x"] = 1.5,
			}
		}    
	}
else
	application = {
		content = {
			width = 640,
			height = 960, 
			scale = "letterbox",
			fps = 60,
		
    	    imageSuffix = {
			    ["@2x"] = 2,
			    --["@15x"] = 1.5,
			}
		}    
	}]]
end