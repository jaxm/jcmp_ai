-- VehicleManger.lua

class 'VehicleInfo'

function VehicleInfo:__init( ... )
	self.vehicles = {}

	self:AddVehicle( 1, "Dongtai Agriboss 35", 15, 2500, .8 )
	self:AddVehicle( 2, "Mancini Cavallo 1001", 15, 2500, .8 )
	self:AddVehicle( 4, "Kenwall Heavy Rescue", 15, 2500, .8 )
	self:AddVehicle( 7, "Poloma Renegade", 15, 2500, .8 )
	self:AddVehicle( 8, "Columbi Excelsior", 15, 2500, .8 )
	self:AddVehicle( 9, "Tuk-Tuk Rickshaw", 15, 2500, .8 )
	self:AddVehicle( 10, "Saas PP12 Hogg", 15, 2500, .8 )
	self:AddVehicle( 11, "Shimuzu Tracline", 15, 2500, .8 )
	self:AddVehicle( 12, "Vanderbildt LeisureLiner", 15, 2500, .8 )
	self:AddVehicle( 13, "Stinger Dunebug 84", 15, 2500, .8 )
	self:AddVehicle( 15, "Sakura Aquila Space", 15, 2500, .8 )
	self:AddVehicle( 18, "SV-1003 Raider", 40, 3500, .5 )
	self:AddVehicle( 21, "Hamaya Cougar 600", 15, 2500, .8 )
	self:AddVehicle( 20, "(DLC) Monster Truck", 15, 2500, .8 )
	self:AddVehicle( 22, "Tuk-Tuk Laa", 15, 2500, .8 )
	self:AddVehicle( 23, "Chevalier Liner SB", 15, 2500, .8 )
	self:AddVehicle( 26, "Chevalier Traveller SD", 15, 2500, .8 )
	self:AddVehicle( 29, "Sakura Aquila City", 15, 2500, .8 )
	self:AddVehicle( 31, "URGA-9380", 15, 2500, .8 )
	self:AddVehicle( 32, "Mosca 2000", 15, 2500, .8 )
	self:AddVehicle( 33, "Chevalier Piazza IX", 15, 2500, .8 )
	self:AddVehicle( 35, "Garret Traver-Z", 15, 2500, .8 )
	self:AddVehicle( 36, "Shimuzu Tracline", 15, 2500, .8 )
	self:AddVehicle( 40, "Fengding EC14FD2", 15, 2500, .8 )
	self:AddVehicle( 41, "Niseco Coastal D22", 15, 2500, .8 )
	self:AddVehicle( 42, "Niseco Tusker P246", 15, 2500, .8 )
	self:AddVehicle( 43, "Hamaya GSY650", 15, 2500, .8 )
	self:AddVehicle( 44, "Hamaya Oldman", 15, 2500, .8 )
	self:AddVehicle( 46, "MV V880", 15, 2500, .8 )
	self:AddVehicle( 47, "Schulz Virginia", 15, 2500, .8 )
	self:AddVehicle( 48, "Maddox FVA 45", 15, 2500, .8 )
	self:AddVehicle( 49, "Niseco Tusker D18", 15, 2500, .8 )
	self:AddVehicle( 52, "Saas PP12 Hogg", 15, 2500, .8 )
	self:AddVehicle( 54, "Boyd Fireflame 544", 15, 2500, .8 )
	self:AddVehicle( 55, "Sakura Aquila Metro ST", 15, 2500, .8 )
	self:AddVehicle( 56, "GV-104 Razorback", 40, 8000, .8 )
	self:AddVehicle( 58, "(DLC) Chevalier Classic", 15, 2500, .8 )
	self:AddVehicle( 60, "Vaultier Patrolman", 15, 2500, .8 )
	self:AddVehicle( 61, "Makoto MZ 260X", 15, 2500, .8 )
	self:AddVehicle( 63, "Chevalier Traveller SC", 15, 2500, .8 )
	self:AddVehicle( 66, "Dinggong 134D", 15, 2500, .8 )
	self:AddVehicle( 68, "Chevalier Traveller SX", 15, 2500, .8 )
	self:AddVehicle( 70, "Sakura Aguila Forte", 15, 2500, .8 )
	self:AddVehicle( 71, "Niseco Tusker G216", 15, 2500, .8 )
	self:AddVehicle( 72, "Chepachet PVD", 15, 2000, .8 )
	self:AddVehicle( 73, "Chevalier Express HT", 15, 2500, .8 )
	self:AddVehicle( 74, "Hamaya 1300 Elite Cruiser", 15, 2500, .8 )
	self:AddVehicle( 75, "(DLC) Tuk Tuk Boom Boom", 15, 2500, .8 )
	self:AddVehicle( 76, "SAAS PP30 Ox", 15, 2500, .8 )
	self:AddVehicle( 77, "Hedge Wildchild", 15, 2500, .8 )
	self:AddVehicle( 78, "Civadier 999", 15, 2500, .8 )
	self:AddVehicle( 79, "Pocumtuck Nomad", 15, 2500, .8 )
	self:AddVehicle( 82, "(DLC) Chevalier Ice Breaker", 15, 2500, .8 )
	self:AddVehicle( 83, "Mosca 125 Performance", 15, 2500, .8 )
	self:AddVehicle( 84, "Marten Storm III", 20, 2000, .8 )
	self:AddVehicle( 86, "Dalton N90", 15, 2500, .8 )
	self:AddVehicle( 87, "Wilforce Trekstar", 15, 2500, .8 )
	self:AddVehicle( 89, "Hamaya Y250S", 15, 2500, .8 )
	self:AddVehicle( 90, "Makoto MZ 250", 15, 2500, .8 )
	self:AddVehicle( 91, "Titus ZJ", 15, 2500, .8 )
	self:AddVehicle( 5, "Pattani Gluay", 15, 2500, .8 )
	self:AddVehicle( 6, "Orque Grandois 21TT", 15, 2500, .8 )
	self:AddVehicle( 16, "YP-107 Phoenix", 15, 2500, .8 )
	self:AddVehicle( 19, "Orque Living 42T", 15, 2500, .8 )
	self:AddVehicle( 25, "Trat Tang-mo", 15, 2500, .8 )
	self:AddVehicle( 27, "SnakeHead T20", 15, 2500, .8 )
	self:AddVehicle( 28, "TextE Charteu 52CT", 15, 2500, .8 )
	self:AddVehicle( 38, "Kuang Sunrise", 15, 2500, .8 )
	self:AddVehicle( 45, "Orque Bon Ton 71FT", 15, 2500, .8 )
	self:AddVehicle( 50, "Zhejiang 6903", 15, 2500, .8 )
	self:AddVehicle( 53, "(DLC) Agency Hovercraft", 15, 2500, .8 )
	self:AddVehicle( 69, "Winstons Amen 69", 15, 2500, .8 )
	self:AddVehicle( 80, "Frisco Catshark S-38", 15, 2500, .8 )
	self:AddVehicle( 88, "MTA Powerrun 77", 15, 2500, .8 )
	self:AddVehicle( 3, "Rowlinson K22", 10, 1500, 1.5 )
	self:AddVehicle( 14, "Mullen Skeeter Eagle", 10, 1500, 1.5 )
	self:AddVehicle( 24, "(DLC) F-33 DragonFly Jet Fighter", 10, 1500, 1.5 )
	self:AddVehicle( 30, "Si-47 Leopard", 10, 1500, 1.5 )
	self:AddVehicle( 34, "G9 Eclipse", 10, 1500, 1.5 )
	self:AddVehicle( 37, "Sivirkin 15 Havoc", 10, 1500, 1.5 )
	self:AddVehicle( 39, "Aeroliner 474", 10, 1500, 1.5 )
	self:AddVehicle( 51, "Cassius 192", 10, 1500, 1.5 )
	self:AddVehicle( 57, "Sivirkin 15 Havoc", 10, 1500, 1.5 )
	self:AddVehicle( 59, "Peek Airhawk 225", 10, 1500, 1.5 )
	self:AddVehicle( 62, "UH-10 Chippewa", 10, 1500, 1.5 )
	self:AddVehicle( 64, "AH-33 Topachula", 10, 1500, 1.5 )
	self:AddVehicle( 65, "H-62 Quapaw", 10, 1500, 1.5 )
	self:AddVehicle( 67, "Mullen Skeeter Hawk", 10, 1500, 1.5 )
	self:AddVehicle( 81, "Pell Silverbolt 6", 10, 1500, 1.5 )
	self:AddVehicle( 85, "Bering I-86DP", 10, 1500, 1.5 )

	self.weapon_type = {
		primary = 1, 
		secondary = 2
	}

	local tank_cannon = WI:GetVehicleWeaponInfo( 34 )

	local vulcan = WI:GetVehicleWeaponInfo( 26 )

	local MachineGunLAVE = WI:GetVehicleWeaponInfo( 128 )

	local RocketARVE = WI:GetVehicleWeaponInfo( 116 )

	local vehicle_offset = Vector3()
	local weapon_offset_table = { Vector3(), Vector3() }

	self:AddVehicleWeapon( 18, 'Cannon', self.weapon_type.secondary, tank_cannon, 1, vehicle_offset, weapon_offset_table )
	weapon_offset_table = { {dir = Vector3.Left, amount = .7}, { dir = Vector3.Right, amount = .7 } }
	self:AddVehicleWeapon( 56, 'WeaponUpgrade1', self.weapon_type.secondary, tank_cannon, 1, Vector3(0,1.45,.5), weapon_offset_table, true )
	self:AddVehicleWeapon( 56, 'WeaponUpgrade1', self.weapon_type.primary, MachineGunLAVE, 2, Vector3(0,3,1.35), weapon_offset_table, true )
	weapon_offset_table = { {dir = Vector3.Left, amount = 2.75}, { dir = Vector3.Right, amount = 2.75 } }
	self:AddVehicleWeapon( 30, 'Default', self.weapon_type.primary, MachineGunLAVE, 2, Vector3(0,1.45,0), weapon_offset_table )
	self:AddVehicleWeapon( 30, 'Default', self.weapon_type.secondary, RocketARVE, 2, Vector3(0,1.45,0), weapon_offset_table )
	self:AddVehicleWeapon( 34, 'Default', self.weapon_type.primary, MachineGunLAVE, 4, vehicle_offset, weapon_offset_table )
	self:AddVehicleWeapon( 34, 'Default', self.weapon_type.secondary, RocketARVE, 4, vehicle_offset, weapon_offset_table )
	weapon_offset_table = { {dir = Vector3.Left, amount = 1.85}, { dir = Vector3.Right, amount = 1.85 } }
	self:AddVehicleWeapon( 62, 'Armed', self.weapon_type.primary, vulcan, 2, Vector3(0,.75,0), weapon_offset_table )
	weapon_offset_table = { {dir = Vector3.Left, amount = .24}, { dir = Vector3.Right, amount = .24 } }
	self:AddVehicleWeapon( 88, 'WeaponUpgrade0', self.weapon_type.primary, MachineGunLAVE, 2, Vector3(0,1.8,.55), weapon_offset_table )

	-- gunner seats

	self:AddVehicleGunnerSeat( 18, 'Default', vulcan )
	self:AddVehicleGunnerSeat( 48, 'BuggyMG', vulcan )
	self:AddVehicleGunnerSeat( 56, 'Default', vulcan )
	self:AddVehicleGunnerSeat( 72, 'Default', MachineGunLAVE )
	self:AddVehicleGunnerSeat( 69, 'Military', vulcan )
	self:AddVehicleGunnerSeat( 84, 'HardtopMG', vulcan )

	-- extended vehicle properties

	self.vehicles[18].properties.protected = true

