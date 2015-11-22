sin = math.sin
rad = math.rad
deg = math.deg
acos = math.acos
min = math.min
abs = math.abs
floor = math.floor
ceil = math.ceil
sqrt = math.sqrt
random = math.random
tGetMS = Timer.GetMilliseconds

debug_start_position = nil
debug_end_position = nil
-- Angle.Delta = function(q1, q2)
-- 	return ((math.acos(math.min(math.abs(q1:Dot(q2)), 1)) * 2))
-- end

Angle.NormalisedDir = function(a1, a2)
	return (a1 - a2):Normalized()
end

Angle.RotateToward = function(q1, q2, max_ang)
	local num = Angle.Delta(q1, q2)
	if num == 0 then
		return q2
	end

	-- t = math.min(1, (max_ang / num))
	t = min(1, (max_ang / num))

	return Angle.Slerp(q1, q2, t)
end

Angle.ToAngleAxis = function(q)
    local sqrLen = q.x*q.x + q.y*q.y + q.z*q.z
    
    local angle = 0
    local axis = Vector3(1, 0, 0)
    
    if sqrLen > 0 then
        -- angle = 2 * math.acos(q.w)
        angle = 2 * acos(q.w)
        axis = Vector3(q.x, q.y, q.z):Normalized()
    end
    
    return angle, axis
end

function DegreesDifference(theta1, theta2)
    return (theta2 - theta1 + 180) % 360 - 180
end

function OppositeDegrees(theta)
    return (theta + 180) % 360
end

function YawToHeading(yaw)
    if yaw < 0 then
        return -yaw
    else
        return 360 - yaw
    end
end

function HeadingToYaw(heading)
    if heading < 180 then
        return -heading
    else
        return 360 - heading
    end
end

function Vehicle:GetRoll()
    return math.deg(self:GetAngle().roll)
end

function Vehicle:GetPitch()
    return math.deg(self:GetAngle().pitch)
end

function Vehicle:GetYaw()
    return math.deg(self:GetAngle().yaw)
end

function Vehicle:GetHeading()
    local yaw = self:GetYaw()
    return YawToHeading(yaw)
end

function Vehicle:GetSpeed()
    return self:GetLinearVelocity():Length() * 3.6
end

function round(x) 
    if x<0 then return -round(-x) end 
    -- return  math.floor(x+0.5) 
    return floor(x+0.5) 
end 

function Distance2D( pos_from, pos_to )
	-- takes 2 vector3's and returns 2d distance
	if pos_from ~= nil and pos_to ~= nil then
		-- local distance = math.sqrt( (pos_to.x-pos_from.x)^2 + (pos_to.z-pos_from.z)^2 )
		local distance = sqrt( (pos_to.x-pos_from.x)^2 + (pos_to.z-pos_from.z)^2 )
		return distance
	end
	return 0
end

function UpdateTerrainHeight( position )
	local c_pos = Copy( position )

	c_pos.x = (round((c_pos.x) / 50) * 50)
	c_pos.z = (round((c_pos.z) / 50) * 50)

	local terrain_height = nil

	if HeightMap[c_pos.x] ~= nil then
		terrain_height = HeightMap[c_pos.x][c_pos.z]
	else
		terrain_height = position.y
	end

	return terrain_height
end

function GetTerrainHeight( position )
	local position = Copy(position)
	position.x = (round((position.x) / 50) * 50)
	position.z = (round((position.z) / 50) * 50)

	local terrain_height = 200 -- default for 200, which is sea level

	if HeightMap[position.x] ~= nil then
		terrain_height = HeightMap[position.x][position.z]
	end

	return terrain_height
end

function ExperimentalGetTerrainHeight( position )
	local position = Copy(position)
	position.x = (round((position.x) / 50) * 50)
	position.z = (round((position.z) / 50) * 50)

	local terrain_height = 200 -- default for 200, which is sea level


	local height_a = GetHeightAtPoint(position.x, position.z) -- center
	local height_b = GetHeightAtPoint(position.x-50, position.z) -- left
	local height_c = GetHeightAtPoint(position.x, position.z-50) -- up
	local height_d = GetHeightAtPoint(position.x, position.z+50) -- down
	local height_e = GetHeightAtPoint(position.x+50, position.z) -- right

	terrain_height = (height_a + height_b + height_c + height_d + height_e) / 5
	return terrain_height
