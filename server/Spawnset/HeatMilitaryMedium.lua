class 'HeatMilitaryMedium'

function HeatMilitaryMedium:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	-- local model = actorModels[random( 1, #actorModels )]
	local model = 52

	local rand = ceil(random(2))

	if rand == 1 then
		model = 66
	end

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = args.goal, 
		model_id = model,
		faction = self.faction,
		health = 500
	} )
	self.npc.spawnset = self

	local name = 'Enforcer'
	
	-- self.npc:SetDrivingProfile( AiDrivingProfile.Standard )
	self.npc:SetStreamDistance( 300 )

	local rand = ceil(random(6))
	if rand == 1 then
		-- 1h shotgun
		self.npc:GiveWeapon( 2, Weapon( 4, 6, 1000 ) )
	elseif rand == 2 then
		-- scorpion SMG
		self.npc:GiveWeapon( 2, Weapon( 2, 28, 1000 ) )
	elseif rand == 3 then
		-- Assault rifle
		self.npc:GiveWeapon( 2, Weapon( 11, 4, 1000 ) )

	elseif rand == 4 then
		-- sniper
		name = 'Sniper'
		self.npc:GiveWeapon( 2, Weapon( 14, 20, 1000 ) )
	else
		-- pump-action shotgun
		self.npc:GiveWeapon( 2, Weapon( 13, 28, 1000 ) )
	end

	self.npc.network_object:SetNetworkValue( 'name', name )
end

function HeatMilitaryMedium:GetPosition()
	return self.npc:GetPosition()
end

function HeatMilitaryMedium:Remove()
	-- self:RemoveEntity( self.npc )

	if self.event then
		self.event:RemoveAgent( self )
	end

	if self.npc then
		self.npc:Remove()
	end

	self = nil
end

function HeatMilitaryMedium:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end