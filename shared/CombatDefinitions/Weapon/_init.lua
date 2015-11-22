----------------------------------------------
class 'WeaponInfo'
function WeaponInfo:__init( ... )
	self.weapons = {}

	self.vehicle_weapons = {}
	self:AddWeapon( { 
		id = 2,
		name = 'Beretta Handgun',
		max_range = 100,
		max_ammo = 96,
		clip_size = 12,
		damage = 40,
		ammo_price = 2,
		v_damage_factor = .25,
		vertical_recoil = .058, --0.032,
		horizontal_recoil = 0.015,
		ac_fire_rate = 130,
		ai_fire_rate = 400,
		firemode = 0
	}) -- 12
	self:AddWeapon( {
		id = 4,
		name = 'Revolver',
		max_range = 100,
		max_ammo = 70,
		clip_size = 7,
		damage = 115,
		ammo_price = 3,
		v_damage_factor = .25,
		vertical_recoil = 0.5, --0.08,
		horizontal_recoil = 0.015,
		ac_fire_rate = 900,
		ai_fire_rate = 800,
		firemode = 0
	}) -- 7
	self:AddWeapon( {
		id = 5,
		name = 'Scorpion SMG',
		max_range = 300,
		max_ammo = 300,
		clip_size = 30,
		damage = 35,
		ammo_price = 4,
		v_damage_factor = .25,
		vertical_recoil = 0.03,
		horizontal_recoil = 0.015,
		ac_fire_rate = 70,
		ai_fire_rate = 250,
		firemode = 1
	 }) -- 30
	self:AddWeapon( {
		id = 6,
		name = 'Onehand Shotgun',
		max_range = 100,
		max_ammo = 54,
		clip_size = 3,
		damage = 30,
		ammo_price = 4,
		v_damage_factor = .25,
		vertical_recoil = 0.1,
		horizontal_recoil = 0.015,
		ac_fire_rate = 400,
		ai_fire_rate = 1600,
		firemode = 0
	}) -- 3
	self:AddWeapon( {
		id = 11,
		name = 'Assault',
		max_range = 300,
		max_ammo = 200,
		clip_size = 20,
		damage = 51,
		ammo_price = 5,
		v_damage_factor = .25,
		vertical_recoil = 0.05,
		horizontal_recoil = 0.015,
		ac_fire_rate = 100,
		ai_fire_rate = 250,
		firemode = 1
	 }) -- 20
	self:AddWeapon( {
		id = 13,
		name = 'Pump-Action Shotgun',
		max_range = 100,
		max_ammo = 72,
		clip_size = 6,
		damage = 30,
		ammo_price = 6,
		v_damage_factor = .25,
		vertical_recoil = 0.1,
		horizontal_recoil = 0.015,
		ac_fire_rate = 300,
		ai_fire_rate = 1600,
		firemode = 0
	}) -- 6
	self:AddWeapon( {
		id = 14,
		name = 'Sniper',
		max_range = 900,
		max_ammo = 80,
		clip_size = 4,
		damage = 600,
		ammo_price = 8,
		v_damage_factor = .1,
		vertical_recoil = 0.8, -- 0.06
		horizontal_recoil = 0.3,
		ac_fire_rate = 1000,
		ai_fire_rate = 3000,
		ai_aim_time = 1000,
		firemode = 0
	}) -- 4
	self:AddWeapon( {
		id = 16,
		name = 'Rocketlauncher',
		max_range = 500,
		max_ammo = 6,
		clip_size = 3,
		damage = 500,
		ammo_price = 15,
		v_damage_factor = 4,
		vertical_recoil = 0.1,
		horizontal_recoil = 0.015,
		ac_fire_rate = 500,
		ai_fire_rate = 3000,
		firemode = 0
	}) -- 3
	self:AddWeapon( {
		id = 17,
		name = 'Grenadelauncher',
		max_range = 300,
		max_ammo = 10,
		clip_size = 5,
		damage = 350,
		ammo_price = 15,
		v_damage_factor = 1,
		vertical_recoil = 0.1,
		horizontal_recoil = 0.015,
		ac_fire_rate = 130,
		ai_fire_rate = 1500,
		firemode = 0
	}) -- 5
	self:AddWeapon( {
		id = 26,
		max_range = 600,
		max_ammo = 0,
		clip_size = 0,
		damage = 20,
		ammo_price = 0,
		v_damage_factor = .25,
		vertical_recoil = 0.01,
		horizontal_recoil = 0.015,
		ac_fire_rate = 130,
		ai_fire_rate = 250,
		firemode = 1
	 }) -- 26
	self:AddWeapon( {
		id = 28,
		name = 'Machine Gun',
		max_range = 300,
		max_ammo = 312,
		clip_size = 26,
		damage = 62,
		ammo_price = 5,
		v_damage_factor = .25,
		vertical_recoil = 0.05, -- 0.05
		horizontal_recoil = 0.015,
		ac_fire_rate = 130,
		ai_fire_rate = 250,
		firemode = 1

	 }) -- 26
	self:AddWeapon( {
		id = 43,
		name = 'Bubble Gun',
		max_ammo = 0,
		clip_size = 0,
		damage = 0,
		ammo_price = 0,
		v_damage_factor = 0,
		vertical_recoil = 0,
		horizontal_recoil = 0,
		ac_fire_rate = 130,
		ai_fire_rate = 250,
		firemode = 1
	 }) -- 43

	-- vehicle weapon definitions

	local t = {
		min_pitch = -10,
		max_pitch = 10,
		min_yaw = -10,
		max_yaw = 10,
		min_roll = -10,
		max_roll = 10
	}

	 -- Cannon weapon_11
	self:AddVehicleWeapon( { 
		id = 34,
		w_type = 1,
		damage = 1500,
		p_speed = 400,
		fire_rate = 0.75,
		max_range = 1000,
		damage_radius = 3.5,
		v_damage_factor = 2,
		aim_constraints = nil
		}
	)

	 -- Vulcan weapon_12
	self:AddVehicleWeapon( { 
		id = 26,
		w_type = 0,
		damage = 80,
		p_speed = 1000,
		fire_rate = 0.15, --0.01
		max_range = 1500,
		damage_radius = 1,
		v_damage_factor = 1.5,
		aim_constraints = nil
		}
	)
	 -- RocketARVE weapon_13
	self:AddVehicleWeapon( { 
		id = 116,
		w_type = 1,
		damage = 1000,
		p_speed = 200,
		fire_rate = 0.5,
		max_range = 1500,
		damage_radius = 3.5,
		v_damage_factor = 4,
		aim_constraints = t
		}
	)
	 -- MachineGunLAVE weapon_20
	self:AddVehicleWeapon( { 
		id = 128,
		w_type = 0,
		damage = 80,
		p_speed = 750,
		fire_rate = 0.1332,
		max_range = 300,
		damage_radius = 1,
		v_damage_factor = .5,
		aim_constraints = t
		}
	)
	 -- CannonLAVE weapon_22
	self:AddVehicleWeapon( { 
		id = 134,
		w_type = 1,
		damage = 1500,
		p_speed = 400,
		fire_rate = 0.75,
		max_range = 1000,
		damage_radius = 3.5,
		v_damage_factor = 1.5,
		aim_constraints = nil
		}
	)
	 -- V039-VHLGL_R weapon_47
	self:AddVehicleWeapon( { 
		id = 139,
		w_type = 1,
		damage = 350,
		p_speed = 60,
		fire_rate = 0.325,
		max_range = 300,
		damage_radius = 4,
		v_damage_factor = 1.5,
		aim_constraints = nil
		}
	)
	 -- HeavyMachineGun weapon_26
	self:AddVehicleWeapon( { 
		id = 129,
		w_type = 0,
		damage = 80,
		p_speed = 750,
		fire_rate = 0.1332,
		max_range = 300,
		damage_radius = 0.5,
		v_damage_factor = .5,
		aim_constraints = nil
		}
	)
