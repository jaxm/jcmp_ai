class 'RescueObjective'

function RescueObjective:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = AiGoal.RescueObjective, 
		model_id = model, 
		faction = self.faction,
		health = 100,
		name = 'Objective NPC'
	} )
	self.npc.spawnset = self
	self.npc:SetStreamDistance( 300 )
end

function RescueObjective:GetPosition()
	return self.npc:GetPosition()
end

function RescueObjective:Remove()
	-- self:RemoveEntity( self.npc )
	if self.npc then
		self.npc:Remove()
	end
	self = nil
end

function RescueObjective:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end