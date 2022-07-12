
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

require "ISUI/ISCollapsableWindow"

ISBarrelInfoWindow = ISCollapsableWindow:derive("ISBarrelInfoWindow");


function ISBarrelInfoWindow:initialise()

	ISCollapsableWindow.initialise(self);
end

function ISBarrelInfoWindow:visible(visible)
	ISBarrelInfoWindow.instance:setVisible(visible);
end

function ISBarrelInfoWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	self.barrelPanel = ISBarrelInfo:new(0, 16, self.width, self.height-16, self.barrel);
	self.barrelPanel:initialise();
	self:addChild(self.barrelPanel);
end

function ISBarrelInfoWindow:new (x, y, width, height, barrel)
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	self.barrelPanel = {};
	o.barrel = barrel;
	return o
end
