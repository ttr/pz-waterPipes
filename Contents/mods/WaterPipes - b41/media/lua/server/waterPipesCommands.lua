require "WaterPipe"

local Commands = {}

function Commands.pickUp(player, args)
	-- print("server received pickUp command")
	local pipe = WaterPipe.getPipeAt(args.x,args.y,args.z)
	Pipe.onPickUp(pipe, player);
end

function Commands.pourWater(player, args)
	local square = getWorld():getCell():getGridSquare(args.x, args.y, args.z);
	WaterPipe.pourWater(nil, args.barrel, args.uses, square);
end

function WaterPipe.OnClientCommand(module, command, player, args)
	if module ~= 'waterPipe' then return; end
	if Commands[command] then
		Commands[command](player, args)
	end
end

function WaterPipe.OnServerCommand(module, command, args)
	if not isClient() then return end
	if module ~= 'waterPipe' then return; end
	-- local argStr = ''
	-- for k,v in pairs(args) do argStr = argStr..' '..k..'='..v end
	-- print('OnServerCommand '..module..' '..command..argStr)
end

Events.OnServerCommand.Add(WaterPipe.OnServerCommand)

if isServer() then
	Events.OnClientCommand.Add(WaterPipe.OnClientCommand)
end