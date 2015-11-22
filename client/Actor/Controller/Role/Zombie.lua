class 'AgentZombie'

function AgentZombie:__init( core )
	self.core = core

	-- player LoS
	self.los_timer = Timer()
	self.has_los = false
	self.network_id = self.core.network_object:GetId()

	-- animation
	self.anim_timer = Timer()
	self.attack_anim = nil

	local actor = self.core.actor
	if actor and IsValid(actor) then
		actor:EnableAutoAim()
	else
		self.delayed_autoaim = true
	end
end

function AgentZombie:Update( e )
	local key = e.key
	local value = e.value
	if key == 'npc_melee_attack' then
		if AM then
			local npc = AM.actors[value]
			if npc then
				self:PlayMeleeAttack( npc.position )		
			end
		end
	elseif key == 'player_melee_attack' then
		local id = value
		local player = Player.GetById(id)
		if player and IsValid( player ) then
			self:PlayMeleeAttack( player:GetPosition() )
		end
	end
end

function AgentZombie:PlayMeleeAttack( target_position )
	local actor = self.core.actor
	if not actor or not IsValid(actor) then return end
	local angle = target_position - actor:GetPosition()
	angle = Angle.FromVectors( Vector3.Forward, angle:Normalized() )
	self.core.angle = angle
	actor:SetAngle( angle )
	local random = math.ceil(math.random(2))
	self.anim_timer:Restart()
	if random == 1 then
		self.attack_anim = AnimationState.LaSOverThrowGrenade
		actor:SetBaseState( AnimationState.SUprightIdle )
		actor:SetUpperBodyState( AnimationState.UbSIdle )
		actor:SetLeftArmState( AnimationState.LaSIdle )
	else
		self.attack_anim = AnimationState.LaSOverThrowGrenade
		actor:SetBaseState( AnimationState.SUprightIdle )
		actor:SetUpperBodyState( AnimationState.UbSIdle )
		actor:SetLeftArmState( AnimationState.LaSIdle )
	end
end

function AgentZombie:Tick()
	local timer = self.los_timer
	if timer:GetMilliseconds() > 250 then
		timer:Restart()
		local los = self:GetPlayerInLoS()
		if los ~= self.has_los then
			-- update server
			self.has_los = los
			Network:Send( 'PlayerLoSUpdate'..tostring( self.network_id ), los )
		end
	end
	local actor = self.core.actor

	if self.delayed_autoaim and actor and IsValid(actor) then
		actor:EnableAutoAim()
		self.delayed_autoaim = nil
	end

	if self.attack_anim then
		if self.anim_timer:GetMilliseconds() < 400 then
			actor:SetLeftArmState( self.attack_anim )
		else
			local actor = self.core.actor
			actor:SetBaseState( AnimationState.SUprightIdle )
			actor:SetUpperBodyState( AnimationState.UbSIdle )
			actor:SetLeftArmState( AnimationState.LaSIdle )
			self.attack_anim = nil
		end
	end
end

function AgentZombie:GetPlayerInLoS()
	if 1 == 1 then return false end
	if not IsValid( LocalPlayer ) then return false end

	local actor = self.core.actor
	local actor_position = actor:GetPosition() + Vector3( 0, 1.5, 0 )
	if IsNaN( actor_position ) then return end
	local player_position = LocalPlayer:GetPosition() + Vector3( 0, 1.25, 0 )

	if IsNaN( player_position ) then return end

	-- adjust height for vehicle seating
	if LocalPlayer:GetVehicle() then
		player_position = player_position - Vector3(0, .5, 0)
	end

	local vec_dir = player_position - actor_position
	vec_dir:Normalize()

	local ray = Physics:Raycast( actor_position, vec_dir, 0, 1000, false )
	local entity = ray.entity

	if entity and IsValid(entity) and entity.__type == 'LocalPlayer' then
		return true
	end
	return false
end

function AgentZombie:Remove()
	if self.has_los then
		Network:Send( 'PlayerLoSUpdate'..tostring( self.network_id ), false )
	end
end