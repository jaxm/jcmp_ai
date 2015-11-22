
Events:Subscribe( 'PlayerEnterVehicle', function( e )

	-- we don't want vehicles to be invulnerable when they're being driven by a player
	-- otherwise NPC's can't deal damage to a player when they're inside a vehicle.

	local player = e.player
	if not player or not IsValid(player) then return end
	local vehicle = e.vehicle
	if not vehicle or not IsValid(vehicle) then return end

	if not e.is_driver then return end

	-- if there was a player in the vehicle before, we don't need to change anything
	if e.old_driver then return end

	if vehicle:GetInvulnerable() then
		vehicle:SetInvulnerable(false)
	end

end )

Events:Subscribe( 'PlayerExitVehicle', function( e )
	local player = e.player
	if not player or not IsValid(player) then return end
	local vehicle = e.vehicle
	if not vehicle or not IsValid(vehicle) then return end

	if not vehicle:GetDriver() then
		vehicle:SetInvulnerable(true)
	end
end )