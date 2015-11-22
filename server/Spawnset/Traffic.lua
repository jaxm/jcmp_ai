class 'Traffic'

function Traffic:__init( position, angle, faction, lane, cell )
	self.position = position
	self.angle = angle
	self.faction = faction
	self.lane = lane
	self.cell = { x = cell.x, y = cell.y }
	self.created = false
	self.removed = false

	-- before creating traffic, request a path for it to follow
	-- so that you don't have vehicles spawning in streets waiting
	-- for a path before they start moving. this also allows us to
	-- spawn traffic on highways / fast moving situations with 
	-- its speed set to the road type and have it spawn moving at
	-- the correct speed.

	local current_cell = GetCellFromPosition( position )
	local connected_cells = GetNearbyCells( current_cell.x, current_cell.y )

	local random_node = nil
	while random_node == nil do
		for i=1,#connected_cells do
			local cell = connected_cells[i]
			if cell ~= current_cell then
				local cell_nodes = cell.nodes[1]
				if cell_nodes then
					local node_count = #cell_nodes
					if node_count > 1 then
						local num = random( 1, node_count )
						random_node = cell_nodes[num]

						local dist = position:Distance( random_node.position )
						if dist < 50 then
							random_node = nil
						end
					end

					if random_node then
						Debug = true
						GeneratePath( position, random_node, self, 1, PathPriority.Low, math.deg( angle.yaw ) )
						Debug = false
						return
					end
				end
			end
		end
	end
end

function Traffic:PathSuccess( t )
	if not self.removed then
		local path = t.path
		local node = GetNodeById( path[#path].id, 1 )
		local speed_limit = node.info.speed_limit or 5

		local next_node = GetNodeById( path[(#path-1)].id, 1 )

		if next_node then
			local vec_dir = next_node.position - node.position
			vec_dir:Normalize()
			local angle = Angle.FromVectors( Vector3.Forward, vec_dir )
			self.angle = angle
		end


		local model_id = TrafficVehicleModels[math.random(1, #TrafficVehicleModels)]
		-- local model_id = 35
		self.vehicle = Vehicle.Create( {
			model_id = model_id,
			position = self.position,
			angle = self.angle or Angle(),
			invulnerable = true,
			enabled = true,
			template = 'Default',
			linear_velocity = (Vector3.Forward*speed_limit)
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
			position = self.position,
			goal = AiGoal.Traffic, 
			model_id = model, 
			faction = self.faction,
			vehicle = self.vehicle,
			speed = speed_limit
		} )
		self.driver.spawnset = self
		self.driver.in_vehicle = true

		table.insert( self.occupants, self.driver )

		local traffic_lc = self.driver.logic_controller[2]
		if traffic_lc then
			traffic_lc:PathSuccess( t )
		end

		-- initialize speed
		if speed_limit then
			local movement_lc = self.driver.logic_controller[1]
			movement_lc.movement.max_speed = RoadSpeedByType[speed_limit]
			movement_lc.movement.speed = RoadSpeedByType[speed_limit]*.9
		end

		self.created = true
	end
end

function Traffic:PathFailed( reason )
	self:Remove()
end

function Traffic:GetPosition()
	-- NPC is likely to have the most up to date position
	local driver = self.driver
	if driver and IsValid(driver) then
		return driver:GetPosition()
	end

	-- vehicle position is updated less frequently on the server in most cases

	local vehicle = self.vehicle
	if vehicle and IsValid( vehicle ) then
		return vehicle:GetPosition()
	end
	return self.position
end

function Traffic:UpdateOccupantPosition( position )
	for _,occupant in pairs(self.occupants) do
		if occupant and IsValid(occupant) then
			if occupant.network_object and IsValid(occupant.network_object) then
				occupant.position = position
				occupant.network_object:SetPosition( position )
			end
		end
	end
end

function Traffic:GetDriver()
	return self.driver
end

function Traffic:RemoveOccupant( npc )
	local i = 1
	while i <= #self.occupants do
		local occupant = self.occupants[i]
		if occupant and IsValid(occupant) then
			if occupant == npc then
				local cell = npc.cell
				npc:Remove()
				table.remove( self.occupants, i )
				if #self.occupants == 0 then
					RemoveTrafficFromCell( self, cell.x, cell.y )
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

function Traffic:Remove()
	if self.driver then
		self.driver.vehicle = nil
	end
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

	RemoveVehicleTrafficFromCell( self, self.cell.x, self.cell.y )

	self = nil
end

function Traffic:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	end
end

TrafficVehicleModels = {
	7, 22, 23, 26, 29, 32, 33, 40, 41, 42, 44, 49, 52, 54, 55, 63, 68, 71, 73, 74, 76, 77, 78, 79, 84, 86, 87, 89, 90, 91
}