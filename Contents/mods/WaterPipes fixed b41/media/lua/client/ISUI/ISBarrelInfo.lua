
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

ISBarrelInfo = ISPanel:derive("ISBarrelInfo");

print("MOD DEBUG: ISBarrelInfo lua loaded")
function ISBarrelInfo:initialise()
	ISPanel.initialise(self);
end

function ISBarrelInfo:setBarrel(barrel)
	self.barrel = barrel;
end

function ISBarrelInfo:prerender()
	local square = getWorld():getCell():getGridSquare(self.barrel.x, self.barrel.y, self.barrel.z);
	if not square then self:getParent():setVisible(false); return end
	if isClient() then
		-- Hack: because the client does not have an up-to-date list of barrels		
		self.barrel = WaterPipe.getCurrentBarrel(square);
	end
	self:drawText(getText("IGUI_WaterPipe_BarrelInfo") , 32, - 14, 1,1,1,1);--getText("Farming_Plant_Information")
end


function ISBarrelInfo:render()
	
	local waterAmount = self.barrel.waterAmount;
	if self.barrel.decimalPart then
		waterAmount = waterAmount + self.barrel.decimalPart;
	end
	waterAmount = string.format("%.2f", waterAmount);

	if self.barrel.clusterWaterLevel then
		waterAmount = waterAmount .. "/" .. string.format("%.2f", self.barrel.clusterWaterLevel);
	end
	
	local description = "";
	description = description .. getText("IGUI_WaterPipe_WaterAmount", waterAmount) .. "\n";
	
	if self.barrel.fertilizerLvl then
		description = description .. getText("IGUI_WaterPipe_FertilizerAmount", self.barrel.fertilizerLvl) .. "\n";
	end
	
	self:drawText(description, 20, 25, 1, 1, 1, 1, UIFont.Small);
end

function ISBarrelInfo:new (x, y, width, height, barrel)
	local o = {}
	o = ISPanel:new(x, y, width, height);
	setmetatable(o, self)
    self.__index = self
	o.barrel = barrel;
   return o
end
