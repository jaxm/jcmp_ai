class 'Zombie'

function Zombie:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	-- local actorModels = faction_info.actorModels

	-- local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = AiGoal.Zombie, 
		model_id = args.model or 97, 
		faction = self.faction,
		health = 500
	} )
	self.npc.spawnset = self
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )
	-- self.npc:GiveWeapon( 2, Weapon( 11, 28, 1000 ) )
	self.npc:SetStreamDistance( 300 )
end

function Zombie:GetPosition()
	return self.npc:GetPosition()
end

function Zombie:Remove()
	-- self:RemoveEntity( self.npc )
	if self.npc then
		self.npc:Remove()
	end
	self = nil
end

function Zombie:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end