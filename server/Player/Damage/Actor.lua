
Network:Subscribe( 'DamageActor', function( WNO, sender )
	if sender == nil or not IsValid( sender ) then return end
	if not WNO or not IsValid( WNO ) then return end
	local actor = AM.actors_id[WNO:GetId()]

	if not actor then return end

	local weapon = sender:GetEquippedWeapon()

	if not weapon then return end

	local weapon_info = WI:GetWeaponInfo( weapon.id )

	if not weapon_info then return end

	if actor.Damage then
		actor:Damage( sender, weapon_info )
	end
end )