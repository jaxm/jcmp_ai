class 'CombatGrunt'

function CombatGrunt:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = args.goal, 
		model_id = model,
		faction = self.faction
	} )
	self.npc.spawnset = self
	self.npc.network_object:SetNetworkValue( 'name', 'Grunt' )
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )

	self.npc:GiveWeapon( 2, Weapon( 11, 28, 1000 ) )
	self.npc:SetStreamDistance( 300 )
end

function CombatGrunt:GetPosition()
	return self.npc:GetPosition()
end

function CombatGrunt:Remove()
	-- self:RemoveEntity( self.npc )
	if self.npc then
		self.npc:Remove()
	end
	self = nil
end

function CombatGrunt:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end