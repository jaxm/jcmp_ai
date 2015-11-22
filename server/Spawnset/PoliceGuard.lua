class 'PoliceGuard'

function PoliceGuard:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	-- local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = args.goal, 
		model_id = 16,
		faction = self.faction
	} )
	self.npc.spawnset = self
	self.npc.network_object:SetNetworkValue( 'name', 'Police' )
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )
	self.npc:SetStreamDistance( 300 )

	local rand = ceil(random(2))
	if rand == 1 then
		-- revolver
		self.npc:GiveWeapon( 2, Weapon( 4, 7, 1000 ) )
	else
		-- beretta
		self.npc:GiveWeapon( 2, Weapon( 2, 28, 1000 ) )
	end
end

function PoliceGuard:GetPosition()
	return self.npc:GetPosition()
end

function PoliceGuard:Remove()
	-- self:RemoveEntity( self.npc )

	if self.event then
		self.event:RemoveAgent( self )
	end

	if self.npc then
		self.npc:Remove()
	end

	self = nil
end

function PoliceGuard:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end