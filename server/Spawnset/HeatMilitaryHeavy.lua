class 'HeatMilitaryHeavy'

function HeatMilitaryHeavy:__init( args )
	self.position = args.position
	self.angle = args.angle or Angle()
	self.faction = args.faction

	local faction_info = GetFactionInfo( self.faction )

	local actorModels = faction_info.actorModels

	-- local model = actorModels[random( 1, #actorModels )]
	local model = 52
	local name = 'Elite'
	local weapon = nil

	local rand = ceil(random(6))

	if rand == 1 then
		name = 'Captain'
		model = 49
	elseif rand == 3 then
		name = 'Colonel'
		model = 101
	end

	self.npc = AM:CreateNPC( {
		position = self.position,
		goal = args.goal, 
		model_id = model,
		faction = self.faction,
		health = 1000
	} )
	self.npc.spawnset = self
	self.npc:SetStreamDistance( 300 )
	if weapon == nil then
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
			-- heavy machinegun
			self.npc:GiveWeapon( 2, Weapon( 28, 26, 1000 ) )
		else
			-- pump-action shotgun
			self.npc:GiveWeapon( 2, Weapon( 13, 28, 1000 ) )
		end
	else
		-- pre-assigned
		self.npc:GiveWeapon( 2, weapon )
	end

	self.npc.network_object:SetNetworkValue( 'name', name )
end

function HeatMilitaryHeavy:GetPosition()
	return self.npc:GetPosition()
end

function HeatMilitaryHeavy:Remove()
	-- self:RemoveEntity( self.npc )

	if self.event then
		self.event:RemoveAgent( self )
	end

	if self.npc then
		self.npc:Remove()
	end

	self = nil
end

function HeatMilitaryHeavy:RemoveEntity( entity )
	if entity and IsValid(entity) then
		entity:Remove()
	else
		AM:QueueDestruction( entity )
	end
end