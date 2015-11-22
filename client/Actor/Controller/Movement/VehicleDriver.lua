class 'AgentVehicleDriver'

function AgentVehicleDriver:__init( core )
	self.core = core
	self.core.in_vehicle = true
	self.delayed_enter = false
	self.vehicle_velocity = Vector3()
	self.vc_timer = Timer() -- velocity correction
	self.lerp_timer = Timer()
	self.lerp_time = 500
	self.last_position = self.core.position
	self.last_applied_velocity = 0
	-- attempt to enter the vehicle
	local vehicle_id = core.network_object:GetValue( 'in_vehicle' )
	if vehicle_id then
		self:EnterVehicle( vehicle_id )
	end
end

function AgentVehicleDriver:Update( e )
	local key = e.key
	local value = e.value
	if key == 'in_vehicle' then
		if value then
			local actor = self.core.actor
			if actor and IsValid(actor) then
				if not actor:GetVehicle() then
					self:EnterVehicle( value )
				end
			end
		else
			-- exit vehicle
			local vehicle = self.core.vehicle
			if vehicle and IsValid(vehicle) then
				-- clear npc driver on vehicle
				vehicle:SetValue( 'NPCDriver', nil )
				local actor = self.core.actor
				if actor and IsValid(actor) then
					actor:ExitVehicle()
				end
			end
			self.core.in_vehicle = nil
			self.core.vehicle = nil
		end
	elseif key == 'collisionMode' then
		self.collisionMode = value
	elseif key == 'braking' then
		self.brake_timer = Timer()
	elseif key == 'travelposition' then
		local lt = self.lerp_timer
		self.lerp_time = lt:GetMilliseconds() -- + 50
		lt:Restart()

		-- correct destination
		local ray = Physics:Raycast( value + Vector3(0, 5, 0), Vector3.Down, 0, 15 )
		if not ray.entity then
			value.y = ray.position.y
		end

		local vehicle = self.core.vehicle
		if vehicle and IsValid( vehicle ) then
			if self.network_destination then
				self.last_position = self.network_destination
			end
	
			-- create driving angle
			local vec_dir = value - self.core.vehicle:GetPosition()
			self.drive_facing = Angle.FromVectors( Vector3.Forward, vec_dir )
			self.drive_facing.roll = 0
		end

		self.network_destination = value 
	elseif key == 'velocity' then
		self.velocity = value
	end
end

function AgentVehicleDriver:Tick( frame_time )

	if self.delayed_enter then
		self:EnterVehicle( self.core.network_object:GetValue( 'in_vehicle' ) )
	end

	local vehicle = self.core.vehicle

	if vehicle and IsValid( vehicle ) then
		-- movement
		self:MovementLogic( frame_time )
	else
		-- idle
	end
end

function AgentVehicleDriver:MovementLogic( frame_time )
	local actor = self.core.actor
	local vehicle = self.core.vehicle
	local current_position = vehicle:GetPosition()
	local network_position = self.core.network_object:GetPosition()
	local facing, turnDiff = nil, nil
	local applyVelocity = false
	local movement = self.core.movement
	local network_destination = network_position

	if self.collisionMode then
		local velocity = ( network_position - current_position )
		local smoothingValue = .5

		local new_velocity = (vehicle:GetLinearVelocity() + (velocity * smoothingValue))
		vehicle:SetLinearVelocity( new_velocity )
		self:VehicleFaceAngle( vehicle, self.core.angle, frame_time )
		self.last_position = vehicle:GetPosition()
	else

		if movement.speed > 0 then
			-- key input
			facing, turnDiff = self:DriveToPosition( actor, vehicle, network_destination )
		end

		-- lerp between last network position and latest
		local ratio = self.lerp_timer:GetMilliseconds() / self.lerp_time 
		if ratio > 1 then ratio = 1 end
		network_position = math.lerp( self.last_position, network_position, ratio )

		-- not every node is above the road, this compensates for that, also corrects
		-- lerp output
		local ray = Physics:Raycast( network_position + Vector3(0, 5, 0), Vector3.Down, 0, 15 )
		if not ray.entity then
			network_position.y = ray.position.y
		end

		local distance = current_position:Distance( network_position )

		if distance > 1 and distance < 6 then
			-- use velocity to smoothly move the vehicle to where it should be
			if not self.velocity_debug then
				self.velocity_debug = Timer()
			else
				if self.velocity_debug:GetMilliseconds() > 250 then
					-- angular
					if self.drive_facing then
						self:VehicleFaceAngle( vehicle, self.drive_facing, frame_time )
					end
					-- velocity
					self:VelocityCatchup( vehicle, current_position, self.core.network_object:GetPosition(), frame_time )
					applyVelocity = true
					self.velocity_debug = nil
				end
			end
		elseif distance > 6 then

			if movement.speed > 0 then
				-- key input update
				facing, turnDiff = self:DriveToPosition( actor, vehicle, network_destination )
			end
			-- translate
			vehicle:SetPosition( network_position )
			vehicle:SetAngle( self.core.angle )
		end
		if not applyVelocity then
			self.last_applied_velocity = 0
		end
	end

	-- update core / fov
	self.core.position = current_position
	self.core.fov:UpdatePositionAndAngle( current_position, vehicle:GetAngle() )
