class 'MilitaryAPC_Cannon'

function MilitaryAPC_Cannon:__init( args )
	local position = args.position
	local angle = args.angle
	local faction = args.faction

	local vehicle_table = {
		model_id = 18,
		position = position,
		angle = Angle(),
		invulnerable = true,
		enabled = true,
		template = 'Cannon'
	}

	local faction_info = GetFactionInfo( faction )
	local colour = faction_info.vehicleColours
	colour = colour[1]

	if colour.col1 and colour.col2 then
		vehicle_table.tone1 = colour.col1
		vehicle_table.tone2 = colour.col2
	end

	local decal = faction_info.decal

	if decal then
		vehicle_table.decal = decal
	end

	self.vehicle = Vehicle.Create( vehicle_table )

	self.vehicle:SetValue( 'DriverAimAngle', Angle() )
	local streamDistance = self.vehicle:GetStreamDistance()

	-- register to vehicle manager
	VOM.vehicles[self.vehicle:GetId()] = self.vehicle

	local actorModels = faction_info.actorModels
	local model = actorModels[random( 1, #actorModels )]
	self.occupants = {}

	-- occupants
	self.driver = AM:CreateNPC( {
			position = position,
			goal = AiGoal.Guard, 
			model_id = model, 
			faction = faction,
			vehicle = self.vehicle,
			speed = speed_limit
		} )
	self.driver.spawnset = self
	self.driver.in_vehicle = true
	table.insert( self.occupants, self.driver )

end

function MilitaryAPC_Cannon:GetPosition( ... )
	if self.vehicle and IsValid(self.vehicle) then
		return self.vehicle:GetPosition()
	else
		return Vector3()
	end
end

function MilitaryAPC_Cannon:UpdateOccupantPosition( position )
	for _,occupant in pairs(self.occupants) do
		if occupant and IsValid(occupant) then
			if occupant.network_object and IsValid(occupant.network_object) then
				occupant.position = position
				occupant.network_object:SetPosition( position )
			end
		end
	end
end

function MilitaryAPC_Cannon:GetDriver( ... )
	return self.driver
end

function MilitaryAPC_Cannon:Remove( ... )
	self.driver:Remove()
	local vehicle = self.vehicle
	if vehicle and IsValid( vehicle ) then
		VOM.vehicles[vehicle:GetId()] = nil
		if not vehicle:GetDriver() then
			vehicle:Remove()
		else
			-- vehicle has player driver
			vehicle:SetDeathRemove( true )
			vehicle:SetUnoccupiedRespawnTime( 25 )
			vehicle:SetUnoccupiedRemove( true )
		end
	end
	self = nil
end