end

function WeaponInfo:GetWeaponInfo( n )
	return self.weapons[n]
end

function WeaponInfo:GetVehicleWeaponInfo( n )
	return self.vehicle_weapons[n]
end

function WeaponInfo:AddWeapon( t )
	local obj = SWeapon( t )
	self.weapons[t.id] = obj
end

function WeaponInfo:AddVehicleWeapon( t )
	local obj = SVehicleWeapon( t )
	self.vehicle_weapons[t.id] = obj
end

-----------------------------------------------------------------------------

class 'SWeapon'

function SWeapon:__init( t )
	self.id = t.id
	self.name = t.name
	self.max_ammo = t.max_ammo
	self.clip_size = t.clip_size
	self.damage = t.damage
	self.ammo_price = t.ammo_price
	self.vehicle_damage = t.v_damage_factor
	self.vertical_recoil = t.vertical_recoil
	self.horizontal_recoil = t.horizontal_recoil
	self.max_range = t.max_range
	self.ac_fire_rate = t.ac_fire_rate
	self.ai_fire_rate = t.ai_fire_rate
	self.firemode = t.firemode

	self.is_shotgun = false

	if self.id == 6 or self.id == 13 then
		self.is_shotgun = true
	end
end

function SWeapon:GetAmmoPrice( ... )
	return self.ammo_price
end

function SWeapon:max_ammo( ... )
	return self.maxammo
end

function SWeapon:ClipSize( ... )
	return self.clip_size
end

function SWeapon:Damage( ... )
	return self.damage
end

----------------------------------------------
--id, w_type, damage, p_speed, fire_rate, max_range, damage_radius, aim_constraints

class 'SVehicleWeapon'

function SVehicleWeapon:__init( t )

	self.id = t.id
	self.w_type = t.w_type
	self.damage = t.damage
	self.p_speed = t.p_speed
	self.fire_rate = t.fire_rate
	self.max_range = t.max_range
	self.damage_radius = t.damage_radius
	self.vehicle_damage = t.v_damage_factor
	self.spread = .5

	self.has_aim_constraints = false

	if t.aim_constraints ~= nil then
		self.has_aim_constraints = true

		self.min_pitch = t.aim_constraints.min_pitch
		self.max_pitch = t.aim_constraints.max_pitch
		self.min_yaw = t.aim_constraints.min_yaw
		self.max_yaw = t.aim_constraints.max_yaw
		self.min_roll = t.aim_constraints.min_roll
		self.max_roll = t.aim_constraints.max_roll
	end
end



----------------------------------------------

WI = WeaponInfo()

function GetWeaponSlot( weaponid )
	local slot = 0
	if weaponid == 2 or weaponid == 4 or weaponid == 5 or weaponid == 6 or weaponid == 17 then
		slot = 1
	else
		slot = 2
	end

	return slot
end