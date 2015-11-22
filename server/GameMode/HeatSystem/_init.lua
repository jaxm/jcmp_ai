class 'Heat'

function Heat:__init()
	self.player_heat = {}
	self.player_heat_event = {}
	self.heat_tick = Timer()
	self.player_join_event = Events:Subscribe( 'ClientModuleLoad', self, self.PlayerJoin )
	self.player_quit_event = Events:Subscribe( 'PlayerQuit', self, self.PlayerQuit )
	self.player_death_event = Events:Subscribe( 'PlayerDeath', self, self.PlayerDeath )
	self.tick_event = Events:Subscribe( 'PostTick', self, self.Tick )

	self.heat_requirement = {}
	self.heat_requirement[0] = 100
	self.heat_requirement[1] = 500
	self.heat_requirement[2] = 1000
	self.heat_requirement[3] = 2000
	self.heat_requirement[4] = 5000
	self.heat_requirement[5] = 99999999

end

function Heat:Tick()
	local t = self.heat_tick

	-- only run heat calculations every 500 ms
	if t:GetMilliseconds() < 500 then return end
	t:Restart()

	for p in Server:GetPlayers() do
		if p and IsValid( p ) then
			local id = p:GetId()
			local heat_level = self:GetPlayerHeatLevel( p )
			-- if heat_level is nil, heat system is currently disabled for this player
			if heat_level and heat_level > 0 then
				-- heat_level is greater than 0
				local event = self.player_heat_event[id]
				if not event then
					-- heat event currently isn't running for this player, create one!
					self:CreatePlayerHeatEvent( p )
				else
					-- heat event running, update / adjust as needed
					if event.current_level < heat_level then
						-- increase events heat level to match players
						event.current_level = heat_level
					end

					if event.current_level > heat_level then
						-- decrease events heat level to match players
						event.current_level = heat_level
					end
				end
			end
		end
	end
end

function Heat:ResetPlayerHeat( player )
	if player and IsValid( player ) then
		player:SetNetworkValue( 'heat_level', 0 )
		player:SetValue( 'heat', 0 )
		local event = self:GetPlayerHeatEvent( player )
		if event then 
			event.current_level = 0
			event:Remove()
		end
	end
end

function Heat:DisablePlayerHeat( player )
	if player and IsValid( player ) then
		player:SetNetworkValue( 'heat_level', nil )
		player:SetValue( 'heat', nil )
	end
end

function Heat:EnablePlayerHeat( player )
	if player and IsValid( player ) then
		player:SetNetworkValue( 'heat_level', 0 )
		player:SetValue( 'heat', 0 )
	end
end

function Heat:GetPlayerHeatLevel( player )
	if player and IsValid( player ) then
		return player:GetValue( 'heat_level' )
	end	
end

function Heat:CreatePlayerHeatEvent( player )
	if player and IsValid( player ) then
		local id = player:GetId()
		local event = EM:AddEvent( {
						event_type = 'Heat',
						target = player
					} )
		self.player_heat_event[id] = event
		return event
	end	
end

function Heat:GetPlayerHeatEvent( player )
	if player and IsValid( player ) then
		return self.player_heat_event[player:GetId()]
	end	
end

function Heat:IncreasePlayerHeatLevel( player, heat )
	if player and IsValid( player ) then
		local current_heat_level = player:GetValue( 'heat_level' ) or 0
		local current_heat = player:GetValue( 'heat' ) or 0

		current_heat = current_heat + heat

		if current_heat >= self.heat_requirement[current_heat_level] then
			-- only 5 levels of heat difficulty
			if current_heat_level + 1 < 6 then
				-- level increase
				current_heat_level = current_heat_level + 1
				player:SetNetworkValue( 'heat_level', current_heat_level )
				-- reset heat percentage with level increase
				current_heat = 0
			else
				if current_heat >= self.heat_requirement[current_heat_level] then
					-- current heat level is max
					-- current heat perc is max
					return
				end
			end
		end

		-- update player heat percentage
		player:SetValue( 'heat', current_heat )
	end
end

function Heat:SetPlayerHeatLevel( player, level )
	if player and IsValid( player ) then 
		player:SetNetworkValue( 'heat_level', level )
	end
end

function Heat:PlayerJoin( e )
	local player = e.player

	player:SetNetworkValue( 'heat_level', 0 )
	player:SetValue( 'heat', 0 )
end

function Heat:PlayerDeath( e )
	local player = e.player
	self:ResetPlayerHeat( player )
end

function Heat:PlayerQuit( e )
	local player = e.player

	-- clear heat event

	local id = player:GetId()

	if self.player_heat_event[id] then
		EM:RemoveEvent( self.player_heat_event[id] )
		self.player_heat_event[id] = nil
	end
end

H = Heat()