Network:Subscribe( 'DamageVehicle', function( vehicle, sender )
	if not sender or not IsValid(sender) then return end
	if not vehicle or not IsValid(vehicle) then return end

	-- if the vehicle isn't invulnerable, its likely being driven by a player
	-- return here so we don't apply standard game damage + custom damage system damage to the vehicle
	if not vehicle:GetInvulnerable() then return end

	local weapon = sender:GetEquippedWeapon()
	if not weapon then return end
	local weapon_info = WI:GetWeaponInfo( weapon.id )

	if not weapon_info then return end
	local damage = weapon_info.damage

	-- shotgun modifier
	if weapon_info.is_shotgun then
		local distance = sender:GetPosition():Distance( vehicle:GetPosition() )
		local ratio = 1 - distance / 60
		local base_damage = Copy( damage )
		damage = ceil(base_damage * (8*ratio))
	end

	-- NPC modifier, double damage vs NPC vehicles
	if vehicle:GetValue( 'NPCDriver' ) ~= nil then
		damage = damage * 2
	end

	local model = vehicle:GetModelId()

	local v_info = VI:GetVehicle( model )
	local max_health = v_info.health
	local current_health = vehicle:GetHealth() * max_health
	if current_health > 0 then
		local armour = v_info.armour

		local damage = damage * weapon_info.vehicle_damage

		local new_health = current_health - damage
		vehicle:SetHealth( new_health / max_health )
	end
end )