
FactionActorModels = {}
FactionActorModels[0] = { 6, 48, 57, 76, 78, 82, 94, 1, 7, 10, 13, 14, 21, 24, 35, 37 } -- civilian
FactionActorModels[1] = { 52, 61, 66, 101 } -- PanauMilitary
FactionActorModels[2] = { 8, 12, 63 } -- Reapers
FactionActorModels[3] = { 32, 59, 85, 5 } -- Roaches
FactionActorModels[4] = { 22, 27, 87, 103 } -- Ular
FactionActorModels[5] = { 30, 25, 34 } -- Agency

FactionDecals = {}
FactionDecals[0] = 'Taxi'
FactionDecals[1] = 'MilStandard'
FactionDecals[2] = 'Reapers'
FactionDecals[3] = 'Roaches'
FactionDecals[4] = 'UlarBoys'

FactionVehicleColours = {}
FactionVehicleColours[1] = { 
	{ col1 = Color(77, 85, 72), col2 = Color(77, 85, 72) }, -- military
	{ col1 = Color(140, 140, 150), col2 = Color(140, 140, 150) }, -- arctic1
	{ col1 = Color(170, 170, 160), col2 = Color(170, 170, 160) }, -- arctic2
	{ col1 = Color(145, 150, 165), col2 = Color(145, 150, 165) }, -- arctic3
	{ col1 = Color(200, 160, 102), col2 = Color(175, 141, 124) }, -- desert1
	{ col1 = Color(170, 160, 100), col2 = Color(155, 140, 121) }, -- desert2
	{ col1 = Color(129, 123, 111), col2 = Color(138, 126, 115) }, -- desert3
	{ col1 = Color(65, 72, 65), col2 = Color(73, 83, 73) }, -- jungle1
	{ col1 = Color(64, 83, 55), col2 = Color(87, 100, 55) }, -- jungle2
	{ col1 = Color(85, 85, 65), col2 = Color(95, 100, 75) } -- jungle3
}
FactionVehicleColours[2] = { 
	{ col1 = Color(36, 3, 4), col2 = Color(113, 48, 9) }
}
FactionVehicleColours[3] = { 
	{ col1 = Color(24, 113, 137), col2 = Color(54, 126, 139) }
}
FactionVehicleColours[4] = {
	{ col1 = Color(180, 135, 0), col2 = Color(180, 135, 0) }
}
FactionVehicleColours[5] = { 
	{ col1 = Color(60, 60, 60), col2 = Color(60, 60, 65) },
	{ col1 = Color(40, 40, 40), col2 = Color(40, 40, 45) }
}


function GetFactionInfo( faction )
	local t = {}
	t.actorModels = FactionActorModels[faction]
	t.vehicleColours = FactionVehicleColours[faction]
	t.decal = FactionDecals[faction]
	return t
end