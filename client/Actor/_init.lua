class 'NPC'

function NPC:__init( WNO )
	self.network_object = WNO
	self.position = self.network_object:GetPosition()
	self.angle = WNO:GetValue( 'angle' ) or Angle()
	self.angle_timer = Timer()

	self.fov = AddTriangle( self.position, 10 )

	self.actor = ClientActor.Create( AssetLocation.Game, {
		model_id = self.network_object:GetValue( 'model_id' ) or 6,
		position = self.position,
		angle = self.angle
	} )

	-- aim reticle
	local faction = WNO:GetValue( 'faction' )
	if faction then
		if IsFriendly[Faction.Player][faction] then
			-- friendly
			self.actor:DisableAutoAim()
		else
			-- enemy
			self.actor:EnableAutoAim()
		end
	end

	-- movement
	self.last_input = 0
	self.movement = {
		speed = self.network_object:GetValue( 'speed' ) or 0,
		max_turn_rate = 8
	}

	-- logic controllers
	self.logic_controllers = {}

	-- configure
	self:ConfigureNPC( WNO )

	-- aim at register
	AM.actor_aim[self.actor:GetId()] = self
end

function NPC:Update( e )
	local key = e.key
	local value = e.value

	if key == 'speed' then
		-- movement speed update
		self.movement.speed = value
	elseif key == 'angle' then
		-- facing angle update
		self.angle = value
		self.angle_timer:Restart()

	elseif key == 'health' then
		if value <= 0 then
			if not self.dead then
				local actor = self.actor
				if actor and IsValid(actor) then
					self.actor:SetHealth(0)
					self.dead_timer = Timer()
					self.dead = true
				end
			end
		else
			if self.dead then
				if value > 0 then
					self.dead_timer = nil
					self.dead = false
				end
			end
		end
	elseif key == 'goal' then
		self:ConfigureNPC( self.network_object )
	else
		local movement_lc = self.logic_controllers[1]
		if movement_lc then
			movement_lc:Update( e )
		end
		local logic_lc = self.logic_controllers[2]
		if logic_lc then
			logic_lc:Update( e )
		end
	end
end

function NPC:ConfigureNPC( WNO )
	local goal = WNO:GetValue( 'goal' )

	for i=1,#self.logic_controllers do
		local lc = self.logic_controllers[i]
		if lc then
			if lc.Remove then
				lc:Remove()
			end
		end
	end

	self.goal = goal

	if goal == AiGoal.Wander then
		self:ExitVehicleSanity()
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controllers[1] = movement
	elseif goal == AiGoal.Panic then
		self:ExitVehicleSanity()
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controllers[1] = movement
	elseif goal == AiGoal.Traffic then
		local movement = AgentVehicleDriver( self )
		self.logic_controllers[1] = movement
	elseif goal == AiGoal.TaxiDriver then
		local movement = AgentVehicleDriver( self )
		self.logic_controllers[1] = movement
	elseif goal == AiGoal.Zombie then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controllers[1] = movement
		-- logic
		local logic = AgentZombie( self )
		self.logic_controllers[2] = logic
	elseif goal == AiGoal.RescueObjective then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controllers[1] = movement
		-- logic
		local logic = AgentRescue( self )
		self.logic_controllers[2] = logic
	elseif goal == AiGoal.Guard then
		local in_vehicle = WNO:GetValue( 'in_vehicle' )

		if not in_vehicle then
			-- on foot guard
			local movement = AgentOnFoot( self )
			self.logic_controllers[1] = movement
		else
			-- in vehicle guard
			local movement = AgentVehicleDriver( self )
			self.logic_controllers[1] = movement
		end

		-- logic
		local logic = AgentGuard( self )
		self.logic_controllers[2] = logic
	elseif goal == AiGoal.Pursue then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controllers[1] = movement

		-- logic
		local logic = AgentGuard( self )
		self.logic_controllers[2] = logic
	elseif goal == AiGoal.HeliGuard then
		-- movement
		local movement = AgentHeliPilot( self )
		self.logic_controllers[1] = movement
		-- logic
		local logic = AgentGuard( self )
		self.logic_controllers[2] = logic
	end
end

function NPC:Tick( e )
	local dt = e.delta

	if not self.network_object or not IsValid(self.network_object) then return end
	if not self.actor or not IsValid(self.actor) then return end

	if self.dead then
		self:Kill()
		return
	end

	-- logic
	local lc = self.logic_controllers

	if lc[1] then
		lc[1]:Tick( dt )
	end
	if lc[2] then
		lc[2]:Tick( dt )
	end
end

function NPC:Render()
	if not self.actor or not IsValid(self.actor) then return end
	local wts, on_screen = Render:WorldToScreen( self.actor:GetPosition() )

	if on_screen then

		local lc = self.logic_controllers[2]
		if lc then
			if lc.Render then
				lc:Render( wts )
			end
		end
	end
end

function NPC:Kill()
	if self.dead_timer:GetMilliseconds() > 5 then
		self.actor:SetBaseState( AnimationState.SDead )
	end
end

function NPC:ExitVehicleSanity()
	local actor = self.actor
	if actor and IsValid(actor) then
		local vehicle = actor:GetVehicle()
		if vehicle then
			if IsValid( vehicle ) then
				-- stop the system from putting the actor back into the vehicle
				vehicle:SetValue( 'NPCDriver', nil )
			end
			actor:ExitVehicle()
		end
		self.in_vehicle = false
	end
end

function NPC:Remove()
	self.removed = true
	AM.actor_aim[self.actor:GetId()] = nil
	self.actor:Remove()
	if self.fov then
		RemoveTriangle( self.fov )
	end
	for i=1,#self.logic_controllers do
		local lc = self.logic_controllers[i]
		if lc then
			if lc.Remove then
				lc:Remove()
			end
		end
	end
	self = nil
end