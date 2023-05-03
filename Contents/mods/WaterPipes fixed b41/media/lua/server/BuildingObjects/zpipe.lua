---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

require "BuildingObjects/ISBuildingObject"

Pipe = ISBuildingObject:derive("Pipe");

function Pipe.checkForBarrel(square)
	for i = 0, square:getSpecialObjects():size() - 1 do
		if square:getSpecialObjects():get(i):getName() == "Rain Collector Barrel" then
			return true;
		end
	end
	return false;
end

function Pipe:create(x, y, z, north, sprite)
	if not self.playerObject:isEquipped(self.pipeItem) and not self.playerObject:getInventory():contains("WaterPipe2") then
		self:reset();
	else
		local cell = getWorld():getCell();
		self.sq = cell:getGridSquare(x, y, z);
		self.javaObject = IsoObject.new(self.sq, sprite, "WaterPipe");
		self.javaObject:getModData()["pipeType"] = self.pipeType;
		self.javaObject:getModData()["infinite"] = "false";

		local pipe = {};
		-- pipe.id = #pipes + 1;
		pipe.x = self.sq:getX();
		pipe.y = self.sq:getY();
		pipe.z = self.sq:getZ();
		pipe.pipeType = self.pipeType;
		pipe.infinite = "false"

		-- water is still on, look for infinite water source
		-- print("nights survived = " .. GameTime:getInstance():getNightsSurvived());
		-- print("water off modifier = " .. SandboxVars.WaterShutModifier);
		if GameTime:getInstance():getNightsSurvived() < SandboxVars.WaterShutModifier then
			-- print("checking for infinite water source");
			local north = cell:getGridSquare(self.sq:getX(), self.sq:getY()-1, self.sq:getZ());
			local south = cell:getGridSquare(self.sq:getX(), self.sq:getY()+1, self.sq:getZ());
			local east = cell:getGridSquare(self.sq:getX()+1, self.sq:getY(), self.sq:getZ());
			local west = cell:getGridSquare(self.sq:getX()-1, self.sq:getY(), self.sq:getZ());

			-- one is enough
			if north:getProperties():Is(IsoFlagType.waterPiped) then
				-- check it's not a barrel and add infinite source to pipe
				if not Pipe.checkForBarrel(north) then
					pipe.infinite = "true";
					self.javaObject:getModData()["infinite"] = "true";
					-- print("infinite water source");
				end
			elseif south:getProperties():Is(IsoFlagType.waterPiped) then
				if not Pipe.checkForBarrel(south) then
					pipe.infinite = "true";
					self.javaObject:getModData()["infinite"] = "true";
					-- print("infinite water source");
				end
			elseif east:getProperties():Is(IsoFlagType.waterPiped) then
				if not Pipe.checkForBarrel(east) then
					pipe.infinite = "true";
					self.javaObject:getModData()["infinite"] = "true";
					-- print("infinite water source");
				end
			elseif west:getProperties():Is(IsoFlagType.waterPiped) then
				if not Pipe.checkForBarrel(west) then
					pipe.infinite = "true";
					self.javaObject:getModData()["infinite"] = "true";
					-- print("infinite water source");
				end
			end
		end

		table.insert(WaterPipe.pipes, pipe);
		self.playerObject:removeFromHands(self.pipeItem);
		self.playerObject:getInventory():Remove("WaterPipe2");

		--self.sq:AddSpecialObject(self.javaObject);
		self.sq:AddTileObject(self.javaObject);
		-- table.insert(WaterPipe.modData.waterPipes.pipes, pipe);

		self.javaObject:transmitCompleteItemToServer();
		self.javaObject:transmitCompleteItemToClients();
	end
end


---
-- Test if it's possible to place
--
function Pipe:isValid(square, north)
	local testForPermitted = false;
	local specialObjectsCount = square:getSpecialObjects():size();
	local specialObjectsAllowed = 0;

	for i = 0, square:getObjects():size() - 1 do
		if square:getObjects():get(i):getName() == "WaterPipe" then
			return false;
		end
--		if (square:getObjects():get(i):getType() == IsoObjectType.wall) then
--			testForPermitted = true;
--		end

	end

	-- local door = nil;
	for i = 0, specialObjectsCount - 1 do
		if (square:getSpecialObjects():get(i):getType() == IsoObjectType.wall) then
			specialObjectsAllowed = specialObjectsAllowed + 1;
		end
	end
	
	if specialObjectsAllowed >= specialObjectsCount then
		return true;
    end

	return false;
