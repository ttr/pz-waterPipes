
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)
-- wierd hack to make gametime calls work

WaterPipe = {};

-- list of our pipes in the world
WaterPipe.pipes = {};

-- where data are saved
WaterPipe.modData = nil;

WaterPipe.doSort = true;
WaterPipe.fertilizedBarrels = {};
 
-- time management
WaterPipe.previousHour = 0;
WaterPipe.hourElapsedForWater = 0;

-- to prevent removing of a pipe while updating (every 2 hours in game)
WaterPipe.lock = false;


function WaterPipe.loadTextures()
	getTexture('WaterPipe.png');
	getTexture('PipeCornerNE.png');
	getTexture('PipeCornerNW.png');
	getTexture('PipeCornerSE.png');
	getTexture('PipeCornerSW.png');
	getTexture('PipeCross.png');
	getTexture('PipeNorth.png');
	getTexture('PipeSE.png');
	getTexture('PipeTN.png');
	getTexture('PipeTS.png');
	getTexture('PipeTE.png');
	getTexture('PipeTW.png');
end

function WaterPipe.init()
	if isClient() then return; end
	local sec = math.floor(GameTime:getInstance():getTimeOfDay() * 3600);
	local currentHour = math.floor(sec / 3600);
	WaterPipe.previousHour = currentHour;
end

Events.OnGameBoot.Add(WaterPipe.loadTextures);
Events.OnGameStart.Add(WaterPipe.init);


function WaterPipe.saveData(pipe)
	for i=1, #WaterPipe.modData.waterPipes.pipes do
		local data = WaterPipe.modData.waterPipes.pipes[i]
		
		if pipe.x == data.x and pipe.y == data.y and pipe.z == data.z then
			for key, val in pairs(pipe) do
				WaterPipe.modData.waterPipes.pipes[i][key] = val;
			end
			break
		end
	end
end

function WaterPipe.convertOldModData()
	if WaterPipe.modData.waterPipes and WaterPipe.modData.waterPipes.pipes then return end
	WaterPipe.modData.waterPipes = {}
	WaterPipe.modData.waterPipes.pipes = {}
end