end

function AgentVehicleDriver:VelocityCatchup( vehicle, current_position, network_position, frame_time )
	local velocity = ( network_position - current_position )
	local smoothingValue = .5

	local new_velocity = (vehicle:GetLinearVelocity() + (velocity * smoothingValue)) * .9
	vehicle:SetLinearVelocity( new_velocity )
	self.last_applied_velocity = new_velocity:Length()
end

function AgentVehicleDriver:DriveToPosition( actor, vehicle, position )
	local mathAbs = math.abs
	local actor_position = vehicle:GetPosition()
	local dir_to_target = Angle.NormalisedDir( position, actor_position)
	local required_facing = Angle.FromVectors( Vector3.Forward, dir_to_target )
	required_facing.roll = 0
	local required_heading = 0
	if self.drive_facing then
		required_heading = YawToHeading( math.deg(self.drive_facing.yaw) )
	else
		required_heading = YawToHeading( math.deg(required_facing.yaw) )
	end
	local heading = vehicle:GetHeading()
	
	-- turning

	local turnDiff = DegreesDifference( required_heading, heading )

	local gain = .01

	local turnInput = mathAbs( turnDiff ) * gain

	if turnInput > 1 then turnInput = 1 end -- max input

	if turnDiff < 0 then
		-- turn right
		actor:SetInput( Action.TurnRight, turnInput )
	elseif turnDiff > 0 then
		-- turn left
		actor:SetInput( Action.TurnLeft, turnInput )
	end

	local move_speed = self.core.movement.speed

	-- acceleration / braking

	gain = .05
	local actual_speed = vehicle:GetLinearVelocity():Length()
	local speed = actual_speed - self.last_applied_velocity

	if speed < 0 then speed = 0 end

	local max_speed = 15
	local t = AiDrivingVehicleModifier[vehicle:GetModelId()]
	if t then
		max_speed = t.max_speed
	end

	local speedInput = (move_speed / max_speed )

	if actual_speed > 1 then
		-- modify the input based on the vehicles current speed vs server speed
		-- this will slow the vehicle down slightly if its moving too fast
		-- or speed up if its moving slower than it should be.
		speedInput = speedInput + ( ( speed - move_speed ) * gain )
	end

	if speedInput > 1 then speedInput = 1 end

	if speed < move_speed then
		-- increase
		actor:SetInput( Action.Accelerate, speedInput )
	elseif speed > move_speed then
		-- decrease
		local brakeInput = mathAbs( speed - move_speed ) * gain
		if brakeInput > .1 then
			actor:SetInput( Action.Reverse, brakeInput )
		end
	end

	return required_facing, turnDiff
end

function AgentVehicleDriver:VehicleFaceAngle( vehicle, newRotation, dt )
	local lastRotation = vehicle:GetAngle()
	newRotation.pitch = lastRotation.pitch
	newRotation.roll = lastRotation.roll

	local deltaRotation = (newRotation * lastRotation:Inverse())
	local smoothingValue = 5 

	newAngle = Vector3.Zero
	local ang, axis = Angle.ToAngleAxis(deltaRotation)
	if axis:Length() > 0 then
	    if deltaRotation.w < 0 then
	        axis = axis * -1
	    end

	    local angle = 2 * math.acos(math.abs(deltaRotation.w))
	    newAngle = axis * (angle * smoothingValue )
		vehicle:SetAngularVelocity( newAngle )
	end
end

function AgentVehicleDriver:EnterVehicle( vehicle_id )
	if not vehicle_id then
		self.delayed_enter = false
		return
	end
	local vehicle = Vehicle.GetById( vehicle_id )
	local actor = self.core.actor
	if vehicle and IsValid( vehicle ) and actor and IsValid( actor ) then

		self.core.vehicle = vehicle
		actor:EnterVehicle( vehicle, VehicleSeat.Driver )
		vehicle:SetValue( 'NPCDriver', actor:GetId() )
		self.delayed_enter = false
		self.core.in_vehicle = true
	else
		-- delayed enter
		self.delayed_enter = true
	end
end