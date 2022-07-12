if isClient() then return end

require"RainBarrel/BuildingObjects/RainCollectorBarrel.lua"
require"RainBarrel/SRainBarrelSystem.lua"
WP_RCB = {};
WP_RCB.RainCollectorBarrelInitSystem = SRainBarrelSystem.initSystem;

function SRainBarrelSystem:initSystem()
	WP_RCB.RainCollectorBarrelInitSystem(self)
	-- Specify GlobalObject fields that should be saved.
	self.system:setObjectModDataKeys({'exterior', 'taintedWater', 'waterAmount', 'waterMax', 'fertilizerLvl', 'decimalPart'})
	print("irrigation rain collector barrel object modData keys added")

	self:convertOldModData()
end

WP_RCB.RainCollectorBarrelCreate = RainCollectorBarrel.create;


function RainCollectorBarrel:create(x, y, z, north, sprite)
	WP_RCB.RainCollectorBarrelCreate(self, x, y, z, north, sprite);

	self.javaObject:getModData()["fertilizerLvl"] = 0;
	self.javaObject:getModData()["decimalPart"] = 0;

	local barrel = nil;
	local square = getWorld():getCell():getGridSquare(x, y, z);
	local barrelsystem = SRainBarrelSystem.instance
	for i=1, barrelsystem:getLuaObjectCount() do
		local v = barrelsystem:getLuaObjectByIndex(i)
		if v.x == square:getX() and v.y == square:getY() and v.z == square:getZ() then
			barrel = v;
			break;
		end
	end

	if barrel ~= nil then
		barrel.fertilizerLvl = 0
		barrel.decimalPart = 0

	else
		print("RainCollectorBarrel:create: No barrel found at "..square:getX().."x"..square:getY().."x"..square:getZ().."!");
	end
end

WP_RCB.RainCollectorBarrelLoadRainBarrel = RainCollectorBarrel.loadRainBarrel;
function RainCollectorBarrel.loadRainBarrel(barrelObject)
	if not barrelObject or not barrelObject:getSquare() then return end
	WP_RCB.RainCollectorBarrelLoadRainBarrel(barrelObject);

	local square = barrelObject:getSquare()
	local barrel = nil;

	-- Find this barrel

	local barrelsystem = SRainBarrelSystem.instance
	for i=1, barrelsystem:getLuaObjectCount() do
		local v = barrelsystem:getLuaObjectByIndex(i)
		if v.x == square:getX() and v.y == square:getY() and v.z == square:getZ() then
			barrel = v;
			break;
		end
	end

	if not barrel then -- If this is nil, the parent function bugged. Error out.
		print("loadRainBarrel: No barrel found at "..square:getX().."x"..square:getY().."x"..square:getZ().."!");
		return;
	end

	-- compatibility stuff
	if not barrelObject:getModData()["fertilizerLvl"] then
		barrelObject:getModData()["fertilizerLvl"] = 0
		barrelObject:transmitModData();
	end
	if not barrelObject:getModData()["decimalPart"] then
		barrelObject:getModData()["decimalPart"] = 0
		barrelObject:transmitModData();
	end
	barrel.fertilizerLvl = barrelObject:getModData()["fertilizerLvl"]
	barrel.decimalPart = barrelObject:getModData()["decimalPart"]
end