function WaterPipe.loadPipes()
	if isClient() then return; end
	
	WaterPipe.modData = GameTime:getInstance():getModData();

	-- convert old barrels
	WaterPipe.convertOldModData()
	
	if #WaterPipe.pipes ~= 0 then print("function loadPipes : SOMETHING IS WRONG") return end
	
	WaterPipe.pipes = {}
	
	for i=1, #WaterPipe.modData.waterPipes.pipes do
		table.insert(WaterPipe.pipes, WaterPipe.modData.waterPipes.pipes[i])
	end
	
	print("WaterPipes: " .. #WaterPipe.modData.waterPipes.pipes .. " loaded");
end

Events.OnGameStart.Add(WaterPipe.loadPipes);
Events.OnGameTimeLoaded.Add(WaterPipe.loadPipes);
Events.OnGameBoot.Add(WaterPipe.loadPipes);
-----

-- load the pipe
function WaterPipe.loadPipe(pipeObject)
	if not pipeObject or not pipeObject:getSquare() then return end
	local square = pipeObject:getSquare()
	local pipe = nil;
	-- check if we don't already have this pipe in our map (the streaming of the map make the gridsquare to reload every time)
	for i,v in ipairs(WaterPipe.pipes) do
		if v.x == square:getX() and v.y == square:getY() and v.z == square:getZ() then
			pipe = v;
			break;
		end
	end
	if not pipe then -- if we don't have the pipe, it's basically when you load your saved game the first time
		pipe = {};
		pipe.x = square:getX();
		pipe.y = square:getY();
		pipe.z = square:getZ();
		pipe.pipeType = pipeObject:getModData()["pipeType"];
		pipe.infinite = pipeObject:getModData()["infinite"];
		
		table.insert(WaterPipe.pipes, pipe);
		table.insert(WaterPipe.modData.waterPipes.pipes, pipe);
		
		print("pipe : new pipe created " .. pipe.x .. "," .. pipe.y);
	else
		pipeObject:getModData()["infinite"] = pipe.infinite;
		pipeObject:transmitModData();
		print("pipe : found existing pipe " .. pipe.x .. "," .. pipe.y);
	end
end

-- Called when the client adds an object to the map (which it shouldn't be able to)
WaterPipe.OnObjectAdded = function(object)
	if isClient() then return end
	if not object then return end
	if object:getName() == "WaterPipe" then
		WaterPipe.loadPipe(object)
	end
end
Events.OnObjectAdded.Add(WaterPipe.OnObjectAdded)


function WaterPipe.LoadGridsquare(square)
    if isClient() then return; end
	-- does this square have a pipe ?
	for i=0,square:getObjects():size() - 1 do
		local obj = square:getObjects():get(i)
		if obj:getName() == "WaterPipe" then
			WaterPipe.loadPipe(obj)
			break
		end
	end
end

Events.LoadGridsquare.Add(WaterPipe.LoadGridsquare);

-------------------------------------

function WaterPipe.findBarrelObject(square)
	for i=0,square:getSpecialObjects():size()-1 do
		local object = square:getSpecialObjects():get(i)
		if object:getName() == "Rain Collector Barrel" then
			return object
		end
	end
	return nil
end

function WaterPipe.getBarrelAt(x,y,z)
	if isClient() then return nil end
	local barrelsystem = SRainBarrelSystem.instance
	for i=1, barrelsystem:getLuaObjectCount() do
		local vCur = barrelsystem:getLuaObjectByIndex(i)
		if vCur.x == x and vCur.y == y and vCur.z == z then
			-- print("WaterPipe.getBarrelAt : barrel found")
			return vCur
		end
	end
	-- print("WaterPipe.getBarrelAt : no barrel found")
	return nil
end

function WaterPipe.getCurrentBarrel(square)
	if square == nil then
		square = getPlayer():getCurrentSquare()
	end
	if isClient() then
		local object = WaterPipe.findBarrelObject(square)
		if object then
			-- print("barrel object found, creating barrel")
			local barrel = {}
			barrel.x = square:getX()
			barrel.y = square:getY()
			barrel.z = square:getZ()
			barrel.waterAmount = object:getModData()["waterAmount"]
			barrel.waterMax = object:getModData()["waterMax"]
			barrel.fertilizerLvl = object:getModData()["fertilizerLvl"]
			barrel.decimalPart = object:getModData()["decimalPart"]
			
			return barrel
		end
		return nil
	end
	return WaterPipe.getBarrelAt(square:getX(), square:getY(), square:getZ())
end

-----
function WaterPipe.getPipeAt(x,y,z)
	if isClient() then return nil end
	for iCur,vCur in pairs(WaterPipe.pipes) do
		if vCur.x == x and vCur.y == y and vCur.z == z then
			-- print("server found pipe")
			return vCur
		end
	end
	return nil
end

function WaterPipe.findPipeObject(square)
	if square ~= nil and square:getObjects() ~= nil and square:getObjects():size() ~= nil then
		for i=0,square:getObjects():size()-1 do
			local object = square:getObjects():get(i)
			if object:getName() == "WaterPipe" then
				return object
			end
		end
		return nil
	end
	return nil
end

function WaterPipe.getCurrentPipe(square)
	if square == nil then
		square = getPlayer():getCurrentSquare()
	end
	if isClient() then
		local object = WaterPipe.findPipeObject(square)
		if object then
			-- print("pipe object found, creating pipe")
			-- Client doesn't have a list of plants, just make a new one each time
			local pipe = {}
			pipe.x = square:getX();
			pipe.y = square:getY();
			pipe.z = square:getZ();
			pipe.pipeType = object:getModData()["pipeType"]
			pipe.infinite = object:getModData()["infinite"]
			
			return pipe
		end
		return nil
	end
	return WaterPipe.getPipeAt(square:getX(), square:getY(), square:getZ())
end



-------------------------------------------

function WaterPipe.updateBarrel(b, waterPerCluster, waterNeededPerCluster, barrelsNb, fertilizerLvl, fillBarrels)
	local max40 = false;
	local ret = fertilizerLvl;
	
	local square = getWorld():getCell():getGridSquare(b.x, b.y, b.z);
		
	if waterPerCluster == -1 then
		b.waterAmount = 0;
	elseif waterPerCluster >= waterNeededPerCluster or fillBarrels then
		local decimalPart = 0;
		local newLevel = 0;
				
		if fillBarrels then
			-- we just level the barrels here, we have infinite water
			-- newLevel = (( waterPerCluster ) * 1.0 ) / ( barrelsNb * 1.0 );
			-- add 100 water per barrel if infinite source in connex comp
			-- if waterNeededPerCluster == 0 then
				newLevel = b.waterMax;
			-- end
		else
			-- harmonize water level
			newLevel = (( waterPerCluster - waterNeededPerCluster ) * 1.0 ) / ( barrelsNb * 1.0 );
		end
		
		if season.weather == "sunny" then
			newLevel = newLevel - 0.1;
		end
		
		-- check for already present decimal part
		if b.decimalPart then
			-- already added when going through waterPerCluster
			-- newLevel = newLevel + b.decimalPart
			b.decimalPart = 0
		end
		
		-- can we add it all ?
		decimalPart = newLevel - math.floor(newLevel);	
		newLevel = math.floor(newLevel);
		-- rounding errors
		if decimalPart <= 1e-6 then
			decimalPart = 0
		end
		
		-- remember decimal part for next update
		if decimalPart > 0 then
			if b.decimalPart then
				b.decimalPart = b.decimalPart + decimalPart
			else
				b.decimalPart = decimalPart
			end
		end
		
		if newLevel > 0 then
			b.waterAmount = newLevel;
			-- ttr note - re-do this to not look for 40 but check if max <  amount.
			if b.waterMax == 40 and b.waterAmount > 40 then
				max40 = true;
				-- if fertilizerLvl == 0 then
					-- return;
				-- end
			end
			
			if b.waterAmount > b.waterMax then
				b.waterAmount = b.waterMax;
			end
		else
			b.waterAmount = 0;
		end
		
		
		-- print("test for fertilizer, global level is " .. fertilizerLvl);
		-- fertilizer
		if fertilizerLvl > 0 and b.fertilizerLvl ~= nil then
			-- print("fertilize plant, lvl = " .. b.fertilizerLvl);
			if b.fertilizerLvl <= fertilizerLvl then
				ret = fertilizerLvl - b.fertilizerLvl;
				b.fertilizerLvl = 0;
			else
				b.fertilizerLvl = b.fertilizerLvl - fertilizerLvl;
				ret = 0;
			end
			-- print("new level = " .. b.fertilizerLvl);
		end
		
	elseif waterPerCluster == -2 then
		b.waterAmount = 40;
	end
	
	if square then -- we're in the real map
		local barrelsystem = SRainBarrelSystem.instance
		local obj = barrelsystem:getIsoObjectOnSquare(square)
		if obj then
			if b.fertilizerLvl then
				obj:getModData()["fertilizerLvl"] = b.fertilizerLvl
			end
			if b.decimalPart then
				obj:getModData()["decimalPart"] = b.decimalPart
			end
			-- why we need two places? oh, pz39, thats why, also double/float
			obj:getModData()["clusterWaterLevel"] = waterPerCluster;
			b.clusterWaterLevel = waterPerCluster * 1.0;
			obj:setWaterAmount(b.waterAmount) -- will trigger sprite change and saveData
			obj:transmitModData()
		end
	end
	
	return max40, ret;
end



function WaterPipe.getTypeIdx(pipeType)
	if pipeType == "lineOption" then
		return 2;
	elseif pipeType == "lineOption2" then
		return 1;
	elseif pipeType == "crossOption" then
		return 3;
	elseif pipeType == "neOption" then
		return 4;
	elseif pipeType == "nwOption" then
		return 5;
	elseif pipeType == "seOption" then
		return 6;
	elseif pipeType == "swOption" then
		return 7;
	elseif pipeType == "tnOption" then
		return 8;
	elseif pipeType == "tsOption" then
		return 9;
	elseif pipeType == "teOption" then
		return 10;
	elseif pipeType == "twOption" then
		return 11;
	elseif pipeType == "barrel" then
		return 12;
	else
		print("pipeType SHOULD NEVER HAPPEN");
	end
end

-- only pipeTypeIdxB can be 12 (a barrel), not pipeTypeIdxA
function WaterPipe.areConnected(pipeTypeIdxA, pipeTypeIdxB, xA, yA, xB, yB, z)
	-- pos of A compared to B
	local square_pos;
	
	-- north
	if yA < yB then
		square_pos = 1;
	-- south
	elseif yA > yB then
		square_pos = 2;
	-- east
	elseif xA > xB then
		square_pos = 3;
	-- west
	elseif xA < xB then
		square_pos = 4;
	-- same pos (should never happen)
	else

		print("WaterPipe.areConnected : TWO ITEMS ON SAME SQUARE: " .. pipeTypeIdxA .. " " .. pipeTypeIdxB .. " " .. xA .. " " .. yA .. " " .. z);
		if pipeTypeIdxA == 12 then -- A is barrel, delete B
			local square = getWorld():getCell():getGridSquare(xB, yB, z);
			local pipeObject = WaterPipe.findPipeObject(square)
			if square and pipeObject ~= nil then
			   print("WaterPipe.areConnected : sprite found - deleting single object");
			   Pipe.pipeRemoveTile(pipeObject);
			else
				print("WaterPipe.areConnected : sprite not found, detelint all references in pipe network - might take a while");
				Pipe.pipeRemove(xB, yB, z, false);
			end
		elseif pipeTypeIdxB == 12 then  -- B is barrel, delete A
			local square = getWorld():getCell():getGridSquare(xA, yA, z);
			local pipeObject = WaterPipe.findPipeObject(square)
			if square and pipeObject ~= nil then
			   print("WaterPipe.areConnected : sprite found - deleting single object");
			   Pipe.pipeRemoveTile(pipeObject);
			else
				print("sprite not found, detelint all references in pipe network - might take a while");
				Pipe.pipeRemove(xA, yA, z, false);
			end
		else --both elemts are pipes / delete both
			local square = getWorld():getCell():getGridSquare(xA, yA, z);
			local pipeObject = WaterPipe.findPipeObject(square)
			if square and pipeObject ~= nil then
			   print("WaterPipe.areConnected : sprite found -> deleted");
			   Pipe.pipeRemoveTile(pipeObject);
			end
		print("WaterPipe.areConnected : removing all mod entries to broken square");
		Pipe.pipeRemove(xA, yA, z, false);
		end
	end

	if square_pos == 1 then
		-- print(pipeTypeIdxA .. " north of " .. pipeTypeIdxB);
		if ( pipeTypeIdxA == 1 or pipeTypeIdxA == 3 or pipeTypeIdxA == 4 or pipeTypeIdxA == 5 or pipeTypeIdxA == 9 or pipeTypeIdxA == 10 or pipeTypeIdxA == 11 ) and ( pipeTypeIdxB == 1 or pipeTypeIdxB == 3 or pipeTypeIdxB == 6 or pipeTypeIdxB == 7 or pipeTypeIdxB == 8 or pipeTypeIdxB == 10 or pipeTypeIdxB == 11 or pipeTypeIdxB == 12 ) then
			return true;
		else
			return false;
		end
	elseif square_pos == 2 then
		-- print(pipeTypeIdxA .. " south of " .. pipeTypeIdxB);
		if ( pipeTypeIdxB == 1 or pipeTypeIdxB == 3 or pipeTypeIdxB == 4 or pipeTypeIdxB == 5 or pipeTypeIdxB == 9 or pipeTypeIdxB == 10 or pipeTypeIdxB == 11 or pipeTypeIdxB == 12 ) and ( pipeTypeIdxA == 1 or pipeTypeIdxA == 3 or pipeTypeIdxA == 6 or pipeTypeIdxA == 7 or pipeTypeIdxA == 8 or pipeTypeIdxA == 10 or pipeTypeIdxA == 11 ) then
			return true;
		else
			return false;
		end
	elseif square_pos == 3 then
		-- print(pipeTypeIdxA .. " east of " .. pipeTypeIdxB);
		if ( pipeTypeIdxB == 2 or pipeTypeIdxB == 3 or pipeTypeIdxB == 5 or pipeTypeIdxB == 7 or pipeTypeIdxB == 8 or pipeTypeIdxB == 9 or pipeTypeIdxB == 10 or pipeTypeIdxB == 12 ) and ( pipeTypeIdxA == 2 or pipeTypeIdxA == 3 or pipeTypeIdxA == 4 or pipeTypeIdxA == 6 or pipeTypeIdxA == 8 or pipeTypeIdxA == 9 or pipeTypeIdxA == 11 ) then
			return true;
		else
			return false;
		end
	elseif square_pos == 4 then
		-- print(pipeTypeIdxA .. " west of " .. pipeTypeIdxB);
		if ( pipeTypeIdxB == 2 or pipeTypeIdxB == 3 or pipeTypeIdxB == 4 or pipeTypeIdxB == 6 or pipeTypeIdxB == 8 or pipeTypeIdxB == 9 or pipeTypeIdxB == 11 or pipeTypeIdxB == 12 ) and ( pipeTypeIdxA == 2 or pipeTypeIdxA == 3 or pipeTypeIdxA == 5 or pipeTypeIdxA == 7 or pipeTypeIdxA == 8 or pipeTypeIdxA == 9 or pipeTypeIdxA == 10 ) then
			return true;
		else
			return false;
		end
	end
	
	print("WaterPipe.areConnected : SHOULD NEVER HAPPEN !");
	return false;
end



------
function WaterPipe.buildAdjMatrix(mat)
	-- matrix is symmetrical, so we build half then fill symmetrical elements
	for id, apipe in ipairs(WaterPipe.pipes) do
		local vect = {};
		
		local idx = WaterPipe.getTypeIdx(apipe.pipeType);
		
		local xA = apipe.x;
		local yA = apipe.y;
		local zA = apipe.z;
		
		-- print("pipe " .. id .. " at " .. xA .. ", " .. yA .. " connected to : ");
				
		for id2, apipe2 in ipairs(WaterPipe.pipes) do
			-- that way, areConnected is called 2 times less
			if id < id2 then
			    local zB = apipe2.z;
				local xB = apipe2.x;
				local yB = apipe2.y;

				if math.abs(xA-xB)+math.abs(yA-yB) <= 1.1 and zA == zB then
					local idx2 = WaterPipe.getTypeIdx(apipe2.pipeType);

					if WaterPipe.areConnected(idx, idx2, xA, yA, xB, yB, zA) then
						table.insert(vect, id2);
						-- print("pipe " .. id2 .. " at " .. xB .. ", " .. yB);
					end
				end
			end
		end
		
		table.insert(mat, vect);
	end

	-- fill missing elements
	-- needed for quicker accessES later
	for id, apipe in ipairs(WaterPipe.pipes) do
		for _, id2 in ipairs(mat[id]) do
			table.insert(mat[id2], id);
		end
	end
end


----
function WaterPipe.addNeighbours(pipeId, cluster, adj)
	for i, j in ipairs(adj[pipeId]) do
		if cluster[j] == 'ok' then
		else
			cluster[j] = 'ok';
			-- print("add neighbour " .. j);
			WaterPipe.addNeighbours(j, cluster, adj);
		end
	end
end

------
function WaterPipe.buildClusters(mat, clusters)
	for k, v in ipairs(mat) do
		-- print("looking at pipe " .. k);
		local done = false;
		-- is pipe at idx k of matrix in a cluster
		for kk, vv in pairs(clusters) do
			if kk[k] == 'ok' then
				-- print("already in a cluster");
				done = true;
				break;
			end
		end
		
		-- not in a cluster, add our neighbours, and their neighbours neighbours ...
		-- we should check for water source here and during recursion
		if not done then
			-- print("new cluser");
			local cluster = {};
			cluster[k] = 'ok';
			
			-- recursion with addNeighbours
			for _, j in ipairs(v) do
				if cluster[j] == 'ok' then
				else
					-- print("add neighbour " .. j);
					cluster[j] = 'ok';
					WaterPipe.addNeighbours(j, cluster, mat);
				end
			end
			
			-- no water source yet
			-- here we should store as value a list of rain collector barrels connected to the cluster
			clusters[cluster] = {};
		end
	end
end


----
function WaterPipe.buildWaterSources(cbarrels)
	for id, apipe in ipairs(WaterPipe.pipes) do	
		local sources = {};
		
		local idx = WaterPipe.getTypeIdx(apipe.pipeType);
		
		local xA = apipe.x;
		local yA = apipe.y;
		local zA = apipe.z;
		local barrelsystem = SRainBarrelSystem.instance
		for i=1, barrelsystem:getLuaObjectCount() do
			local v = barrelsystem:getLuaObjectByIndex(i)
			-- add barrels with or without water (to fusion clusters)
			if math.abs(xA-v.x)+math.abs(yA-v.y) <= 1.1 and zA == v.z then
				local idx2 = WaterPipe.getTypeIdx("barrel");
				
				if WaterPipe.areConnected(idx, idx2, xA, yA, v.x, v.y, zA) then
					table.insert(sources, v);
				end
			end
		end
		
		table.insert(cbarrels, sources);
	end
end


---
function WaterPipe.buildClustersSources(clusters, cbarrels)
	-- find our cluster and add the water source to corresponding cluster
	for id, apipe in ipairs(WaterPipe.pipes) do
		for k, v in pairs(clusters) do
			if k[id] == 'ok' then
				for pos, barrel in ipairs(cbarrels[id]) do
					local exist = false;
					local x = barrel.x;
					local y = barrel.y;
					local z = barrel.z;
					for idx, b in ipairs(v) do
						if b.x == x and b.y == y and b.z == z then
							exist = true;
							break;
						end
					end
					
					if exist then					
					else
						table.insert(v, barrel);
					end
					-- if v[barrel] == "source" then
					-- else
						-- v[barrel] = "source";
					-- end
				end
				break;
			end
		end
	end
end


----
function WaterPipe.buildPlantsAdj(planting)
	for id, apipe in ipairs(WaterPipe.pipes) do
		local xA = apipe.x;
		local yA = apipe.y;
		local zA = apipe.z;
		
		local plants = {};
		
		-- the square may not be available, so we go through all plantings
		local farmsystem = SFarmingSystem.instance
		for i=1, farmsystem:getLuaObjectCount() do
			local plant = farmsystem:getLuaObjectByIndex(i)
			-- around, or on square ?
			-- for now on square, easier to make sure in game that each plant is watered only once
			-- you need double pipes to cover the same area than when water spreads all around
			-- in this case there can only be one plant
			-- we should check there is really a plant
			if plant.state ~= "plow" and math.abs(xA-plant.x)+math.abs(yA-plant.y) <= 0.1 and zA == plant.z then --1.1 -- all around
				table.insert(plants, plant);
				break; -- comment this line if water spreads all around
			end
		end
		
		table.insert(planting, plants);
	end
end


----
function WaterPipe.buildClusterWaterNeeds(clusters, planting, waterPerCluster, fertilizerPerCluster, infiniteClusterSource)
	for kk, vv in pairs(clusters) do
		for _, barrel in ipairs(vv) do			
			
			waterAmount = barrel.waterAmount;
			
			-- decimalPart because of integers only for barrel waterAmount
			if barrel.decimalPart then
				waterAmount = waterAmount + barrel.decimalPart
			end
			
			if waterPerCluster[kk] then
				waterPerCluster[kk] = waterPerCluster[kk] + waterAmount;
			else
				waterPerCluster[kk] = waterAmount;
			end
			
			----- fertilizer
			if barrel.fertilizerLvl or #WaterPipe.fertilizedBarrels > 0 then
				local playerBarrel = false;
				
				if barrel.fertilizerLvl then
					playerBarrel = true;
				else
					----
					-- get the data, we do nothing if barrel is not found
					----
					for key, barrel2 in ipairs(WaterPipe.fertilizedBarrels) do
						if barrel2.x == barrel.x and barrel2.y == barrel.y and barrel2.z == barrel.z then
							-- copy it so we can be faster next time
							barrel.fertilizerLvl = barrel2.fertilizerLvl;
							table.remove(WaterPipe.fertilizedBarrels, key);
							playerBarrel = true;
							break;
						end
					end
					
				end
				
				if playerBarrel and fertilizerPerCluster[kk] then
					fertilizerPerCluster[kk] = fertilizerPerCluster[kk] + barrel.fertilizerLvl;
				elseif playerBarrel then
					fertilizerPerCluster[kk] = barrel.fertilizerLvl;
				end
			end
		end
		
		-- no barrels case
		if waterPerCluster[kk] then
		else
			waterPerCluster[kk] = 0;
		end
		-- no fertilizer case
		if fertilizerPerCluster[kk] then
		else
			fertilizerPerCluster[kk] = 0	
		end
	end
end


function WaterPipe.waterPlants(clusters, planting, waterPerCluster, fertilizerPerCluster, infiniteClusterSource)
	-- test if there is enough water for each cluster
	for k, v in pairs(clusters) do
		if waterPerCluster[k] > 0 or infiniteClusterSource[k] == "true" then

			local stop = false;
			local waterNeeded = 0;
			for id, apipe in ipairs(WaterPipe.pipes) do
				if k[id] == 'ok' then
					for _, plant in ipairs(planting[id]) do
						if SandboxVars.WaterPipes.SmartPipes then
							if plant.waterNeededMax then
								waterNeeded = (plant.waterNeeded + plant.waterNeededMax)/2;
							else
								waterNeeded = plant.waterNeeded;
							end
							waterNeeded = math.min((waterNeeded - plant.waterLvl + 2), SandboxVars.WaterPipes.SmartPipesFillMax);
							-- print(plant.typeOfSeed .. "  " .. plant.waterLvl .. " " .. " ".. waterNeeded);
						else
							waterNeeded = 1;
						end

						if waterNeeded > 0 then
							if waterPerCluster[k] < waterNeeded then
								stop = true;
								break;
							end
							plant.waterLvl = plant.waterLvl + waterNeeded ;
							-- barrel units to plant units ratio is 5, we will use 4 to make some penalty for automaiton
							waterPerCluster[k] = waterPerCluster[k] - (waterNeeded / 4);
							local farmsystem = SFarmingSystem.instance;
							plant.lastWaterHour = farmsystem.hoursElapsed;
							plant:saveData();
						elseif SandboxVars.WaterPipes.SmartPipesUpdateNotWatered and waterNeeded <= 0 then
							local farmsystem = SFarmingSystem.instance;
							plant.lastWaterHour = farmsystem.hoursElapsed;
							plant:saveData();
						end
					end
					if stop then
						break;
					end
				end
			end
			
			-- update barrels
			local barrelsNb = #v;
			for _, barrel in ipairs(v) do
				WaterPipe.updateBarrel(barrel, waterPerCluster[k], 0, barrelsNb, fertilizerPerCluster[k], false);
			end
		end
	end
end


function WaterPipe.fusionClustersSharedSources(clusters)
	local found_shared = true;
	
	while found_shared do
	
		found_shared = false;
		
		local clusterKey1 = nil;
		local clusterKey2 = nil
		
		for key, srcL in pairs(clusters) do 
			clusterKey1 = key;
			for pos, barrel in ipairs(srcL) do			
				for key2, srcL2 in pairs(clusters) do
					clusterKey2 = key2;
					for pos2, barrel2 in ipairs(srcL2) do
						if key ~= key2 then
							if barrel.x == barrel2.x and barrel.y == barrel2.y and barrel.z == barrel2.z then
								found_shared = true;							
								break;
							end
						end
					end
					if found_shared then
						break;
					end
				end
				if found_shared then
					break;
				end
			end
			if found_shared then
				break;
			end
		end
		
		-- fusion
		if found_shared then
			local new_clusters = {};
			local fusion_clusterPipes = {};
			local fusion_clusterSources = {};
			for key, srcL in pairs(clusters) do 
				if key == clusterKey1 or key == clusterKey2 then
					for i,j in pairs(key) do
						fusion_clusterPipes[i] = "ok";
					end
					for i,barrel in ipairs(srcL) do
						local found = false;
						for _, barrel2 in ipairs(fusion_clusterSources) do
							if barrel.x == barrel2.x and barrel.y == barrel2.y and barrel.z == barrel2.z then
								found = true;
								break;
							end
						end
						
						if found then
						else
							table.insert(fusion_clusterSources, barrel);
						end
					end
				else
					new_clusters[key] = srcL;
				end
			end
			
			new_clusters[fusion_clusterPipes] = fusion_clusterSources;
			clusters = new_clusters;
		end
		
	end
	
	return clusters;
end


----
function WaterPipe.updatePipes()
	if isClient() then return; end
	-- every 2 hours, we proceed
	local sec = math.floor(getGameTime():getTimeOfDay() * 3600);
	local currentHour = math.floor(sec / 3600);
	
	local doWater = false;
	
	if currentHour ~= WaterPipe.previousHour then
		WaterPipe.previousHour = currentHour;
		WaterPipe.hourElapsedForWater = WaterPipe.hourElapsedForWater + 1;
		local hourForWater = 5
		if SandboxVars.PlantResilience == 1 then -- very high
			hourForWater = 12;
		elseif SandboxVars.PlantResilience == 2 then -- high
			hourForWater = 8;
		elseif SandboxVars.PlantResilience == 4 then -- low
			hourForWater = 3;
		elseif SandboxVars.PlantResilience == 5 then -- very low
			hourForWater = 2;
		end

		if WaterPipe.hourElapsedForWater >= hourForWater then
			WaterPipe.hourElapsedForWater = 0;
			doWater = true;
			-- print("watering plants")

		end
	end
		
	-- print("debug rain collector barrel code : all collector barrels waterLvl");
	-- for k, v in pairs(barrels) do
		-- print("rain collector barrel " .. v.id .. " has waterLvl " .. v.waterAmount);
		-- print("at pos " .. v.x .. ", " .. v.y);
		-- if v.fertilizerLvl then
			-- print("has fertilizer level : " .. v.fertilizerLvl );
		-- end
	-- end	


	-- Winter related code. Should already be handles by farming system though? So commented out

	-- update plants if it's winter, code should go into plantings
	-- no plant (outdoor) should last more than 2 or 3 days.
--	local month = GameTime:getInstance():getMonth();
--	-- print("month is " .. month);
--	if month >= 10 or month <= 1 then
--		print("winter is here, and (outdoor) plants slowly loose health");
--		for iPlant, vPlant in pairs(basicFarming.plantings) do
--			if vPlant.state ~= "plow" and vPlant:isAlive() and vPlant.exterior then
--				vPlant.health = vPlant.health - 2.8; -- farming does +1.4 if sunny and water is ok
--				basicFarming.checkStat(vPlant);
--				if vPlant.health <= 0 then
--					basicFarming.dryThis(vPlant);
--				end
--				basicFarming.saveData(vPlant)
--			end
--		end
--	end
	
	if #WaterPipe.pipes == 0 then
		return;
	end

	WaterPipe.lock = true;

	if WaterPipe.modData.waterPipes["check_infinite"] == nil then
		WaterPipe.modData.waterPipes["check_infinite"] = "true";
	end
	
	if WaterPipe.modData.waterPipes["check_infinite"] == "true" and GameTime:getInstance():getNightsSurvived() >= SandboxVars.WaterShutModifier then
		for ind, apipe in ipairs(WaterPipe.pipes) do
			if apipe.infinite and apipe.infinite == "true" then
				apipe.infinite = "false";
			end
		end
		for ind, apipe in ipairs(WaterPipe.modData.waterPipes.pipes) do
			if apipe.infinite and apipe.infinite == "true" then				
				apipe.infinite = "false";
			end
		end
		WaterPipe.modData.waterPipes["check_infinite"] = "false";
	end
	
	-- build adjacent matrix
	local mat = {};
	WaterPipe.buildAdjMatrix(mat);
	
	-- build clusters
	local clusters = {};
	WaterPipe.buildClusters(mat, clusters);
	
	local cbarrels = {};
	-- find sources	(water barrels)
	WaterPipe.buildWaterSources(cbarrels);
	
	-- update clusters with sources
	WaterPipe.buildClustersSources(clusters, cbarrels);
	
	-- fusion of clusters sharing sources
	local clustersF = {};
	clustersF = WaterPipe.fusionClustersSharedSources(clusters);
	
	local planting = {};
	local waterPerCluster = {};
	local fertilizerPerCluster = {};
	
	
	local infiniteClusterSource = {};
	for i,j in pairs(clustersF) do
		infiniteClusterSource[i] = "false";
	end
	-- save some processing power	
	if doWater then
		-- find our plants
		WaterPipe.buildPlantsAdj(planting);		
		
		-- water needed for each cluster
		-- water available for each cluster
		-- if there's enough it's gonna be easy, otherwise we have an optimal flow problem for each cluster ...
		-- from ttr - nope - max water was removed - system is now dummed down and plants go FIFO
		WaterPipe.buildClusterWaterNeeds(clustersF, planting, waterPerCluster, fertilizerPerCluster, infiniteClusterSource);
		
		-- water plants of each cluster
		WaterPipe.waterPlants(clustersF, planting, waterPerCluster, fertilizerPerCluster, infiniteClusterSource);
	else
		-- for water average	
		for id, apipe in ipairs(WaterPipe.pipes) do
			table.insert(planting, {});
		end

		WaterPipe.buildClusterWaterNeeds(clustersF, planting, waterPerCluster, fertilizerPerCluster, infiniteClusterSource);
		
		for k, v in pairs(clustersF) do
			local fillBarrels = false;
			if infiniteClusterSource[k] == "true" then
				fillBarrels = true;
			end
		
			-- go through the water barrels
			local barrelsNb = #v;			
			local max40 = false;
			
			for _, barrel in ipairs(v) do
				local ret, val = WaterPipe.updateBarrel(barrel, waterPerCluster[k], 0, barrelsNb, 0, fillBarrels);
				if ret then
					max40 = true;
				end
			end
			
			if max40 then
				for _, barrel in ipairs(v) do
					WaterPipe.updateBarrel(barrel, -2, 0, barrelsNb, 0, false);
				end
			end			
		end
	end
	
	WaterPipe.lock = false;	
	
	-- print for debug
	-- for i, j in pairs(clustersF) do
		-- print("compo connex : ");
		-- for k, v in pairs(i) do
			-- if doWater then
				-- print(k .. ", connected to " .. #planting[k] .. " plants");
			-- else
				-- print(k);
			-- end
		-- end
		-- print("has " .. #j .. " water sources :");
		-- for id, barrel in ipairs(j) do	
			-- for k, v in pairs(barrels) do
				-- if v.x == barrel.x and v.y == barrel.y and v.z == barrel.z then
					-- print("rain collector barrel " .. k .. " has waterLvl " .. barrel.waterAmount);
					-- if barrel.fertilizerLvl then
						-- print("has fertilizer level : " .. barrel.fertilizerLvl );
					-- end
				-- end
			-- end
		-- end
		
		-- print("has " .. waterPerCluster[i] .. " water units available");
		-- print("has a need of " .. waterNeededPerCluster[i] .. " water units");
		-- if waterPerCluster[i] - waterNeededPerCluster[i] >= 0 then
			-- print("has " .. waterPerCluster[i] - waterNeededPerCluster[i] .. " water units left (some natural loss can occur)");
		-- else
			-- print("has " .. 0 .. " water units left");
		-- end
	-- end
	-- print("nights survived = " .. GameTime:getInstance():getNightsSurvived());
	-- print("water off modifier = " .. SandboxVars.WaterShutModifier);
end

Events.EveryTenMinutes.Add(WaterPipe.updatePipes);


WaterPipe.pourWater = function(waterSource, barrel, uses, square)
	local waterAmount = barrel.waterAmount;
	if(waterAmount < barrel.waterMax) and uses > 0 then
		if waterSource then
			
			for i = 1, uses do
				if waterSource:getUsedDelta() > 0 then
					waterSource:Use();
				else
					-- waterSource:setUsedDelta(0);
					break;
				end
			end
			-- leave nothing less than 1 use
			if math.floor((waterSource:getUsedDelta())/waterSource:getUseDelta()) == 0 and waterSource:getUsedDelta() > 0 then
				waterSource:Use();
				waterSource:setUsedDelta(0);
			end
		end	
			-- print("adding " .. uses .. " water to barrel");
			waterAmount = waterAmount + ( uses );--* 0.25 );
			
			if(waterAmount > barrel.waterMax) then
				waterAmount = barrel.waterMax;
			end
			
			barrel.waterAmount = waterAmount;
			local barrelsystem = SRainBarrelSystem.instance
			local obj = barrelsystem:getIsoObjectOnSquare(square)
			if obj then
				obj:setWaterAmount(barrel.waterAmount)
				obj:transmitModData()
			end
			
			-- should be useless, we're always in square
			if square then
			-- obj:setWaterAmount(vB.waterAmount) or obj:transmitModData() is going to trigger RainCollectorBarrel.saveData(vB) soon after through event
			else
				--barrel:saveData();
			end
		--end
	end
	
	-- break;
	-- end
	-- end
end

-- pour fertilizer
function WaterPipe.pourFertilizer(npkItem, barrel, square, character, touse)
	-- as client, we don't have the real barrel, the server needs to find the real one, with the fertilizer level
	local b = WaterPipe.findBarrelObject(square)
	
	-- print("adding ".. touse .."fertilizer")
	barrel.fertilizerLvl = barrel.fertilizerLvl + touse;
		
	if npkItem then
		for i = 1, touse do
			npkItem:Use();
		end
	end
	
	if b then
		b:getModData()["fertilizerLvl"] = barrel.fertilizerLvl;
		b:transmitModData()
	end
	
	--barrel:saveData();
	
end

function WaterPipe.onCreateMigratepipes(items, result, player)
	local pipesToAdd=0;
	for i=0,items:size() - 1 do
		if items:get(i):getType() == "WaterPipe" then
			tool = items:get(i)
			condition = tool:getCondition()
		end
    end
	pipesToAdd = math.floor(condition * 10);
	-- start from 1 as 1 is added by recipe
	if pipesToAdd > 1 then
		for i=2,pipesToAdd,1 do
			player:getInventory():AddItem("waterPipes.WaterPipe2");
		end
	end
end