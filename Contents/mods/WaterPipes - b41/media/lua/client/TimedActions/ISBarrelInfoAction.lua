
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

require "TimedActions/ISBaseTimedAction"

ISBarrelInfoAction = ISBaseTimedAction:derive("ISBarrelInfoAction");

function ISBarrelInfoAction:isValid()
	return true;
end

function ISBarrelInfoAction:update()
end

function ISBarrelInfoAction:start()
end

function ISBarrelInfoAction:stop()
	ISBaseTimedAction.stop(self);
end

function ISBarrelInfoAction:perform()
	if WaterPipeMenu.info then
		WaterPipeMenu.info.barrelPanel:setBarrel(self.barrel);
		WaterPipeMenu.info:setVisible(true);
	else
		WaterPipeMenu.info = ISBarrelInfoWindow:new(300,200,220,120, self.barrel);
		WaterPipeMenu.info:initialise();
		WaterPipeMenu.info:addToUIManager();
	end
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISBarrelInfoAction:new(character, barrel)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
    o.barrel = barrel;
	o.maxTime = 0;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	return o;
end