end

function GetHeightAtPoint( x, z )
	if HeightMap[x] then
		return HeightMap[x][z] or 200
	end
	return 200
end

HeightMap = {}

air_vehicles = {}
heli_vehicles = {}
-- planes
air_vehicles[24] = true 
air_vehicles[30] = true
air_vehicles[34] = true
air_vehicles[39] = true
air_vehicles[51] = true
air_vehicles[59] = true
air_vehicles[81] = true
air_vehicles[85] = true
-- helicopters
air_vehicles[3] = true 
air_vehicles[14] = true
air_vehicles[37] = true
air_vehicles[57] = true
air_vehicles[62] = true
air_vehicles[64] = true
air_vehicles[65] = true
air_vehicles[67] = true

-- helicopters table
heli_vehicles[3] = true 
heli_vehicles[14] = true
heli_vehicles[37] = true
heli_vehicles[57] = true
heli_vehicles[62] = true
heli_vehicles[64] = true
heli_vehicles[65] = true
heli_vehicles[67] = true


function IsAirVehicle( id )
	return air_vehicles[id] or false
end

function IsHeli( id )
	return heli_vehicles[id] or false
end

function Vector3ToTable( vec )
    return {x = vec.x, y = vec.y, z = vec.z}
end

function TableToVector3( t )
    if type(t) == 'table' then
    	if t and t.x and t.y and t.z then
        	return Vector3( t.x, t.y, t.z )
        end
    end
    return nil
end

-- A* defines

PathPriority = {
	Low = 10,
	Medium = 30,
	High = 50
}

AiDrivingProfile = {
	Standard = {
		max_speed = 15,
		acceleration_rate = .25,
		brake_rate = .25,
		turn_rate = 90,
		turn_slow_rate = .1,
		max_corner_speed = 10
	},
	Panic = {
		max_speed = 35,
		acceleration_rate = .5,
		brake_rate = 1,
		turn_rate = 50,
		turn_slow_rate = .1,
		max_corner_speed = 30
	},
	Racer = {
		max_speed = 41.6,
		acceleration_rate = .5,
		brake_rate = 1,
		turn_rate = 45,
		turn_slow_rate = .3,
		max_corner_speed = 35
	},
	Combat = {
		max_speed = 30,
		acceleration_rate = .5,
		brake_rate = 1,
		turn_rate = 30,
		turn_slow_rate = .1,
		max_corner_speed = 25
	}
}

-- roads start

RoadSize = { -- size
	PATROL_PATH=0,
	DIRT_ROAD=1,
	ASPHALT_SMALL=2,
	ASPHALT_MEDIUM=3,
	HIGHWAY=4,
	SINGLE_LANE=5
}

RoadWidth = {}
RoadWidth[RoadSize.PATROL_PATH] = 6
RoadWidth[RoadSize.DIRT_ROAD] = 6
RoadWidth[RoadSize.ASPHALT_SMALL] = 12
RoadWidth[RoadSize.ASPHALT_MEDIUM] = 24
RoadWidth[RoadSize.HIGHWAY] = 48
RoadWidth[RoadSize.SINGLE_LANE] = 6

RoadLanes = {}
RoadLanes[RoadSize.PATROL_PATH] = 1
RoadLanes[RoadSize.DIRT_ROAD] = 1
RoadLanes[RoadSize.ASPHALT_SMALL] = 2
RoadLanes[RoadSize.ASPHALT_MEDIUM] = 2 -- could be wrong
RoadLanes[RoadSize.HIGHWAY] = 4
RoadLanes[RoadSize.SINGLE_LANE] = 1

RoadType = { -- road_type
	ROADTYPE_NORMAL=0,
	WATER_PATROL=1,
	GROUND_ROAM=2,
	GROUND_PATROL=3,
	AIR_PATROL=4,
	AIR_TAXI=7,
	WATER_ROAM=5,
	RAILWAY=6,
	SPLINE=8
}

