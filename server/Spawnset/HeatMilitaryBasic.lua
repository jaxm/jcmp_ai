class 'HeatMilitaryBasic'

function HeatMilitaryBasic:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	-- local model = actorModels[random( 1, #actorModels )]

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = args.goal, 
		model_id = 61,
		faction = self.faction,
		health = 250
	} )
	self.npc.spawnset = self
	self.npc.network_object:SetNetworkValue( 'name', 'Soldier' )
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )
	self.npc:SetStreamDistance( 300 )

	local rand = ceil(random(3))
	if rand == 1 then
		-- 1h shotgun
		self.npc:GiveWeapon( 2, Weapon( 4, 6, 1000 ) )
	elseif rand == 2 then
		-- scorpion SMG
		self.npc:GiveWeapon( 2, Weapon( 2, 28, 1000 ) )
	else
		-- pump-action shotgun
		self.npc:GiveWeapon( 2, Weapon( 13, 28, 1000 ) )
	end
end

function HeatMilitaryBasic:GetPosition()
	return self.npc:GetPosition()
end

function HeatMilitaryBasic:Remove()
	-- self:RemoveEntity( self.npc )

	if self.event then
		self.event:RemoveAgent( self )
	end

	if self.npc then
		self.npc:Remove()
	end

	self = nil
end

function HeatMilitaryBasic:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end