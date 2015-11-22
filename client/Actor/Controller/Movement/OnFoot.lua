class 'AgentOnFoot'

function AgentOnFoot:__init( core )
	self.core = core
	self.ragdollMode = false
	self.anim_timer = Timer()
	self.last_anim = AnimationState.SUprightIdle
end

function AgentOnFoot:Update( e )
	local key = e.key
	local value = e.value

	if key == 'ragdollforce' then
		local actor = self.core.actor
		if actor and IsValid(actor) then
			actor:SetHealth(.01)
			actor:SetBaseState( AnimationState.SHitreactUncontrolledFlight )
			self.last_anim = AnimationState.SHitreactUncontrolledFlight
			actor:SetPosition( actor:GetPosition() + (value*.025) )
			if value:Length() > 1 then
				self.ragdollMode = true
				self.anim_timer:Restart()
			else
				actor:SetHealth(1)
				actor:SetPosition( self.core.actor:GetPosition() )
				self.ragdollMode = false
			end
		end
	end
end

function AgentOnFoot:Tick( frame_time )
	local actor = self.core.actor
	if not actor then return end

	if self.ragdollMode then
		if self.last_anim == AnimationState.SHitreactUncontrolledFlight then
			actor:SetHealth(.01)
		end
		actor:SetBaseState( AnimationState.SHitreactUncontrolledFlight )
		self.last_anim = AnimationState.SHitreactUncontrolledFlight
		self.core.actor:SetHealth(0)
		if self.anim_timer:GetMilliseconds() > 600 then
			self.ragdollMode = false
		end
		return
	end
	actor:SetBaseState( self.last_anim )
	local current_state = self.last_anim
	local anim_timer = self.anim_timer
	if current_state == AnimationState.SHitreactUncontrolledFlight then
		-- getup
		if not actor:GetLinearVelocity():Length() == 0 then return end
		if anim_timer:GetMilliseconds() < 125 then return end
		actor:SetBaseState( AnimationState.SHitreactGetUpBlendin )
		self.last_anim = AnimationState.SHitreactGetUpBlendin
		anim_timer:Restart()
		return
	elseif current_state == AnimationState.SHitreactGetUpBlendin then
		if anim_timer:GetMilliseconds() < 300 then return end
		actor:SetBaseState( AnimationState.SHitreactGetUp )
		self.last_anim = AnimationState.SHitreactGetUp
		anim_timer:Restart()
		return
	else
		if anim_timer:GetMilliseconds() < 1000 then return end
	end

	local distance = actor:GetPosition():Distance( self.core.network_object:GetPosition() )
	if self.core.movement.speed > 0 or distance > .1 then
		-- movement
		self:MovementLogic( frame_time )
	else
		-- idle
		actor:SetBaseState( AnimationState.SUprightIdle )
		self.last_anim = AnimationState.SUprightIdle
	end
end

function AgentOnFoot:MovementLogic( frame_time )
	local actor = self.core.actor
	local current_position = actor:GetPosition()
	local network_position = self.core.network_object:GetPosition()

	local distance = current_position:Distance( network_position )
	if distance > 1 then
		self:VelocityCatchup( actor, current_position, network_position, frame_time )
	end
	if distance < 11 then
		if distance > 2 then
			-- timed translate
			if not self.translate_timer then
				-- create timer
				self.translate_timer = Timer()
			else
				if self.translate_timer:GetMilliseconds() > 1500 then

					-- translate
					actor:SetPosition( network_position )
					actor:SetAngle( self.core.angle )
					-- clear timer
					self.translate_timer = nil
				end
			end
		else
			-- clear timer
			if self.translate_timer then
				self.translate_timer = nil
			end
		end
		if distance > .05 then
			-- calculate and rotate actor towards network angle
			local current_angle = actor:GetAngle()
			local move_dir = Angle.NormalisedDir( network_position, current_position )
			local angle = Angle.FromVectors( Vector3.Forward, move_dir )
			angle.roll = 0
			angle.pitch = 0

			local deltaRotation = ( current_angle * angle:Inverse() )
			local yaw_difference = math.deg(math.abs( deltaRotation.yaw ))
			if yaw_difference < 150 then
				-- turn
				local angle = Angle.RotateToward( current_angle, angle, math.rad(self.core.movement.max_turn_rate) )
				actor:SetAngle( angle )
			else
				-- translate
				actor:SetAngle( self.core.angle )
			end

			-- movement
			self:MoveToPosition( actor, network_position, distance )
			self.core.fov:UpdatePositionAndAngle( current_position, angle )
		else
			actor:SetInput( Action.MoveForward, 0 )
			actor:SetBaseState( AnimationState.SUprightIdle )
			self.last_anim = AnimationState.SUprightIdle
		end
	else
		-- translate
		actor:SetPosition( network_position )
		actor:SetAngle( self.core.angle )
	end
	self.core.position = current_position
end

function AgentOnFoot:VelocityCatchup( actor, current_position, network_position, frame_time )
	local velocity = ( network_position - current_position )
	local smoothingValue = .25

	local new_velocity = (actor:GetLinearVelocity() + (velocity * smoothingValue)) * .9
	actor:SetLinearVelocity( new_velocity )
	self.last_applied_velocity = new_velocity:Length()
end

function AgentOnFoot:MoveToPosition( actor, position, distance )
	-- local gain = 0.05
	-- minus distance from current_speed to smoothly move the actor closer
	-- to its network_position
	local speed = self.core.movement.speed

	if speed == 0 then
		speed = distance
	end

	local speed_input = speed / 5.5
	if speed_input > 0 and speed_input < .2 then
		speed_input = .2
	end
	if speed_input > 1 then speed_input = 1 end
	
	actor:SetInput( Action.MoveForward, speed_input )
	actor:SetBaseState( AnimationState.SUprightBasicNavigation )
	self.last_anim = AnimationState.SUprightBasicNavigation
end