TraverseType = { -- traverse_type
	BIDIRECTIONAL=0,
	ONEWAY_FORWARD=1,
	ONEWAY_REVERSE=2
}

RoadSpeedLimit = { -- speed_limit
	SPEED_DEFAULT=0,
	SPEED_CITY=1, 
	SPEED_RURAL_SLOW=2, 
	SPEED_RURAL_FAST=3, 
	SPEED_HIGHWAY=4
}

RoadSpeedByType = {}
RoadSpeedByType[RoadSpeedLimit.SPEED_DEFAULT] = 15
RoadSpeedByType[RoadSpeedLimit.SPEED_CITY] = 15
RoadSpeedByType[RoadSpeedLimit.SPEED_RURAL_SLOW] = 10
RoadSpeedByType[RoadSpeedLimit.SPEED_RURAL_FAST] = 25
RoadSpeedByType[RoadSpeedLimit.SPEED_HIGHWAY] = 30

-- roads end

boxes = {
	[1] = {Vector3(-1.229248, 0.105957, -1.633301), Vector3(1.229248, 2.290527, 2.082520)},
	[2] = {Vector3(-1.100037, 0.064087, -2.853516), Vector3(1.100525, 1.506714, 2.509277)},
	[3] = {Vector3(-1.144775, -0.122559, -1.969727), Vector3(1.130737, 3.185547, 5.937500)},
	[4] = {Vector3(-1.691223, 0.518066, -5.493652), Vector3(1.691223, 4.149902, 5.409180)},
	[5] = {Vector3(-2.171143, -1.346802, -6.682617), Vector3(2.164368, 2.692749, 5.537598)},
	[6] = {Vector3(-1.716003, -2.070923, -7.359375), Vector3(2.765991, 14.223267, 5.828125)},
	[7] = {Vector3(-1.174194, 0.102051, -2.430176), Vector3(1.174927, 1.858398, 3.125488)},
	[8] = {Vector3(-0.972290, 0.182739, -3.276855), Vector3(0.972473, 1.545532, 4.658203)},
	[9] = {Vector3(-0.849915, 0.184448, -1.688965), Vector3(0.849915, 2.199341, 2.069824)},
	[10] = {Vector3(-1.269165, 0.395996, -2.691406), Vector3(1.269165, 2.258057, 2.938477)},
	[11] = {Vector3(-0.696594, 0.288086, -1.043457), Vector3(0.696594, 1.089600, 1.111816)},
	[12] = {Vector3(-1.591431, -0.080078, -5.843750), Vector3(1.559021, 4.089111, 7.888672)},
	[13] = {Vector3(-0.994507, 0.121338, -1.411621), Vector3(0.993530, 1.384521, 2.067383)},
	[14] = {Vector3(-3.880066, 0.002563, -2.710938), Vector3(3.880066, 3.563599, 9.809082)},
	[15] = {Vector3(-1.027283, 0.166748, -1.988770), Vector3(1.026794, 1.562988, 2.557617)},
	[16] = {Vector3(-1.494873, -0.601318, -5.237793), Vector3(1.494873, 4.377930, 4.203125)},
	[17] = {Vector3.Zero, Vector3.Zero},
	[18] = {Vector3(-1.964111, 0.322388, -3.943848), Vector3(1.964111, 2.737915, 3.899902)},
	[19] = {Vector3(-1.715759, -0.665283, -7.004883), Vector3(1.715759, 2.942871, 5.480469)},
	[20] = {Vector3(-2.282410, -0.046997, -3.071289), Vector3(2.282471, 2.664673, 2.841309)},
	[21] = {Vector3(-0.261353, 0.161133, -0.859863), Vector3(0.261902, 1.329834, 1.182129)},
	[22] = {Vector3(-0.796570, 0.184570, -1.401367), Vector3(0.812378, 2.084961, 2.137695)},
	[23] = {Vector3(-1.127014, 0.237305, -2.642578), Vector3(1.127014, 2.201416, 2.642578)},
	[24] = {Vector3(-6.121704, 0.555542, -7.333496), Vector3(6.129639, 3.976440, 6.433594)},
	[25] = {Vector3(-2.912170, -0.949097, -8.632813), Vector3(2.912170, 7.913452, 9.949707)},
	[26] = {Vector3(-1.127014, 0.237305, -2.651367), Vector3(1.127014, 1.728760, 2.674805)},
	[27] = {Vector3(-2.199158, -0.597534, -9.729492), Vector3(2.049316, 1.377563, 3.750977)},
	[28] = {Vector3(-1.932556, -0.665161, -6.682617), Vector3(1.932556, 2.232056, 6.749512)},
	[29] = {Vector3(-1.031860, 0.143433, -1.980469), Vector3(1.022217, 1.566528, 2.565430)},
	[30] = {Vector3(-6.524963, 0.284485, -6.846680), Vector3(6.524963, 4.794128, 8.953613)},
	[31] = {Vector3(-2.028748, 0.597961, -4.509766), Vector3(1.998535, 3.973938, 5.411621)},
	[32] = {Vector3(-0.291138, 0.120911, -0.774414), Vector3(0.293701, 1.598450, 1.076172)},
	[33] = {Vector3(-1.127014, 0.237244, -2.642578), Vector3(1.127014, 2.421204, 2.642578)},
	[34] = {Vector3(-11.960327, 1.249817, -9.547852), Vector3(11.960327, 6.186951, 20.280273)},
	[35] = {Vector3(-1.180786, 0.033264, -2.555176), Vector3(1.180847, 1.473206, 2.287598)},
	[36] = {Vector3(-0.696594, 0.288025, -1.043457), Vector3(0.696594, 1.089661, 1.111816)},
	[37] = {Vector3(-2.303833, -0.037720, -5.486816), Vector3(2.309998, 3.889648, 10.286133)},
	[38] = {Vector3(-2.485596, -1.158875, -9.625977), Vector3(2.619080, 12.553162, 7.466309)},
	[39] = {Vector3(-18.646973, 0.575989, -13.242676), Vector3(18.646973, 13.015442, 26.523926)},
	[40] = {Vector3(-1.907471, -0.048340, -4.207031), Vector3(1.910156, 3.388916, 5.106934)},
	[41] = {Vector3(-1.236755, 0.394409, -2.860352), Vector3(1.236755, 3.701050, 4.153320)},
	[42] = {Vector3(-1.324890, 0.394409, -2.835449), Vector3(1.330017, 2.670410, 4.151855)},
	[43] = {Vector3(-0.385864, 0.093933, -0.942871), Vector3(0.385864, 1.194641, 1.242188)},
	[44] = {Vector3(-0.904175, 0.094849, -1.889648), Vector3(0.904175, 1.484985, 2.121094)},
	[45] = {Vector3(-1.715820, -0.646118, -7.812012), Vector3(1.715820, 3.251587, 5.479004)},
	[46] = {Vector3(-1.291199, 0.258667, -2.668457), Vector3(1.291199, 2.245850, 2.698242)},
	[47] = {Vector3(-0.199341, 0.133423, -0.917480), Vector3(0.251099, 1.584961, 1.051270)},
	[48] = {Vector3(-1.066284, 0.191223, -1.494141), Vector3(1.068726, 2.003967, 2.595215)},
	[49] = {Vector3(-1.192993, 0.394409, -2.860352), Vector3(1.192993, 2.853638, 4.061035)},
	[50] = {Vector3(-4.861450, -1.071777, -11.787109), Vector3(4.877319, 6.515625, 15.120605)},
	[51] = {Vector3(-7.942200, 0.161987, -4.192383), Vector3(7.942200, 4.049316, 9.117676)},
	[52] = {Vector3(-1.290955, 0.395996, -2.661621), Vector3(1.290955, 2.243530, 2.947754)},
	[53] = {Vector3(-3.023743, -0.049988, -5.295898), Vector3(3.023743, 5.035461, 5.146484)},
	[54] = {Vector3(-1.179932, 0.027954, -2.360840), Vector3(1.179932, 1.416138, 3.268555)},
	[55] = {Vector3(-1.027283, 0.197510, -2.029785), Vector3(1.026794, 1.548950, 2.541504)},
	[56] = {Vector3(-2.256531, 0.559265, -3.457520), Vector3(2.245850, 3.589783, 3.786133)},
	[57] = {Vector3(-2.303833, -0.037720, -5.486816), Vector3(2.309998, 3.889648, 10.286133)},
	[58] = {Vector3(-1.191040, 0.102173, -2.584961), Vector3(1.191040, 1.494873, 3.022949)},
	[59] = {Vector3(-5.383240, -0.024109, -3.453125), Vector3(5.394043, 4.060486, 6.333008)},
	[60] = {Vector3(-1.027283, 0.187378, -1.988770), Vector3(1.027283, 1.820190, 2.571777)},
	[61] = {Vector3(-0.256287, 0.269348, -0.931641), Vector3(0.257568, 1.252991, 1.257324)},
	[62] = {Vector3(-2.889648, 0.002502, -2.713867), Vector3(2.917603, 4.031555, 10.408203)},
	[63] = {Vector3(-1.127014, 0.237305, -2.662598), Vector3(1.127014, 1.976929, 2.849121)},
	[64] = {Vector3(-2.901245, -0.051270, -5.924316), Vector3(2.905334, 5.572021, 9.335449)},
	[65] = {Vector3(-2.644897, -1.700500, -5.207520), Vector3(2.644897, 1.530212, 9.366699)},
	[66] = {Vector3(-1.418457, 0.523926, -3.575684), Vector3(1.441467, 3.403076, 5.525391)},
	[67] = {Vector3(-1.506714, -0.056030, -2.710938), Vector3(1.520447, 3.563599, 9.809082)},
	[68] = {Vector3(-1.127014, 0.237305, -2.642578), Vector3(1.127014, 2.253418, 2.557129)},
	[69] = {Vector3(-2.389771, -0.964478, -9.761719), Vector3(2.442200, 5.462646, 8.518066)},
	[70] = {Vector3(-1.031860, 0.174927, -1.980469), Vector3(1.022217, 1.601929, 2.565430)},
	[71] = {Vector3(-1.431335, 0.421631, -2.851563), Vector3(1.440857, 3.428223, 4.549805)},
	[72] = {Vector3(-1.308105, 0.229980, -2.879883), Vector3(1.308105, 2.205566, 2.778809)},
	[73] = {Vector3(-1.127014, 0.237305, -2.695313), Vector3(1.127014, 1.740723, 2.684082)},
	[74] = {Vector3(-0.425903, 0.114990, -0.867676), Vector3(0.425903, 1.410278, 1.231445)},
	[75] = {Vector3(-0.849915, 0.184509, -1.688965), Vector3(0.849915, 2.464294, 1.894531)},
	[76] = {Vector3(-1.675781, 0.375183, -3.333984), Vector3(1.675781, 3.094543, 3.851563)},
	[77] = {Vector3(-1.268372, 0.352905, -2.632813), Vector3(1.268188, 2.267822, 2.452148)},
	[78] = {Vector3(-1.120361, 0.080017, -2.556152), Vector3(1.129395, 1.477966, 2.282227)},
	[79] = {Vector3(-1.606689, 0.373047, -4.104980), Vector3(1.424377, 4.057373, 6.524902)},
	[80] = {Vector3(-1.379944, -0.500000, -6.015137), Vector3(1.379944, 1.235229, 3.098633)},
	[81] = {Vector3(-4.135498, 0.101318, -4.526855), Vector3(4.135498, 2.355713, 2.527832)},
	[82] = {Vector3(-1.127014, 0.077698, -2.959961), Vector3(1.127014, 2.421204, 2.642578)},
	[83] = {Vector3(-0.390259, 0.199707, -0.913574), Vector3(0.390259, 1.396118, 1.137695)},
	[84] = {Vector3(-1.376282, 0.225525, -2.725098), Vector3(1.376282, 2.008484, 2.947754)},
	[85] = {Vector3(-31.769287, 0.537903, -14.602539), Vector3(31.769226, 13.711487, 33.133301)},
	[86] = {Vector3(-1.273010, 0.229980, -2.628906), Vector3(1.273010, 1.937134, 2.804688)},
	[87] = {Vector3(-1.194336, -0.081543, -2.153320), Vector3(1.194275, 2.299805, 2.020508)},
	[88] = {Vector3(-2.476318, -0.525574, -4.327148), Vector3(2.476318, 1.833191, 3.799316)},
	[89] = {Vector3(-0.208313, 0.161011, -0.981934), Vector3(0.286865, 1.171265, 1.147949)},
	[90] = {Vector3(-0.247864, 0.261902, -0.939941), Vector3(0.247864, 1.232117, 1.311523)},
	[91] = {Vector3(-1.170288, 0.111206, -2.566406), Vector3(1.170288, 1.458618, 2.611328)}
}

