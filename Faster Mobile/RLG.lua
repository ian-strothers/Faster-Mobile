--this module stores the game's random level gernerator
RLG = {}

RLG.blocks = { --create the predefined blocks
  {width = 1, height = 6, center = 3,
    block = {
      {1},
      {0},
      {0},
      {0},
      {0},
      {1} }},
  
  {width = 2, height = 6, center = 3,
    block = {
      {5, 5},
      {0, 0},
      {0, 0},
      {0, 0},
      {0, 0},
      {5, 5} }},
  
  {width = 2, height = 5, center = 2,
    block = {
      {8, 1},
      {0, 0},
      {0, 0},
      {0, 0},
      {1, 1} }},
      
  {width = 2, height = 5, center = 2,
  	block = {
  		{0, 0},
  		{0, 0},
  		{0, 0},
  		{0, 0},
  		{8, 1} }},
  
  {width = 1, height = 3, center = 1,
    block = {
      {0},
      {3},
      {0} }},
  
  {width = 1, height = 3, center = 1,
    block = {
      {0},
      {7},
      {1} }},
  
  {width = 3, height = 3, center = 1,
    block = {
      {0, 0, 0},
      {0, 7, 1},
      {1, 1, 1} }},
  
  {width = 2, height = 7, center = 3,
    block = {
      {6, 6},
      {0, 0},
      {0, 0},
      {0, 0},
      {0, 0},
      {0, 0},
      {6, 6} }},
  }
  
  RLG.run = function()
    local room = {}
    local line = {}
    
    -----------------------------------------------
    --setup----------------------------------------
    -----------------------------------------------
      for i = 1, 20 do --create empty room maps
        room[i] = {}
        line[i] = {}
        
        for j = 1, 20 do
          room[i][j] = 0
          line[i][j] = false
        end
      end
      
      --place spikes along floor of room
      for i = 1, 20 do
        room[19][i] = 4
      end
      
      -----------------------------------------
      --create line through room---------------
      -----------------------------------------
      line[10][2] = true --start line at player's position
      local exitPos = {0, 0} --store exit pos to prevent it being overidden
      
      local currX = 1; currY = 10 --current x and y position of the line
      local cUpMoves = 0; cDownMoves = 0 --consecutive moves in a direction
      local exitPlaced = false --whether or not the exit has been placed
      
      ---------------------------------------
      --start creating the line--------------
      ---------------------------------------
      while currX < 19 do
        local move = math.random(0, 3) --the direction that the line will move
        
        if move == 0 or move == 3 then --line moves right
          currX = currX + 1 --increment currX because line moves foreward
          
          line[currY][currX] = true --add new point to the line
        elseif move == 1 then --line moves up
          if currY > 1 then --do not allow line to move out of map
            currY = currY - 1 --currY goes down because line moves up
            cUpMoves = cUpMoves + 1 --add on to consecutive up moves
            
            if cUpMoves > 3 then --stop too many up movements in a row
              currX = currX + 1 --currX increments because line moves foreward
              cUpMoves = 0 --reset consecutive up moves
            end
            
            line[currY][currX] = true --add new point to the line
          end
        elseif move == 2 then --line moves down
          if currY <= 19 then --make sure line does not leave the map
            currY = currY + 1 --currY increments because line moves down
            cDownMoves = cDownMoves + 1 --add to consecutive down moves
            
            if cDownMoves > 3 then
              currX = currX + 1 --currX goes up one because the line moves foreward
              cDownMoves = 0 --reset consecutive down moves
            end
            
            line[currY][currX] = true --add new point to line
          end
        end
        
        if currX == 19 and not exitPlaced then --place exit tile at the end of the line
          if currY <= 19 then
            exitPos = {currX, currY}
          else
            exitPos = {currX, currY - 1}
          end
          
          exitPlaced = true
        end
      end
      
      -----------------------------------------
      --place blocks around line---------------
      -----------------------------------------
      for i = 1, 20 do --search line map
        for j = 1, 20 do
          if line[i][j] then --if the point is true
            local adjacentCounter = 0 --number of adjacent tiles a y point
            
            for k = j, math.huge do --get adjacent tiles
              if line[i][k] then --if next point is true, increment adjacentCounter
                adjacentCounter = adjacentCounter + 1
              else
                break --stop if the adjacent line ends
              end
            end
            
            local lastChoice
            
            while true do
              local blockIndex = math.random(1, #RLG.blocks) --randomly choose a block from the table
              if blockIndex == lastChoice then --make it difficult for the same block to be chosen twice
              	blockIndex = math.random(1, #RLG.blocks) --randomly choose a block from the table
              end
              
              --if the block is smaller or equal to the acjacentCounter, place it
              if RLG.blocks[blockIndex].width <= adjacentCounter then
              	lastChoice = blockIndex --save the last block index so it is not used directly afterwards
                --subtract block width from adjacentCounter
                adjacentCounter = adjacentCounter - RLG.blocks[blockIndex].width
                if adjacentCounter <= 0 then --if adjacent space is filled break
                  break
                end
                print("Block: " .. blockIndex .. " chosen.")
                
                --loop through both map and selected block
                local k1 = 1; local k2 = i - RLG.blocks[blockIndex].center
                while k1 <= RLG.blocks[blockIndex].height and k2 <= 20 do
                  local l1 = 1; local l2 = j
                  
                  while l1 <= RLG.blocks[blockIndex].width and l2 <= 20 do
                    --map the block to the room
                   if k1 >= 1 and k2 >= 1 and l1 >= 1 and l2 >= 1 then room[k2][l2] = RLG.blocks[blockIndex].block[k1][l1] end
                	 l1 = l1 + 1; l2 = l2 + 1
                  end
                  k1 = k1 + 1; k2 = k2 + 1
                end
                
                j = j + RLG.blocks[blockIndex].width --force move j forward
              end
            end
          end
        end
      end
      
      ------------------------------------------
      --clear safe area for player to spawn-----
      ------------------------------------------
      for i = 1, 18 do
      	room[i][2] = 0
      end
      
      ------------------------------------------
      --limit to one tile above and below line--
      ------------------------------------------
     --[=[ local upBlocks = {}
      local downBlocks = {}
      for i = 1, 20 do --loop through room and save all tiles on same x line
        for j = 1, 20 do
          if line[i][j] then
            local k1 = i; k2 = i
            while k1 < 20 and k2 > 1 do --save points
              if room[k1][j] == 1 then --below line
                downBlocks[#downBlocks + 1] = {k1, j}
              end
              
              if room[k2][j] == 1 then --above line
                upBlocks[#upBlocks + 1] = {k2, j}
              end
              
              k1 = k1 + 1; k2 = k2 - 1
            end
            
            for k = 1, #upBlocks - 1 do
              if room[upBlocks[k][1]][upBlocks[k][2]] then
                room[upBlocks[k][1]][upBlocks[k][2]] = 0
              end
            end
            
            for k = 1, #downBlocks - 1 do
              if room[downBlocks[k][1]][downBlocks[k][2]] then
                room[downBlocks[k][1]][downBlocks[k][2]] = 0
              end
            end
          end
        end
      end]=]
      
      ------------------------------------
      --outline room----------------------
      ------------------------------------
      for i = 1, 20 do
        for j = 1, 20 do
          --fill in first and last rows with std tiles
          if i == 1 or i == 20 then
            room[i][j] = 1
            --fill in first and last column with std tiles
          elseif j == 1 or j == 20 then
            room[i][j] = 1
          end
        end
      end
      
      ----------------------------------------------------------------------------------------------------------------------------------------
      --make sure there are no floating cannons, flamethrowers, blocked moving tiles, or spikes also remove enemies that are too constricted--
      ----------------------------------------------------------------------------------------------------------------------------------------
      for i = 1, 20 do
        for j = 1, 20 do
          --check adjacent tiles
          if room[i][j] == 4 or room[i][j] == 7 or room[i][j] == 8 then --destroy floating cannons, spikes and flamethrowers
            if room[i - 1][j] ~= 1 and room[i + 1][j] ~= 1 and 
              room[i][j - 1] ~= 1 and room[i][j + 1] ~= 1 then
              room[i][j] = 0
            end
          elseif room[i][j] == 3 then --make sure enemies have enough room to move
          	for k = i, i + 1 do
          		if k < 19 and room[k][j] == 1 or room[k][j] == 5 or room[k][j] == 6 then --clamp k to stay within map
          			room[i][j] = 0
          		end
          	end
          	
          	for k = j, j + 1 do
          		if k < 19 and room[i][k] == 1 or room[i][k] == 5 or room[i][k] == 6 then --clamp k to stay within map
          			room[i][j] = 0
          		end
          	end
          	
          	for k = i, i - 1, -1 do
          		if k > 1 and room[k][j] == 1 or room[k][j] == 5 or room[k][j] == 6 then --clamp k to stay within map
          			room[i][j] = 0
          		end
          	end
          elseif room[i][j] == 5 then --destroy DownTiles if they cannot move
          	if room[i + 1][j] ~= 0 or room[i - 1][j] ~= 0 then
          		room[i][j] = 0
          	end
          elseif room[i][j] == 6 then --replace UpTiles if the cannot move
          	if room[i - 1][j] ~= 0 then
          		room[i][j] = 1
          	end
          end
        end
      end
      
      ----------------------------------------------------------
      --create a possibility map to allow for checking----------
      ----------------------------------------------------------
      --0 cannot be pathed to, 1 = can be pathed to, 2 = dangerous, 3 = exit
      local possMap = {}
      
      for i = 1, 20 do
        possMap[i] = {}
        
        for j = 1, 20 do
          possMap[i][j] = 0
          
          --edges cannot be pathed to
          if i == 1 or i == 20 or j == 1 or j == 20 then
            possMap[i][j] = 0
          --exit tile can be pathed to but represented specially
          elseif i == exitPos[2] and j == exitPos[1] then
            possMap[i][j] = 3
          --dangerous tiles
          elseif room[i][j] == 3 or room[i][j] == 4 or room[i][j] == 7 or
            room[i][j] == 8 then
            possMap[i][j] = 2
          --safe tiles
          elseif room[i][j] == 1 or room[i][j] == 5 or room[i][j] == 6 then
            possMap[i][j] = 1
            
            --pathable tiles cannot be pathed to if there is another pathable tile 1 to the right or left of it
					--(this is done to avoid part of a roof that covers the player being considered a path)
					--(this works because if there is a pathable tile directly to the left than that tile will be pathed to)
            if (possMap[i][j - 1] == 1 and possMap[i][j + 1] == 1) and 
              (j - 1 > 1 and j + 1 < 20) then
				possMap[i][j] = 0
            end
              
            --pathable tiles cannot be pathed to if there are tiles directly above them
            --exclude blank tiles because the tile under it can still be pathed to
            if possMap[i - 1][j] == 2 or possMap[i - 1][j] == 1 then
              possMap[i][j] = 0
            end
          end
        end
      end
      -------------------
      --constants--------
      -------------------
      possMap[exitPos[2] + 1][exitPos[1]] = 1 --std tile under exit
      possMap[12][2] = 1 --std tile under player
      possMap[11][2] = 0 --player pos
      
      for i = 1, 20 do
          for j = 1, 20 do
            io.write(possMap[i][j])
          end
          io.write("\n")
      end
      
      local paths = {} --map to store paths
      for i = 1, 20 do
        paths[i] = {}
        for j = 1, 20 do
          paths[i][j] = false
        end
      end
      paths[12][2] = true --player spawn
      
      local complete = false
      while not complete do
        --loop through path map
        for i = 1, 20 do
          for j = 1, 20 do
            if paths[i][j] then
              --check if there are any valid tiles between 3 above the current path andthe spikes at the bottom of the map
              for k = i - 3, 19 do
                if k <= 1 then --clamp k to keep it in the map
                  k = 2
                end
                
                --check if there are any valid tiles between 1 right from the current path and
							   --6 right of the current path (the player's max jump width)
                for l = j + 1, j + 6 do
                  if l >= 20 then --clamp l to keep it in map
                    break 
                  end
                  
                  if possMap[k][l] == 1 then
                    paths[k][l] = true
                    paths[i][j] = false
                  elseif possMap[k][l] == 3 then
                    complete = true
                    print("path found")
                    break
                  end
                end
                if complete then break end
              end
            end
            if complete then break end
          end
          if complete then break end
        end
        if complete then
          break
        else
          print("level rejected")
          return RLG.run() --call run() recursively if the level is rejected
        end
      end
      
      --------------------------------------
      --place constants (player and exit)---
      --------------------------------------
     
    	--player and tile under it
    	room[11][2] = 2
    	room[12][2] = 1
        
    	--exit and tile under it
    	room[exitPos[2]][exitPos[1]] = 9
    	room[exitPos[2] + 1][exitPos[1]] = 1
        
    	--print room
    	for i = 1, 20 do
    		for j = 1, 20 do
        		io.write(room[i][j])
        	end
    		io.write("\n")
    	end
        
    	return room
  end

return RLG