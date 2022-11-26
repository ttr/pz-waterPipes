
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

require "TimedActions/ISBaseTimedAction"

removePipeAction = ISBaseTimedAction:derive("removePipeAction");

---
--
--
function removePipeAction:isValid()
	return true;
end


---
--
--
function removePipeAction:update()
end


---
--
--
function removePipeAction:start()
end


---
--
--
function removePipeAction:stop()
    ISBaseTimedAction.stop(self);
end


---
--
--
function removePipeAction:perform()
	if isClient() then
		local args = { x = self.square:getX(), y = self.square:getY(), z = self.square:getZ()}
		sendClientCommand('waterPipe', 'pickUp', args)
	else
		local pipe = WaterPipe.getPipeAt(self.square:getX(),self.square:getY(),self.square:getZ())
		Pipe.onPickUp(pipe, self.character);
	end
	
	ISBaseTimedAction.perform(self);
end


---
--
--
function removePipeAction:new(character, pipe, square, time)
	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o.character = character;
	o.pipe = pipe;
	o.square = square;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	return o;
end