for id,box in ipairs(boxes) do -- Extends bounding boxes to the base of the vehicle

	-- box[1].y = math.min(box[1].y, 0)
	box[1].y = min(box[1].y, 0)
	
end

ellipsoids = {}

for id,box in ipairs(boxes) do -- Initialized ellipsoid parameters based on bounding boxes

	-- local a = (box[2].x - box[1].x) / math.sqrt(2)
	-- local b = (box[2].y - box[1].y) / math.sqrt(2)
	-- local c = (box[2].z - box[1].z) / math.sqrt(2)
	local a = (box[2].x - box[1].x) / 1.41421356237 -- sqrt(2)
	local b = (box[2].y - box[1].y) / 1.41421356237 -- sqrt(2)
	local c = (box[2].z - box[1].z) / 1.41421356237 -- sqrt(2)
	
	ellipsoids[id] = {a, b, c}

end

function Vector3:IsObscuredByVehicle(vehicle)

	local model = vehicle:GetModelId()
	local position = vehicle:GetPosition()
	local angle = vehicle:GetAngle()
		
	local point1 = position + angle * boxes[model][1]
	local point2 = position + angle * boxes[model][2]
	local origin = math.lerp(point1, point2, 0.5)
	
	local a = ellipsoids[model][1]
	local b = ellipsoids[model][2]
	local c = ellipsoids[model][3]
	
	local coord = -angle * (self - origin)
	
	local x_term = (coord.x / a)^2
	local y_term = (coord.y / b)^2
	local z_term = (coord.z / c)^2
	
	if x_term + y_term + z_term > 1 then
		return false
	else
		return true
	end