end

function VehicleInfo:AddVehicle( id, name, armour, health, velocity_factor )
	local obj = SVehicle( id, name, armour, health, velocity_factor )
	self.vehicles[id] = obj
end

function VehicleInfo:GetVehicle( id )
	return self.vehicles[id]
end

function VehicleInfo:AddVehicleWeapon( id, template, slot, weapon, amount, vehicle_offset, weapon_offset_table, has_turret )
	local vehicle = self.vehicles[id]

	if vehicle ~= nil then

		if vehicle.variation[template] == nil then
			vehicle.variation[template] = {}
		end

		if has_turret == nil then
			has_turret = false
		end

		if slot == self.weapon_type.primary then
			--[[vehicle.has_primary_weapon = true
			vehicle.primary_weapon = weapon
			vehicle.number_of_primarys = amount]]

			vehicle.variation[template].has_primary_weapon = true
			vehicle.variation[template].primary_weapon = weapon
			vehicle.variation[template].number_of_primarys = amount
			vehicle.variation[template].vehicle_offset = vehicle_offset
			vehicle.variation[template].weapon_offset_table = weapon_offset_table
			vehicle.variation[template].has_turret = has_turret

		else
			--[[vehicle.has_secondary_weapon = true
			vehicle.secondary_weapon = weapon
			vehicle.number_of_secondarys = amount]]

			vehicle.variation[template].has_secondary_weapon = true
			vehicle.variation[template].secondary_weapon = weapon
			vehicle.variation[template].number_of_secondarys = amount
			vehicle.variation[template].vehicle_offset = vehicle_offset
			vehicle.variation[template].weapon_offset_table = weapon_offset_table
			vehicle.variation[template].has_turret = has_turret

		end
	end
