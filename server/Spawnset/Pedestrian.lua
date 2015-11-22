class 'Pedestrian'

function Pedestrian:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = AiGoal.Wander, 
		model_id = model, 
		faction = self.faction,
		name = 'Civilian'
	} )
	self.npc.spawnset = self
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )
	-- self.npc:GiveWeapon( 2, Weapon( 11, 28, 1000 ) )
	self.npc:SetStreamDistance( 300 )
end

function Pedestrian:GetPosition()
	local npc = self.npc
	if npc and IsValid(npc) then
		return npc:GetPosition()
	end
end

function Pedestrian:Remove()
	-- self:RemoveEntity( self.npc )
	local npc = self.npc
	if npc and IsValid(npc) then
		npc:Remove()
	end
	self = nil
end

function Pedestrian:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	end
end