
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

print("MOD DEBUG: waterpipemenu lua loaded")
WaterPipeMenu = {};
WaterPipeMenu.info = nil;
WaterPipeMenu.currentBarrel = nil;
WaterPipeMenu.currentPipe = nil;


WaterPipeMenu.onWater = function(worldobjects, uses, handItem, square, player, barrel)
	if luautils.walkAdj(getSpecificPlayer(player), square) then
		if getSpecificPlayer(player):getSecondaryHandItem() ~= handItem then
			ISTimedActionQueue.add(ISEquipWeaponAction:new(getSpecificPlayer(player), handItem, 50, false));
		end
		
		ISTimedActionQueue.add(pourWaterInBarrelAction:new(getSpecificPlayer(player), handItem, uses, square, WaterPipeMenu.currentBarrel, uses));
	end
end

---
-- Create the contextual menu for piping
--

-- any container that takes water from the barrel takes 10 and pours back 10
WaterPipeMenu.doPourWaterMenu = function(worldobjects, context, subMenu, player, handItem, square, barrel)
	local doMenu = false;
	if handItem and handItem:isWaterSource() and math.floor(handItem:getUsedDelta()/handItem:getUseDelta()) > 0 then
		doMenu = true;
	else
		for i = 0, getSpecificPlayer(player):getInventory():getItems():size() - 1 do
			local item = getSpecificPlayer(player):getInventory():getItems():get(i);
			if item:isWaterSource() and math.floor(item:getUsedDelta()/item:getUseDelta()) > 0 then
				handItem = item;
				doMenu = true;
				break;
			end
		end
	end
	-- we get how many use we can do on our item
	-- we choose the percentage of what the item have to use
	if doMenu then
		local use = math.floor((handItem:getUsedDelta())/handItem:getUseDelta());
		-- print("uses of item left " .. use);
		if use > 0 and barrel.waterAmount < barrel.waterMax then
			local waterOption = subMenu:addOption(getText("ContextMenu_WaterPipe_PourWater"), worldobjects, nil);
			local subMenuWater = subMenu:getNew(subMenu);
			context:addSubMenu(waterOption, subMenuWater);
						
			local missingWaterUse = barrel.waterMax - barrel.waterAmount;
			if missingWaterUse  < use then
				use = missingWaterUse;
			end
						
			subMenuWater:addOption(getText("ContextMenu_WaterPipe_OneUse"), worldobjects, WaterPipeMenu.onWater, 1, handItem, square, player, barrel);
			
			
			-- quantity of water units to pour
			local waterLvl = 0;
			local step = 1;
			if use > 10 then
				step = 4;
				for i=step, use/2.0, step do
					if i >= use then
						break
					end
					waterLvl = i;
					subMenuWater:addOption(getText("ContextMenu_WaterPipe_SomeUses", waterLvl), worldobjects, WaterPipeMenu.onWater, waterLvl, handItem, square, player, barrel);
				end
			else
				for i=2, use/2.0, step do
					if i >= use then
						break
					end
					waterLvl = i;
					subMenuWater:addOption(getText("ContextMenu_WaterPipe_SomeUses", waterLvl), worldobjects, WaterPipeMenu.onWater, waterLvl, handItem, square, player, barrel);
				end
			end
			
			
			subMenuWater:addOption(getText("ContextMenu_WaterPipe_AllUses", use), worldobjects, WaterPipeMenu.onWater, use, handItem, square, player, barrel);
			
		end
	end
end

