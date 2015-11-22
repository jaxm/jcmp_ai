-- ai defines

AiGoal = {
	Wander = 0,
	Guard = 1,
	Patrol = 2,
	Pursue = 3,
	Panic = 4,
	Driver = 5,
	VehiclePassenger = 6,
	VehicleGunner = 7,
	ArmedDriver = 8,
	Traffic = 9,
	Zombie = 10,
	HeliGuard = 11,
	TaxiDriver = 12,
	RescueObjective = 13,
	toString = {}
}
AiGoal.toString[0] = 'Wander'
AiGoal.toString[1] = 'Guard'
AiGoal.toString[2] = 'Patrol'
AiGoal.toString[3] = 'Pursue'
AiGoal.toString[4] = 'Panic'
AiGoal.toString[5] = 'Driver'
AiGoal.toString[6] = 'VehiclePassenger'
AiGoal.toString[7] = 'VehicleGunner'
AiGoal.toString[8] = 'ArmedDriver'
AiGoal.toString[9] = 'Traffic'
AiGoal.toString[10] = 'Zombie'
AiGoal.toString[11] = 'HeliGuard'
AiGoal.toString[12] = 'TaxiDriver'
AiGoal.toString[13] = 'RescueObjective'

AiDrivingVehicleModifier = {}
AiDrivingVehicleModifier[18] = { -- tank
	max_speed = 1,
	acceleration_rate = .1,
	brake_rate = .1,
	turn_rate = 50,
	turn_slow_rate = .25,
	max_corner_speed = 1.5
}

AiDrivingVehicleModifier[7] = { -- Poloma Renegade 'ute'
	max_speed = 30,
	acceleration_rate = .15,
	brake_rate = .2,
	turn_rate = 50,
	turn_slow_rate = .25,
	max_corner_speed = 8
}

AiDrivingVehicleModifier[22] = { -- Tuk-Tuk Laa
	max_speed = 24,
	acceleration_rate = .15,
	brake_rate = .2,
	turn_rate = 50,
	turn_slow_rate = .25,
	max_corner_speed = 8
}

AiDrivingVehicleModifier[23] = { -- Chevalier Liner SB
	max_speed = 30,
	acceleration_rate = .15,
	brake_rate = .2,
	turn_rate = 50,
	turn_slow_rate = .25,
	max_corner_speed = 8
}

AiDrivingVehicleModifier[55] = { -- Sakura Aquila Metro ST
	max_speed = 30,
	acceleration_rate = .3,
	brake_rate = .4,
	turn_rate = 50,
	turn_slow_rate = .1,
	max_corner_speed = 8
}

AiDrivingVehicleModifier[70] = { -- taxi
	max_speed = 30,
	acceleration_rate = .15,
	brake_rate = .2,
	turn_rate = 50,
	turn_slow_rate = .1,
	max_corner_speed = 8
}

AiDrivingVehicleModifier[71] = { -- garbage
	max_speed = 12, --9
	acceleration_rate = .08,
	brake_rate = .1,
	turn_rate = 45,
	turn_slow_rate = .1,
	max_corner_speed = 4
}

AiDrivingVehicleModifier[78] = { -- Civadier 999
	max_speed = 30,
	acceleration_rate = .4,
	brake_rate = .8,
	turn_rate = 50,
	turn_slow_rate = .1,
	max_corner_speed = 20
}

-- gamemode defines

Mode = {
	Initializing = 0,
	Running = 1,
	Failed = 2,
	Success = 3,
	Cleanup = 4,
	Intro = 5,
	PostRound = 6,
	WaitingForPlayers = 7
}