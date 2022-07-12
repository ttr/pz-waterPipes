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
	if not self.playerObject:isEquipped(self.pipeItem) then
		self:reset();
	elseif math.abs(self.pipeItem:getUsedDelta()-self.pipeItem:getUseDelta()) < 0.1 or math.floor(self.pipeItem:getUsedDelta()/self.pipeItem:getUseDelta()) > 0 then
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
		self.pipeItem:Use();

		--self.sq:AddSpecialObject(self.javaObject);
		self.sq:AddTileObject(self.javaObject);
		-- table.insert(WaterPipe.modData.waterPipes.pipes, pipe);

		self.javaObject:transmitCompleteItemToServer();
		self.javaObject:transmitCompleteItemToClients();
	else
		self.playerObject:Say(getText("IGUI_WaterPipe_NoMorePipe"));
		ISTimedActionQueue.add(ISUnequipAction:new(self.playerObject, self.pipeItem, 50));
	end
end


---
-- Test if it's possible to place
--
function Pipe:isValid(square, north)
	local testForPermitted = false;
	
	for i = 0, square:getObjects():size() - 1 do
		if square:getObjects():get(i):getName() == "WaterPipe" then
			return false;
		end
		if (square:getObjects():get(i):getType() == IsoObjectType.wall) then
			testForPermitted = true;
		end

	end

	-- local door = nil;
	for i = 0, square:getSpecialObjects():size() - 1 do
		if (square:getSpecialObjects():get(i):getType() == IsoObjectType.wall) then
			testForPermitted = true;
		end
	end
	
	if testForPermitted then
		return true;
    end

	return ( square:getSpecialObjects():size() == 0 );
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
function Pipe.pipeRemoveTile(pipeObject)

	square:transmitRemoveItemFromSquare(pipeObject);
	square:RemoveTileObject(pipeObject);
	square:DeleteTileObject(pipeObject);

	for i=1, #WaterPipe.pipes do
		if WaterPipe.pipes[i].x == pipe.x and
			WaterPipe.pipes[i].y == pipe.y and
			WaterPipe.pipes[i].z == pipe.z then
			table.remove(WaterPipe.pipes, i)
			break
		end
	end
	for i=1, #WaterPipe.modData.waterPipes.pipes do
		if WaterPipe.modData.waterPipes.pipes[i].x == pipe.x and
			WaterPipe.modData.waterPipes.pipes[i].y == pipe.y and
			WaterPipe.modData.waterPipes.pipes[i].z == pipe.z then
			table.remove(WaterPipe.modData.waterPipes.pipes, i)
			break
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

function Pipe.onPickUp(pipe, player)
	local square = getWorld():getCell():getGridSquare(pipe.x, pipe.y, pipe.z);
	local pipeObject = WaterPipe.findPipeObject(square)

	if square and pipeObject ~= nil then
		Pipe.pipeRemoveTile(pipeObject)
		
		-- with player modData : reset when after re login on server
		-- so when player dies, we don't have useless stuff that remain
		-- if player:getModData()["removedWaterPipes"] then
		-- print("player has already removed some pipes")
		-- player:getModData()["removedWaterPipes"] = player:getModData()["removedWaterPipes"] + 1;
		-- if player:getModData()["removedWaterPipes"] == 10 then
		-- player:sendObjectChange('addItemOfType', { type = "waterPipes.WaterPipe", count = 1 })
		-- player:Say("I got enough pipes back");
		-- player:getModData()["removedWaterPipes"] = 0;
		-- else
		-- local delta = 10 - player:getModData()["removedWaterPipes"];
		-- player:Say("I got one pipe back, " .. delta .. " more before I get the whole back");
		-- end
		-- else
		-- print("player didn't remove any pipe")
		-- player:getModData()["removedWaterPipes"] = 1;
		-- player:Say("I got one pipe back, 9 more before I get the whole back");
		-- end

		if WaterPipe.modData.waterPipes.player and WaterPipe.modData.waterPipes.player["removedWaterPipes"] then
			WaterPipe.modData.waterPipes.player["removedWaterPipes"] = WaterPipe.modData.waterPipes.player["removedWaterPipes"] + 1;
			if WaterPipe.modData.waterPipes.player["removedWaterPipes"] == 10 then
				if isServer() then
					player:sendObjectChange('addItemOfType', { type = "waterPipes.WaterPipe", count = 1 });
				else
					player:getInventory():AddItem("waterPipes.WaterPipe");
				end
				player:Say(getText("IGUI_WaterPipe_EnoughPipeBack"));
				WaterPipe.modData.waterPipes.player["removedWaterPipes"] = 0;
			else
				local delta = 10 - WaterPipe.modData.waterPipes.player["removedWaterPipes"];
				player:Say(getText("IGUI_WaterPipe_RecoverPipeProgress", delta));
			end
		else
			WaterPipe.modData.waterPipes.player = {}
			WaterPipe.modData.waterPipes.player["removedWaterPipes"] = 1;
			player:Say(getText("IGUI_WaterPipe_RecoverPipeProgress", 9));
		end
	end
end