function WaterPipeMenu.doPourNPKMenu(worldobjects, context, subMenu, player, npkItem, barrel, square)
	local doMenu = false;
	local handItem = nil;
	if npkItem and math.floor(npkItem:getUsedDelta()/npkItem:getUseDelta()) > 0 then
		handItem = npkItem;
		doMenu = true;
	else
		for i = 0, getSpecificPlayer(player):getInventory():getItems():size() - 1 do
			local item = getSpecificPlayer(player):getInventory():getItems():get(i);
			if item:getName() == 'Fertilizer' and math.floor(item:getUsedDelta()/item:getUseDelta()) > 0 then
				handItem = item;
				doMenu = true;
				break;
			end
		end
	end
	-- we get how many use we can do on our item
	-- we choose the percentage of what the item have to use
	if doMenu and handItem then
		local use = math.ceil((handItem:getUsedDelta())/handItem:getUseDelta());
		-- print("uses of item left " .. use);
		if use > 0 then
			local fertilizerOption = subMenu:addOption(getText("ContextMenu_WaterPipe_PourFertilizer"), worldobjects, nil);
			local subMenuFertilizer = subMenu:getNew(subMenu);
			context:addSubMenu(fertilizerOption, subMenuFertilizer);			
						
			for i=1, use do
				subMenuFertilizer:addOption(getText("ContextMenu_WaterPipe_Uses"), worldobjects, WaterPipeMenu.onPourFertilizer, i, handItem, square, player, barrel);
			end
			
		end
	end
end


