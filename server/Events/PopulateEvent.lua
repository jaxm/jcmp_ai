class 'PopulateEvent'

function PopulateEvent:__init( t )
	self.initialized = false
	self.agents = {}
	self.info = t
	self.network_object = WorldNetworkObject.Create( t.centerPoint )
	self.network_object:SetStreamDistance( t.activateDistance )
end

function PopulateEvent:Tick()

	local network_object = self.network_object

	if not network_object or not IsValid( network_object ) then return end

	local players = iterator.count( network_object:GetStreamedPlayers() )

	if players > 0 and not self.initialized then
		-- initialize event
		self:Create()
	elseif players == 0 and self.initialized then
		-- cleanup event
		self:Remove()
	end
end

function PopulateEvent:Create()
	local t = self.info

	for i=1,#t.actors do
		local actor = t.actors[i]
		local new_agent = nil
		if actor.type == 'CombatGrunt' then
			new_agent = CombatGrunt( actor )
		elseif actor.type == 'MilitaryAPC_Cannon' then
			new_agent = MilitaryAPC_Cannon( actor )
		end

		if new_agent then
			table.insert( self.agents, new_agent )
		end
	end

	self.initialized = true
end

function PopulateEvent:Remove()
	local t = self.agents
	for i=1,#t do
		local agent = t[i]
		if agent then
			agent:Remove()
		end
	end

	self.initialized = false
end