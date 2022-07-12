
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

require "TimedActions/ISBaseTimedAction"

pourWaterInBarrelAction = ISBaseTimedAction:derive("pourWaterInBarrelAction");

function pourWaterInBarrelAction:isValid()
	return true;
end

function pourWaterInBarrelAction:update()
	self.item:setJobDelta(self:getJobDelta());
end

function pourWaterInBarrelAction:start()
	self.item:setJobType("Water");
	self.item:setJobDelta(0.0);
end

function pourWaterInBarrelAction:stop()
	ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function pourWaterInBarrelAction:perform()
	self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
	
	if isClient() then
		local args = {barrel = self.barrel, uses = self.uses, x=self.square:getX(), y=self.square:getY(),z=self.square:getZ() }
		sendClientCommand('waterPipe', 'pourWater', args)
		-- ugly hack so server doesn't have to update client stuff
		for i = 1, self.uses do
			if self.item:getUsedDelta() > 0 then
				self.item:Use();
			else
				break;
			end
		end
		-- leave nothing less than 1 use
		if math.floor((self.item:getUsedDelta())/self.item:getUseDelta()) == 0 and self.item:getUsedDelta() > 0 then
			self.item:Use();
			self.item:setUsedDelta(0);
		end
	else
		WaterPipe.pourWater(self.item, self.barrel, self.uses, self.square);
	end
	
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

---
--
function pourWaterInBarrelAction:new(character, handItem, uses, square, barrel, time)
	local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.uses = uses;
	o.item = handItem;
	o.square = square;
	o.barrel = barrel;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o;
end