end


---
--
--
function Pipe:render(x, y, z, square, north)
	ISBuildingObject.render(self, x, y, z, square, north)
	-- return true;
end


---
--
--
function Pipe:getHealth()
	return 100;
end


---
--
--
function Pipe:new(player, pipeItem, spritea, pipeType)
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();

	o:setSprite(spritea);

	o.name = "Water Pipe";
	o.dismantable = false;
	o.canBarricade = false;
	o.blockAllTheSquare = false;
	o.canPassThrough = true;
	o.maxTime = 10;
	o.isContainer = false;
	o.isThumpable = false;
	o.noNeedHammer = true;

	o.pipeItem = pipeItem;
	o.player = player;
	o.playerObject = getSpecificPlayer(player);

	o.pipeType = pipeType;

	return o;
end


----------------------

---
-- When pipe is removed / destroyed
--

-- delete sprite and call removal pipe from network
function Pipe.pipeRemoveTile(pipeObject)
	local square = pipeObject:getSquare();
	square:transmitRemoveItemFromSquare(pipeObject);
	square:RemoveTileObject(pipeObject);
	square:DeleteTileObject(pipeObject);
	Pipe.pipeRemove(square:getX(), square:getY(), square:getZ());
end

-- delete pipe from network
function Pipe.pipeRemove(x, y , z, breakOnFind)
	--print('\t', "pipeRemove",x, y, z, breakOnFind);
	if breakOnFind == nil then
		breakOnFind = true
	end

	for i=0, #WaterPipe.pipes do
		if WaterPipe.pipes[i] and
			WaterPipe.pipes[i].x == x and
			WaterPipe.pipes[i].y == y and
			WaterPipe.pipes[i].z == z then
				table.remove(WaterPipe.pipes, i)
				--print('\t', "pipes 1", x, y, z);
				if breakOnFind then break;end
		end
	end
	for i=0, #WaterPipe.modData.waterPipes.pipes do
		if WaterPipe.modData.waterPipes.pipes[i] and WaterPipe.modData.waterPipes.pipes[i].x == x and
			WaterPipe.modData.waterPipes.pipes[i].y == y and
			WaterPipe.modData.waterPipes.pipes[i].z == z then
				table.remove(WaterPipe.modData.waterPipes.pipes, i)
				--print('\t',"pipes 2", x, y, z);
				if breakOnFind then break;end
		end
	end
end

-- not used (future for destroyin with sledge)
function Pipe.onPipeDestroy(pipe)
	local square = getWorld():getCell():getGridSquare(pipe.x, pipe.y, pipe.z);
	local pipeObject = WaterPipe.findPipeObject(square)
	if square and pipeObject ~= nil then
		Pipe.pipeRemoveTile(pipeObject)
	end
end

-- pipe pickup
function Pipe.onPickUp(pipe, player)
	--print('\t', "Pipe pickup", pipe.x, pipe.y, pipe.z)
	local square = getWorld():getCell():getGridSquare(pipe.x, pipe.y, pipe.z);
	local pipeObject = WaterPipe.findPipeObject(square)

	if square and pipeObject ~= nil then
		Pipe.pipeRemoveTile(pipeObject)
		
		-- wp2
		if isServer() then
			player:sendObjectChange('addItemOfType', { type = "waterPipes.WaterPipe2", count = 1 });
		else
			player:getInventory():AddItem("waterPipes.WaterPipe2");
		end

		-- refund partial pipes mk1
		if WaterPipe.modData.waterPipes.player and WaterPipe.modData.waterPipes.player["removedWaterPipes"] and WaterPipe.modData.waterPipes.player["removedWaterPipes"] > 0 then
			if isServer() then
				player:sendObjectChange('addItemOfType', { type = "waterPipes.WaterPipe2", count = WaterPipe.modData.waterPipes.player["removedWaterPipes"] });
			else
				for i=1,WaterPipe.modData.waterPipes.player["removedWaterPipes"],1 do
					player:getInventory():AddItem("waterPipes.WaterPipe2");
				end
			end
			WaterPipe.modData.waterPipes.player["removedWaterPipes"] = 0;
		end
	end
end

