class 'TaxiDriver'

function TaxiDriver:__init( core, args )
	self.core = core
	self.vehicle = args.vehicle
	self.spawn_position = self.core.position
	self.heading_to_goal = false
	self:EnterVehicle( self.vehicle )

	-- pathfinding
	self.path = {}
	self.has_requested_path = false
	self.path_failed_count = 0
	self.last_heading = 0
	self.lane = 0
end

function TaxiDriver:Tick( core, frame_time )

	-- do we have a fare?
	local vehicle = self.vehicle
	if not vehicle then return end

	local occupants = vehicle:GetOccupants()

	if #occupants == 0 then return end	

	-- get movement lc
	local movement_lc = core.logic_controller[1]

	if not movement_lc then return end

	-- currenty following a path?
	if movement_lc.path_destination or #movement_lc.path > 1 then return end

	local path = self.path

	if #path == 0 then
		if not self.has_requested_path then
			if #movement_lc.path == 1 then
				self:RequestNewPath( movement_lc.path[1].position )
			else
				self:RequestNewPath( movement_lc.position )
			end
		end
	else
		local node = GetNodeById( path[#path].id, 1 )
		local next_node = path[#path-1]
		if next_node then
			next_node = GetNodeById( path[#path-1].id, 1 )
		end

		-- apply road speed caps
		local speed_limit = node.info.speed_limit
		if speed_limit then
			movement_lc.movement.max_speed = RoadSpeedByType[speed_limit]
			movement_lc.movement.max_corner_speed = RoadSpeedByType[speed_limit]*.6
		end

		local sharp_turn = false
		if next_node and node then
			local vec_dir = next_node.position - node.position
			local angle = Angle.FromVectors( Vector3.Forward, vec_dir )

			local current_heading = deg(angle.yaw)

			local heading_diff = abs(DegreesDifference(current_heading, self.last_heading))
			if heading_diff > 80 then
				-- sharp turn
				sharp_turn = true
			end
			self.last_heading = current_heading
		end

		-- upcoming turn logic
		local upcoming_turn = false
		local diff = 0
		if next_node then
			local current_angle = movement_lc.angle
			local dir = Angle.NormalisedDir( next_node.position, node.position )
			local required_angle = Angle.FromVectors( Vector3.Forward, dir )
			local heading = YawToHeading( deg( current_angle.yaw ) )
			local required_heading = YawToHeading( deg( required_angle.yaw ) )
			diff = DegreesDifference( required_heading, heading )
			local absDiff = abs(diff)
			local movement = movement_lc.movement
			if absDiff > 30 then
				upcoming_turn = true
				movement_lc.turn_ahead = true	
			else
				-- no turn
				if not obstruction then
					if movement.speed < movement.max_speed then
						movement_lc.turn_ahead = false
					end
				end
			end
		end

		local lane = self.lane

		if upcoming_turn then
			if diff < 0 then
				lane = 4
			end
		end

		-- lane / road rules
		local position = nil
		if self.last_node then
			position = GetLanePosition( self.last_node, node, nil, lane )
		else
			if next_node then
				position = GetLanePosition( node, next_node, nil, lane )
			else
				position = GetLanePosition( nil, node, self.core.position, lane )
			end
		end

		if sharp_turn then
			if diff < 0 then
				-- right
				local c = nil
				if self.last_node then
					c = self.last_node.position
				else
					c = movement_lc.position
				end

				local a = node.position
				local b = next_node.position
				local center_point = ( a + b + c ) / 3
				local vec_dir = center_point - a
				local angle = Angle.FromVectors( Vector3.Forward, vec_dir )

				position = a + (angle * (Vector3.Forward * 10))
			else
				-- left
				position = math.lerp( node.position, next_node.position, .5 ) 
			end
		end

		self.last_node = node
		-- make path request
		if position and not IsNaN(position) then
			movement_lc:SetPathDestination( position )
			movement_lc.current_node = node
		end
		table.remove( self.path, #path )
	end
end

function TaxiDriver:RequestNewPath( start_position )
	self.has_requested_path = true
	local target_position = nil
	if not self.heading_to_goal then
		self.heading_to_goal = true
		local goal_position = Vector3( -6780.176270, 207.998779, -3619.083496 )
		target_position = goal_position
	else
		self.heading_to_goal = false
		target_position = self.spawn_position
	end

	local movement_lc = self.core.logic_controller[1]

	if movement_lc then
		GeneratePath( start_position, target_position, self, 1, PathPriority.High, math.deg( movement_lc.angle.yaw ) )
		return
	end
	self.has_requested_path = false
end

function TaxiDriver:PathSuccess( t )
	self.path = t.path
	self.has_requested_path = false
	local network_object = self.core.network_object
	if network_object and IsValid(network_object) then
		network_object:SetNetworkValue( 'path', t.path )
	end
end

function TaxiDriver:PathFailed()
	self.has_requested_path = false
end

function TaxiDriver:EnterVehicle( vehicle )
	local network_object = self.core.network_object
	vehicle:SetValue( 'NPCDriver', network_object:GetId() )
	network_object:SetNetworkValue( 'in_vehicle', vehicle:GetId() )
	network_object:SetStreamDistance( vehicle:GetStreamDistance() )

	local movement_lc = self.core.logic_controller[1]

	if not movement_lc then return end
	movement_lc.position = vehicle:GetPosition()
	movement_lc.angle = vehicle:GetAngle()
end