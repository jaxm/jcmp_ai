
Network:Subscribe( 'DamageObject', function( WNO, sender )
	if not sender or not IsValid( sender ) then return end

	if not WNO or not IsValid( WNO ) then return end

	local obj = IM.items_id[WNO:GetId()]

	if not obj then return end

	-- if you tracked player ammo server side, you would do
	-- an ammo check here to verify the player has ammo
	-- to cause damage to the object.

	obj:Damage( sender )
end )

-- if you wanted to track player accuracy

-- Network:Subscribe( 'BulletMissed', BulletMissed )