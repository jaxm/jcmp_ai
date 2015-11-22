
HeatTimer = Timer()

Events:Subscribe( 'NetworkObjectValueChange', function( e )
	local object = e.object

	if object.__type ~= 'LocalPlayer' then return end

	if object ~= LocalPlayer then return end
	local key = e.key
	local value = e.value

	if key == 'heat_level' then
		if value > 0 then
			Game:SetHeat( HeatLevel.Red, value*.2 )
			HeatTimer:Restart()
		else
			Game:SetHeat( HeatLevel.None, 0 )
		end
	end
end )
