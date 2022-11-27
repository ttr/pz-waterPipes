
---- Garden Hoses By Kyun, thanks to Robert Johnson for it's rain collector barrel and farming mod (among others !)

Events.OnGameStart.Add( function ()
	if NecroList then
		if NecroList.Items.WaterPipe then		
		else
			-- print("Adding garden hose to necro list");
			NecroList.Items.WaterPipe = {"Farming", nil, nil, "Irrigation Pipe", "waterPipes.WaterPipe2", "Item_WaterPipe", nil, nil, nil};
		end
	end
	
	-- add garbage bag
	--if NecroList then
		--if NecroList.Items.Garbagebag then		
		--else
			--print("Adding garbage bags to necro list");
			--NecroList.Items.Garbagebag = {"Carpentry", nil, nil, "Garbage bag", "Base.Garbagebag", "Item_Garbagebag", nil, nil, nil};
			-- NecroList.Items.radio = {"Carpentry", nil, nil, "radio", "Recycling.Radio", "Item_DVDplayer", nil, nil, nil};
		--end
	--end
end)