end

function VehicleInfo:GetDriverWeapons( id, template )
	local vehicle = self.vehicles[id]

	if not vehicle then return nil end

	local weapon_table = vehicle.variation[template]
	local t = {}
	if weapon_table then
		t[1] = weapon_table.primary_weapon
		t[2] = weapon_table.secondary_weapon
		return t
	end
end

function VehicleInfo:GetGunnerWeapon( id, template )
	local vehicle = self.vehicles[id]

	if not vehicle then return nil end

	if vehicle.variation[template] then
		return vehicle.variation[template].gunner_seat_weapon
	end
end

function VehicleInfo:AddVehicleGunnerSeat( id, template, weapon )
	local vehicle = self.vehicles[id]

	if vehicle ~= nil then

		if vehicle.variation[template] == nil then
			vehicle.variation[template] = {}
		end

		--[[vehicle.has_gunner_seat = true
		vehicle.gunner_seat_weapon = weapon]]

		vehicle.variation[template].has_gunner_seat = true
		vehicle.variation[template].gunner_seat_weapon = weapon

	end
end

class 'SVehicle'

function SVehicle:__init( id, name, armour, health, velocity_factor )
	self.id = id
	self.name = name
	self.armour = armour
	self.health = health
	self.velocity_factor = velocity_factor

	self.properties = {}

	self.variation = {}

	-- Vehicle Weapons
	--[[self.has_primary_weapon = false
	self.has_secondary_weapon = false
	self.number_of_primarys = 0
	self.primary_weapon = nil
	self.secondary_weapon = nil
	self.number_of_secondarys = 0
	
	--Vehicle Gunner Seats / Weapons
	self.has_gunner_seat = false
	self.gunner_seat_weapon = nil]]

	self.bounds ={
		top_left = nil,
		bottom_right = nil
	}
end

VI = VehicleInfo()