class 'PlayerWeapon'

function PlayerWeapon:__init( ... )

	-- variables

	self.last_frame_ammo = 0

	self.events = {
		tick = Events:Subscribe( 'Render', self, self.Tick )
	}
end

function PlayerWeapon:Tick( ... )

	if LocalPlayer:InVehicle() then

	else
		local current_weapon = LocalPlayer:GetEquippedWeapon()

		if not current_weapon or current_weapon.id == 0 then self.last_frame_ammo = 0 return end

		if current_weapon.id == 26 then
			-- -- handle minigun
		else
			-- handle standard weapon
			if current_weapon.ammo_clip < self.last_frame_ammo then
				self:DamageTarget( LocalPlayer:GetAimTarget() )
			end
		end
		self.last_frame_ammo = current_weapon.ammo_clip
	end
end

function PlayerWeapon:DamageTarget( target )

	if target.entity then

		if target.entity.__type == 'ClientStaticObject' then

			local WNO = OM.object_aim[target.entity:GetId()]

			if not WNO or not WNO.network_object or not IsValid(WNO.network_object) then return end

			Network:Send( 'DamageObject', WNO.network_object )
		elseif target.entity.__type == 'ClientActor' then
			local WNO = AM.actor_aim[target.entity:GetId()]

			if not WNO or not WNO.network_object or not IsValid(WNO.network_object) then return end
			Network:Send( 'DamageActor', WNO.network_object )
		elseif target.entity.__type == 'Vehicle' then

			Network:Send( 'DamageVehicle', target.entity )
		end
	else
		Network:Send( 'BulletMissed' )
	end
end

PW = PlayerWeapon()