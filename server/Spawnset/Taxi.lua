class 'Taxi'

function Taxi:__init( position, angle, faction, lane, cell )
	self.position = position
	self.angle = angle
	self.faction = faction
	self.lane = lane
	self.removed = false
	local destination = nil
	
	local node = GetClosestNode( position, 1 )
	position = node.position
	local speed_limit = node.info.speed_limit or 5

	local model_id = TaxiModels[math.random(1, #TaxiModels)]
	-- model override for vehicle profiler testing / creation
	-- local model_id = 22
	self.vehicle = Vehicle.Create( {
		model_id = model_id,
		position = position,
		angle = self.angle or Angle(),
		invulnerable = true,
		enabled = true,
		template = 'Default'
	} )

	local streamDistance = self.vehicle:GetStreamDistance()

	-- register to vehicle manager
	VOM.vehicles[self.vehicle:GetId()] = self.vehicle

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	local model = actorModels[random( 1, #actorModels )]
	self.occupants = {}

	-- occupants
	self.driver = AM:CreateNPC( {
		position = position,
		goal = AiGoal.TaxiDriver, 
		model_id = model, 
		faction = self.faction,
		vehicle = self.vehicle,
		speed = 0
	} )
	self.driver.spawnset = self
	self.driver.in_vehicle = true

	table.insert( self.occupants, self.driver )

	-- initialize speed
	if speed_limit then
		local movement_lc = self.driver.logic_controller[1]
		movement_lc.movement.max_speed = RoadSpeedByType[speed_limit]
	end
end

function Taxi:GetPosition( ... )
	if self.vehicle and IsValid( self.vehicle ) then
		return self.vehicle:GetPosition()
	end
	return self.position
end

function Taxi:UpdateOccupantPosition( position )
	for _,occupant in pairs(self.occupants) do
		if occupant and IsValid(occupant) then
			if occupant.network_object and IsValid(occupant.network_object) then
				occupant.position = position
				occupant.network_object:SetPosition( position )
			end
		end
	end
end

function Taxi:GetDriver( ... )
	return self.driver
end

function Taxi:RemoveOccupant( npc )
	local i = 1
	while i <= #self.occupants do
		local occupant = self.occupants[i]
		if occupant and IsValid(occupant) then
			if occupant == npc then
				local cell = npc.cell
				-- RemoveActorFromCell( npc, npc.cell.x, npc.cell.y )
				npc:Remove()
				table.remove( self.occupants, i )
				if #self.occupants == 0 then
					RemoveTaxiFromCell( self, cell.x, cell.y )
				end
			else
				i = i + 1
			end
		else
			-- invalid
			table.remove( self.occupants, i )
		end
	end

	if #self.occupants == 0 then
		-- vehicle cleanup
		if self.vehicle and IsValid(self.vehicle) then
			local occupants = self.vehicle:GetOccupants()
			if #occupants == 0 then
				-- no player currently in vehicle
				self.vehicle:Remove()
			end
		end
	end
end

function Taxi:Remove( ... )
	self:RemoveEntity( self.driver )
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

function Taxi:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	end
end

TaxiModels = {
	70 -- 9
}