end

function Vector3:IsObscuredByVehicleEfficient(model, position, angle)
		
	local point1 = position + angle * boxes[model][1]
	local point2 = position + angle * boxes[model][2]
	local origin = math.lerp(point1, point2, 0.5)
	
	local a = ellipsoids[model][1]
	local b = ellipsoids[model][2]
	local c = ellipsoids[model][3]
	
	local coord = -angle * (self - origin)
	
	local x_term = (coord.x / a)^2
	local y_term = (coord.y / b)^2
	local z_term = (coord.z / c)^2
	
	if x_term + y_term + z_term > 1 then
		return false
	else
		return true
	end
end

function Vector3:IsObscuredByVehicleAtPosition( vehicle, position )

	local model = vehicle:GetModelId()
	local angle = vehicle:GetAngle()
		
	local point1 = position + angle * boxes[model][1]
	local point2 = position + angle * boxes[model][2]
	local origin = math.lerp(point1, point2, 0.5)
	
	local a = ellipsoids[model][1]
	local b = ellipsoids[model][2]
	local c = ellipsoids[model][3]
	
	local coord = -angle * (self - origin)
	
	local x_term = (coord.x / a)^2
	local y_term = (coord.y / b)^2
	local z_term = (coord.z / c)^2
	
	if x_term + y_term + z_term > 1 then
		return false
	else
		return true
	end

end

iterator = {}
iterator.count = function(it)
 local i = 0
 for v in it do
  i = i + 1
 end

 return i
end