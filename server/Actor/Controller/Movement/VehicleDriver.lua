class 'AgentVehicleDriver'

function AgentVehicleDriver:__init( core, args )
	-- initialize
	self.core = core
	self.position = core.position
	self.angle = core.angle
	self.vehicle = args.vehicle

	-- pathfinding
	self.path = {}
	self.path_destination = nil
	self.requested_destination = nil
	self.has_requested_path = false
	self.current_node = nil

	-- movement
	self.movement = {
		speed = args.speed or 0,
		max_speed = 50,
		max_vehicle_speed = 50,
		turn_rate = 0,
		max_turn_rate = 2
	}

	-- init driving profile settings
	self:SetDrivingProfile( AiDrivingProfile.Standard )
end

function AgentVehicleDriver:Tick( core, frame_time )
	local position = self.position

	-- vehicle sanity

	local vehicle = self.vehicle

	if vehicle and IsValid(vehicle) then
		local health = vehicle:GetHealth()

		if health <= .25 then
			-- abandon vehicle
			self:ExitVehicle( AiGoal.Panic )
		end
	end

	-- request a path, calculate distance from destination etc
	self:PathLogic( position )
	local path_destination = self.path_destination

	local can_accelerate = true
	if not path_destination then
		-- no where to go, kill movement speed
		path_destination = self.position + (self.angle * (Vector3.Forward * 2))
		self:ApplyBraking( self.movement.brake_rate )
		can_accelerate = false
		-- return
	end

	-- we have a destination, move there!
	local move_dir = Angle.NormalisedDir( path_destination, position )
	local move_angle = Angle.FromVectors( Vector3.Forward, move_dir )
	-- no rolling about!
	move_angle.roll = 0

	local turnDiff = DegreesDifference( deg(move_angle.yaw), deg(self.angle.yaw))

	local speed = self.movement.speed
	local sync_handbrake = false
	if self.turn_ahead then
		if speed > self.movement.max_corner_speed or speed > self.movement.max_vehicle_corner_speed then
			self:ApplyBraking( self.movement.brake_rate )
			can_accelerate = false
			speed = self.movement.speed
		end
	end

	if turnDiff > 5 then
		local turn_speed = self.movement.max_turn_rate - self.movement.speed
		move_angle = Angle.RotateToward( self.angle, move_angle, rad(turn_speed*frame_time))
	end

	-- obstruction
	local closest_entity = self.core.closest_entity
	if closest_entity and IsValid( closest_entity ) then
		-- we have a valid closest entity
		if closest_entity.__type ~= 'Player' then
			-- the entity is another NPC
			if closest_entity.network_object and IsValid(closest_entity.network_object) then
				-- the entity is valid
				local distance = self.core.closest_entity_distance
				self.core.debug.closest_entity_distance = distance
				self.core.debug.closest_entity = closest_entity.network_object:GetId()
				if distance < 25 then
					-- the distance between this NPC and closest entity is under 25m
					local entity_movement_lc = closest_entity.logic_controller[1]
					if closest_entity.network_object:GetValue('in_vehicle') then
						-- the closest entity is driving a vehicle
						if self.movement.max_vehicle_speed <= entity_movement_lc.movement.max_vehicle_speed then
							-- this NPC is driving a vehicle that is slower or equal in speed to closest entities vehicle
							if self.movement.speed >= entity_movement_lc.movement.speed then
								-- brake to match speed
								self:ApplyBraking( self.movement.brake_rate )
								-- stop this NPC from accelerating this frame
								can_accelerate = false
							end
							-- if distance < 4 then
							-- 	-- push
							-- 	this code allows vehicles to move each other around on the server, and it sucks
							-- 	local impulse = 1.25
							-- 	local current_velocity = entity_movement_lc.velocity or Vector3()
							-- 	local vec_dir = Angle.NormalisedDir( entity_movement_lc.position, self.position )
							-- 	local hit_angle = Angle.FromVectors( Vector3.Forward, vec_dir )
							-- 	local new_velocity = current_velocity + ( hit_angle * ( Vector3.Forward * impulse ) )
							-- 	entity_movement_lc.collisionVelocity = new_velocity
							-- 	entity_movement_lc.movement.speed = entity_movement_lc.movement.speed*.5
							if distance < 15 then
								-- under 15m to closest entity
								-- are we traveling the same direction
								local heading_diff = DegreesDifference( deg(self.angle.yaw), deg(entity_movement_lc.angle.yaw) )
								local abs_heading_diff = abs(heading_diff)
								if abs_heading_diff < 45 then
									-- we're heading in the same direction, which means we're tailgating!
									-- brake to increase distance to closest entity
									self:ApplyBraking( self.movement.brake_rate )
									-- stop this NPC from accelerating this frame
									can_accelerate = false
								else
									-- other heading, either T or oncoming
									-- try and drive around
									local entity_movement_lc = closest_entity.logic_controller[1]
									local entity_position = entity_movement_lc.position
									-- local entity_angle = entity_movement_lc.angle
									local angle = self.angle
									local avoid_position = entity_position + (angle * (Vector3.Right*3))

									-- adjust our turning angle to try and avoid the closest entity
									local target_angle = Angle.FromVectors(Vector3.Forward, (avoid_position - self.position):Normalized() )
									move_angle = Angle.RotateToward( move_angle, target_angle, rad((self.movement.max_turn_rate*2)*frame_time))
								end
							end
						else
							-- our vehicle's top speed is higher than that of the closest entities
							-- tell our pathing logic controller we want to overtake by switching lane if possible
							-- ( this code isn't working right now )
							-- local entity_logic_lc = closest_entity.logic_controller[2]
							-- if entity_logic_lc then
							-- 	local logic_lc = self.core.logic_controller[2]

							-- 	if logic_lc.lane == entity_logic_lc.lane then
							-- 		logic_lc.lane = logic_lc.lane + 1
							-- 	end
							-- end
							if can_accelerate then
								local entity_movement_lc = closest_entity.logic_controller[1]
								local entity_position = entity_movement_lc.position
								local angle = self.angle
								local avoid_position = entity_position + (angle * (Vector3.Right*6))
								local target_angle = Angle.FromVectors(Vector3.Forward, (avoid_position - self.position):Normalized() )
								move_angle = Angle.RotateToward( move_angle, target_angle, rad((self.movement.max_turn_rate*2)*frame_time))
							end
						end
					else
						-- closest entity is a pedestrian
						if self.movement.speed > 5 then
							if distance < 3 and entity_movement_lc then
								-- hit pedestrian
								self:ApplyBraking( self.movement.brake_rate )
								-- send pedestrian flying
								local entity_position = entity_movement_lc.position
								local target_angle = Angle.FromVectors(Vector3.Forward, (entity_position - self.position):Normalized() )
								closest_entity:HitByVehicle( {
										impulse = 5,
										angle = target_angle
									} )
								-- deal damage
								closest_entity:Hurt( self, ceil(self.movement.speed*2) )

							elseif distance < 6 then
								if closest_entity.goal == AiGoal.Wander then
									closest_entity:ConfigureNPC( { goal = AiGoal.Panic } )
									local lc = closest_entity.logic_controller[2]
									if lc then
										table.insert( lc.avoid, self.core )
									end
								end
							elseif distance < 20 then
								self:ApplyBraking( self.movement.brake_rate )
							end
							-- stop this NPC from accelerating this frame
							can_accelerate = false
						end

						-- pedestrian avoidance code

						local entity_movement_lc = closest_entity.logic_controller[1]
						if entity_movement_lc then
							local entity_position = entity_movement_lc.position
							-- local entity_angle = entity_movement_lc.angle
							local angle = self.angle

							local current_trajectory = self.position + (angle * (Vector3.Forward*distance))

							-- try to work out which direction we want to turn based on which direction is least
							-- likely to hit the pedestrian, this logic might be flawed.... but it works.. most of the time.

							local avoid_position_behind = entity_position + (angle * (Vector3.Left*3))
							local avoid_position_infront = entity_position + (angle * (Vector3.Right*3))

							local behind_dist = current_trajectory:Distance( avoid_position_behind )
							local infront_dist = current_trajectory:Distance( avoid_position_infront )
							local avoid_position = current_trajectory
							-- select avoid position / direction
							if behind_dist < infront_dist then
								avoid_position = avoid_position_behind
							else
								avoid_position = avoid_position_infront
							end

							-- adjust our turning angle to try and avoid the pedestrian
							local target_angle = Angle.FromVectors(Vector3.Forward, (avoid_position - self.position):Normalized() )
							move_angle = Angle.RotateToward( move_angle, target_angle, rad((self.movement.max_turn_rate*2)*frame_time))
						end
					end
				end
			end
		else
			-- player
			local distance = self.core.closest_entity_distance
			if distance < 30 then

				-- player avoidance code ( same as pedestrian avoidance code above )
				local entity_position = closest_entity:GetPosition()
				local angle = self.angle

				local current_trajectory = self.position + (angle * (Vector3.Forward*distance))
				local avoid_distance =  3
				if closest_entity:GetVehicle() then
					avoid_distance = 6
				end
				local avoid_position_behind = entity_position + (angle * (Vector3.Left*avoid_distance))
				local avoid_position_infront = entity_position + (angle * (Vector3.Right*avoid_distance))

				local behind_dist = current_trajectory:Distance( avoid_position_behind )
				local infront_dist = current_trajectory:Distance( avoid_position_infront )
				local avoid_position = current_trajectory
				if behind_dist < infront_dist then
					avoid_position = avoid_position_behind
				else
					avoid_position = avoid_position_infront
				end

				-- a little extra turn factor, because no one likes being run over by AI...
				-- the closer the AI is to the player, the sharper it will turn

				local turn_factor = 2
				if distance < 10 then
					turn_factor = 6
					self:ApplyBraking( self.movement.brake_rate )
					sync_handbrake = true
					can_accelerate = false
				elseif distance < 20 then
					turn_factor = 4
				end

				local target_angle = Angle.FromVectors(Vector3.Forward, (avoid_position - self.position):Normalized() )
				move_angle = Angle.RotateToward( move_angle, target_angle, rad((self.movement.max_turn_rate*turn_factor)*frame_time))
			end
		end
	end

	local network_object = self.core.network_object

	if can_accelerate then
		local current_speed = self.movement.speed
		if current_speed < self.movement.max_speed and current_speed < self.movement.max_vehicle_speed then
			self:ApplyAcceleration( self.movement.acceleration_rate )
		end
	end

	-- sync speed
	-- speed is synced ahead of position calculation so the vehicle on the client can more readily react
	if network_object:GetValue( 'speed' ) ~= speed then
		network_object:SetNetworkValue( 'speed', speed )
	end

	self:MovementStep( position, move_angle, self.movement.speed, frame_time )
end

function AgentVehicleDriver:MovementStep( position, angle, speed, frame_time )
	-- governs movement through 3d space for our agent

	local angle_difference = deg(abs((self.angle * angle:Inverse()).yaw))
	local collisionVelocity = self.collisionVelocity
	local new_position = nil
	local velocity = nil

	if collisionVelocity and collisionVelocity:Length() > 0.1 then
		new_position = self.position + collisionVelocity
		self.collisionVelocity = collisionVelocity * .75
		self.movement.speed = 1
		if not self.collisionMode then
			self.core.network_object:SetNetworkValue( 'collisionMode', true )
			self.collisionMode = true
		end

		if (new_position.y - position.y) > 1 then -- self.path_destination.y
			new_position.y = new_position.y - 1--( 9.8 * self.frame_time )
		end

		-- force network updates for colliding vehicles
		self.core.net_tick = self.core.sync_tick
	else
		if self.collisionMode then
			self.collisionMode = false
			self.core.network_object:SetNetworkValue( 'collisionMode', false )
			self.collisionVelocity = nil
		end

		speed = self.movement.speed

		-- build server movement
		velocity = angle * ( Vector3.Forward * (speed*frame_time) )
		self.velocity = velocity
		new_position = position + velocity

		if not new_position then return end
		if not IsValid(new_position) then return end

		-- build predicted next frame position
		self.next_frame_position = new_position + velocity
	end

	if not new_position or IsNaN(new_position) then return end

	-- update stored position
	self.position = new_position

	if self.angle ~= angle then
		self.angle = angle
		self.core.angle = angle
	end

	-- is it a network tick?

	if self.core.net_tick == self.core.sync_tick then
		
		local network_object = self.core.network_object

		-- update travel position
		if velocity then
			network_object:SetNetworkValue( 'travelposition', new_position + ( velocity ) )
		end

		-- update vehicle velocity

		-- network_object:SetNetworkValue( 'velocity', angle * ( Vector3.Forward * speed ) )

		-- sync position
		if network_object:GetPosition() ~= new_position then
			network_object:SetPosition( new_position )
		end

		-- sync angle
		if network_object:GetValue( 'angle' ) ~= angle then
			network_object:SetNetworkValue( 'angle', angle )
		end

		-- update cell info, doesn't have to be done so often
		self.core:CalculateCell( new_position )
	end
	-- update vehicle position
	self.vehicle:SetStreamPosition( new_position )

	-- update core position
	self.core.position = new_position
end

function AgentVehicleDriver:ApplyAcceleration( n )
	local max_vehicle_speed = self.movement.max_vehicle_speed
	local current_speed = self.movement.speed
	if current_speed < self.movement.max_speed and current_speed < max_vehicle_speed then
		self.movement.speed = self.movement.speed + n
	end

	-- cap at max speed
	if self.movement.speed > max_vehicle_speed then
		self.movement.speed = max_vehicle_speed
	end

	-- adjust turning cirle

	-- local speed_ratio = self.movement.speed / max_speed
	-- self.movement.turn_rate = (1-speed_ratio)*self.movement.max_turn_rate
end

function AgentVehicleDriver:ApplyBraking( n )
	if self.movement.speed > 0 then
		self.movement.speed = self.movement.speed - n
	end

	-- limit to 0

	if self.movement.speed < 0 then
		self.movement.speed = 0
	end

	-- adjust turning cirle

	-- local speed_ratio = self.movement.speed / self.movement.max_speed
	-- self.movement.turn_rate = (1-speed_ratio)*self.movement.max_turn_rate
end


function AgentVehicleDriver:SetDrivingProfile( profile )
	self.movement.max_speed = profile.max_speed
	self.movement.max_vehicle_speed = profile.max_speed
	self.movement.acceleration_rate = profile.acceleration_rate
	self.movement.brake_rate = profile.brake_rate
	self.movement.max_turn_rate = profile.turn_rate
	self.movement.turn_rate = 0
	self.movement.turn_slow_rate = profile.turn_slow_rate
	self.movement.max_corner_speed = profile.max_corner_speed
	self.movement.max_vehicle_corner_speed = profile.max_corner_speed

	self:UpdateDrivingProfile()
end

function AgentVehicleDriver:UpdateDrivingProfile()
	local model_id = self.vehicle:GetModelId()

	local profile = AiDrivingVehicleModifier[model_id]
	if profile then
		self.movement.max_vehicle_speed = profile.max_speed
		self.movement.acceleration_rate = profile.acceleration_rate
		self.movement.brake_rate = profile.brake_rate
		self.movement.max_turn_rate = profile.turn_rate
		self.movement.turn_rate = 0
		self.movement.turn_slow_rate = profile.turn_slow_rate
		self.movement.max_vehicle_corner_speed = profile.max_corner_speed
	end
end

function AgentVehicleDriver:PathLogic( position )
	-- work out where we're going
	local path = self.path

	-- do we need to change where we're moving?
	if self.requested_destination then
		self:RequestPathToDestination( self.requested_destination )
		return
	end

	-- do we need to move?
	if not self.path_destination then
		-- get next path position
		if #path > 0 then
			self.path_destination = path[#path].position
		end
	end

	if self.path_destination then

		-- is our path blocked?
		if self.current_node then
			-- we have a node to check against
			if self.current_node.blocked then
				self.path = {}
				self.path_destination = nil
				self.current_node = nil
				return
			end
		end

		-- have we arrived at our destination?
		local distance = Distance2D( position, self.path_destination )

		local limit = (5+(self.movement.speed*.5))

		if distance <= limit then
			-- we've arrived!
			table.remove( self.path, #path )

			if #self.path > 0 then
				-- get next node along path
				-- check if next node is blocked
				local position = self.path[#self.path].position
				local x, y, cell = GetMeshCellFromPosition( position )
				if IsCellLoaded( x, y ) then
					local node = GetMeshNodeById( self.path[#self.path].id, cell )
					self.current_node = node
					if node and node.blocked then
						self.path = {}
						self.path_destination = nil
						return
					end
				end

				self.path_destination = position
			else

				self.path_destination = nil
			end
		end
	end
end

function AgentVehicleDriver:ExitVehicle( new_goal )
	local vehicle = self.vehicle
	if vehicle and IsValid( vehicle ) then
		vehicle:SetValue( 'NPCDriver', nil ) 

		local network_object = self.core.network_object

		network_object:SetNetworkValue( 'in_vehicle', nil )
		network_object:SetStreamDistance( 250 )

		self.core:ConfigureNPC( { goal = new_goal } )

	end
end

function AgentVehicleDriver:LogicPath( t )
	-- logic path override for special path instances
	-- ie: could be used to drive a vehicle down a specific path in a mission
	self.path = t.path
end

function AgentVehicleDriver:SetPathDestination( position )
	-- position goal, ignores navmesh
	self.path_destination = position
end

function AgentVehicleDriver:RequestPathToDestination( position )
	-- if we've already requested a path, wait for the pathfinder
	-- to return a successful path or a failed path notifier
	if not self.has_requested_path and position then
		self.has_requested_path = true
		-- send request to the pathfinder
		GeneratePath( self.position, position, self, 2, PathPriority.Low, nil, true )

		-- clear destination request
		self.requested_destination = nil
	end
end

function AgentVehicleDriver:PathSuccess( t )
	local network_object = self.core.network_object

	if network_object and IsValid( network_object ) then

		table.remove(t.path, #t.path )
		self.path = t.path
		self.core.network_object:SetNetworkValue( 'path', t.path )

		-- clear bool so new path can be requested
		self.has_requested_path = false
	end
end

function AgentVehicleDriver:PathFailed()
	-- pathfinder failed to find a suitable path
	-- clear bool so new path can be requested
	self.has_requested_path = false
end