WaterPipeMenu.doPipeMenu = function(player, context, worldobjects)
	local playerInventory = getSpecificPlayer(player):getInventory();
	local trap = nil;
	local isWaterPipeMenu = false;
	local isWaterPipeMenuBarrel = false;
	local subMenu = context:getNew(context);
	for _,object in ipairs(worldobjects) do
		local square = object:getSquare();
		-- for i = 0, square:getSpecialObjects():size() - 1 do
			
			
			WaterPipeMenu.currentPipe = WaterPipe.getCurrentPipe(square);
			if WaterPipeMenu.currentPipe ~= nil then
				print("pipe on right click")
			else
				print("no pipe on right click")
			end
			
			local specialObject = nil;
			if WaterPipeMenu.currentPipe ~= nil then
				specialObject = WaterPipe.findPipeObject(square)
				if specialObject ~= nil then
					print("found special object pipe")
				end
			end
			
			-- shouldn't remove pipes if watering plants : check WaterPipe.lock == false
			--if instanceof(specialObject, "IsoObject") and specialObject:getName() == "WaterPipe" and WaterPipe.lock == false then
			if WaterPipeMenu.currentPipe ~= nil and specialObject ~= nil then
				isWaterPipeMenu = true;
				subMenu:addOption(getText("ContextMenu_WaterPipe_RemovePipe"), worldobjects, WaterPipeMenu.onRemovePipe, player, specialObject, square, 10);
				break;
			end
			
			WaterPipeMenu.currentBarrel = WaterPipe.getCurrentBarrel(square);
			
			if WaterPipeMenu.currentBarrel ~= nil then
				print("barrel on right click")
			else
				print("no barrel on right click")
			end
			
			-- interact with rain barrel for fertilizer
			--if instanceof(specialObject, "IsoObject") and specialObject:getName() == "Rain Collector Barrel" then
			if WaterPipeMenu.currentBarrel ~= nil then
				-- print("interract with rain barrel");
				local npkItem = nil;
				local canUseNPK = false;
				local handItem = getSpecificPlayer(player):getSecondaryHandItem();
				
				if handItem and handItem:getType() == "Fertilizer" and ( math.abs(handItem:getUsedDelta()-handItem:getUseDelta()) < 0.1 or math.floor(handItem:getUsedDelta()/handItem:getUseDelta()) > 0 ) then
					canUseNPK = true;
					npkItem = handItem;
				else
					if playerInventory:contains("Fertilizer") then		
						for i = 0, getSpecificPlayer(player):getInventory():getItems():size() - 1 do
							npkItem = getSpecificPlayer(player):getInventory():getItems():get(i);
							if npkItem:getType() == "Fertilizer" and ( math.abs(npkItem:getUsedDelta()-npkItem:getUseDelta()) < 0.1 or math.floor(npkItem:getUsedDelta()/npkItem:getUseDelta()) > 0 ) then
								canUseNPK = true;
								break;
							end
						end
					end
				end
				
				if canUseNPK then
					WaterPipeMenu.doPourNPKMenu(worldobjects, context, subMenu, player, npkItem, WaterPipeMenu.currentBarrel, square);
				end
				
				subMenu:addOption(getText("ContextMenu_WaterPipe_BarrelInfo"), worldobjects, WaterPipeMenu.onBarrelInfo, player, square, WaterPipeMenu.currentBarrel);
				
				WaterPipeMenu.doPourWaterMenu(worldobjects, context, subMenu, player, handItem, square, WaterPipeMenu.currentBarrel);		
								
				isWaterPipeMenuBarrel = true;
				break;
			end
		-- end
	end
	
	local pipeItem = nil;
	local canUsepipeItem = false;
	local handItem = getSpecificPlayer(player):getSecondaryHandItem();
	
	if handItem and handItem:getType() == "WaterPipe" and ( math.abs(handItem:getUsedDelta()-handItem:getUseDelta()) < 0.1 or math.floor(handItem:getUsedDelta()/handItem:getUseDelta()) > 0 ) then
		canUsepipeItem = true;
		pipeItem = handItem;
	else
		if playerInventory:contains("WaterPipe") then		
			for i = 0, getSpecificPlayer(player):getInventory():getItems():size() - 1 do
				pipeItem = getSpecificPlayer(player):getInventory():getItems():get(i);
				if pipeItem:getType() == "WaterPipe" and ( math.abs(pipeItem:getUsedDelta()-pipeItem:getUseDelta()) < 0.1 or math.floor(pipeItem:getUsedDelta()/pipeItem:getUseDelta()) > 0 ) then
					canUsepipeItem = true;
					break;
				end
			end
		end
	end
	
	if canUsepipeItem then
		local pipeOption = subMenu:addOption(getText("ContextMenu_WaterPipe_PlacePipe"), worldobjects, nil);
		local subMenuPipe = subMenu:getNew(subMenu);
		context:addSubMenu(pipeOption, subMenuPipe);
		
		local subsubOption = subMenuPipe:addOption(getText("ContextMenu_WaterPipe_Lines"), worldobjects, nil);
		local subMenuShape = subMenuPipe:getNew(subMenuPipe);
		context:addSubMenu(subsubOption, subMenuShape);
		
		local lineOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Line_Param", getText("ContextMenu_WaterPipe_EW")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeSE.png", "lineOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Line"));
		tooltip.description = getText("ContextMenu_WaterPipe_Line");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeSE.png");		
		lineOption.toolTip = tooltip;		
		----------------------------------------
		local lineOption2 = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Line_Param", getText("ContextMenu_WaterPipe_NS")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeNorth.png", "lineOption2");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Line"));
		tooltip.description = getText("ContextMenu_WaterPipe_Line");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeNorth.png");		
		lineOption2.toolTip = tooltip;		
		----------------------------------------
		subsubOption = subMenuPipe:addOption(getText("ContextMenu_WaterPipe_Cross"), worldobjects, nil);
		subMenuShape = subMenuPipe:getNew(subMenuPipe);
		context:addSubMenu(subsubOption, subMenuShape);
		
		local crossOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Cross") , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeCross.png", "crossOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Cross"));
		tooltip.description = getText("ContextMenu_WaterPipe_Cross");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeCross.png");		
		crossOption.toolTip = tooltip;		
		----------------------------------------
		subsubOption = subMenuPipe:addOption(getText("ContextMenu_WaterPipe_Corner"), worldobjects, nil);
		subMenuShape = subMenuPipe:getNew(subMenuPipe);
		context:addSubMenu(subsubOption, subMenuShape);
		
		local neOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Corner_Param", getText("ContextMenu_WaterPipe_SW")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeCornerNE.png", "neOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Corner"));
		tooltip.description = getText("ContextMenu_WaterPipe_Corner");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeCornerNE.png");		
		neOption.toolTip = tooltip;		
		----------------------------------------
		local nwOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Corner_Param", getText("ContextMenu_WaterPipe_SE")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeCornerNW.png", "nwOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Corner"));
		tooltip.description = getText("ContextMenu_WaterPipe_Corner");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeCornerNW.png");		
		nwOption.toolTip = tooltip;		
		----------------------------------------		
		local seOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Corner_Param", getText("ContextMenu_WaterPipe_NW")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeCornerSE.png", "seOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Corner"));
		tooltip.description = getText("ContextMenu_WaterPipe_Corner");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeCornerSE.png");		
		seOption.toolTip = tooltip;		
		----------------------------------------		
		local swOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_Corner_Param", getText("ContextMenu_WaterPipe_NE")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeCornerSW.png", "swOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_Corner"));
		tooltip.description = getText("ContextMenu_WaterPipe_Corner");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeCornerSW.png");		
		swOption.toolTip = tooltip;		
		----------------------------------------		
		subsubOption = subMenuPipe:addOption(getText("ContextMenu_WaterPipe_T"), worldobjects, nil);
		subMenuShape = subMenuPipe:getNew(subMenuPipe);
		context:addSubMenu(subsubOption, subMenuShape);
		
		local tnOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_T_Param", getText("ContextMenu_WaterPipe_North")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeTN.png", "tnOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_T"));
		tooltip.description = getText("ContextMenu_WaterPipe_T");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeTN.png");		
		tnOption.toolTip = tooltip;		
		----------------------------------------		
		local tsOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_T_Param", getText("ContextMenu_WaterPipe_South")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeTS.png", "tsOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_T"));
		tooltip.description = getText("ContextMenu_WaterPipe_T");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeTS.png");		
		tsOption.toolTip = tooltip;		
		----------------------------------------		
		local teOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_T_Param", getText("ContextMenu_WaterPipe_East")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeTE.png", "teOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_T"));
		tooltip.description = getText("ContextMenu_WaterPipe_T");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeTE.png");		
		teOption.toolTip = tooltip;		
		----------------------------------------		
		local twOption = subMenuShape:addOption(getText("ContextMenu_WaterPipe_T_Param", getText("ContextMenu_WaterPipe_West")) , worldobjects, WaterPipeMenu.onPlacePipe, player, pipeItem, "media/textures/Item_PipeTW.png", "twOption");
		----------------------------------------------
		local tooltip = ISBuildMenu.addToolTip();
		tooltip:setName(getText("ContextMenu_WaterPipe_T"));
		tooltip.description = getText("ContextMenu_WaterPipe_T");
		-- tooltip.description = tooltip.description .. " <LINE>" .. " <RGB:1,1,1>" .. "Water Pipe";
		tooltip:setTexture("media/textures/Item_PipeTW.png");		
		twOption.toolTip = tooltip;		
		----------------------------------------
	end
	
	if canUsepipeItem or isWaterPipeMenu or isWaterPipeMenuBarrel then
		local buildOption = context:addOption(getText("ContextMenu_WaterPipe_IrrigationPipe"), worldobjects, nil);
		context:addSubMenu(buildOption, subMenu);
	end
	
end


---
-- Create a new pipe to drag
--
WaterPipeMenu.onPlacePipe = function(worldobjects, player, pipeItem, spritea, pipeType)	
	if getSpecificPlayer(player):getSecondaryHandItem() ~= pipeItem then
		ISTimedActionQueue.add(ISEquipWeaponAction:new(getSpecificPlayer(player), pipeItem, 50, false));
	end
	
	local pipe = Pipe:new(player, pipeItem, spritea, pipeType);
	
	player = getSpecificPlayer(player);
	getCell():setDrag(pipe, player:getPlayerNum());
end


WaterPipeMenu.onRemovePipe = function(worldobjects, player, pipe, square, time)
	if luautils.walkAdj(getSpecificPlayer(player), square) then
		ISTimedActionQueue.add(removePipeAction:new(getSpecificPlayer(player), pipe, square, time));
	end
end

---
--
--


function WaterPipeMenu.onBarrelInfo(worldobjects, player, square, barrel)
	if square and barrel then
		if luautils.walkAdj(getSpecificPlayer(player), square) then
			ISTimedActionQueue.add(ISBarrelInfoAction:new(getSpecificPlayer(player), WaterPipeMenu.currentBarrel));
		end
	end
end


Events.OnFillWorldObjectContextMenu.Add(WaterPipeMenu.doPipeMenu);
