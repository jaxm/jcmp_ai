class 'ActorManager'

function ActorManager:__init( ... )
	self.actors = {}
	self.actors_id = {}
	self.cell_actors = {}
	self.frame_number = 1

	self.loaded_successfully = false

	self.timers = {
		delay_tick = Timer(),
		actor_tick = Timer(),
		on_foot = Timer()
	}

	self.coroutine = nil

	self.events = {
		unload = Events:Subscribe( 'ModuleUnload', self, self.CleanupItems ),
		delayed_load = Events:Subscribe( 'PostTick', self, self.DelayedLoad ),
		map_loaded_trigger = Events:Subscribe( 'MapsLoaded', self, self.MapLoadedTrigger ),
		car_jack = Events:Subscribe( 'PlayerEnterVehicle', self, self.PlayerEnterVehicle )		
	}

	self.network_events = {
		hit_by_car = Network:Subscribe( 'ActorHitByCar', self, self.ActorHitByCar ),
		car_collision = Network:Subscribe( 'VehicleCollideEvent', self, self.VehicleCollideEvent )
	}

end

function ActorManager:CreateNPC( args )
	local npc = AgentCore( args )
	table.insert( AM.actors, npc )
	return npc
end

function ActorManager:RemoveNPC( npc )
	local actors = self.actors
	for i=1, #actors do
		local actor = actors[i]
		if actor == npc then
			table.remove( self.actors, i )
			return
		end
	end
end

function ActorManager:DelayedLoad( ... )

	if self.timers.delay_tick:GetMilliseconds() < 1000 then return end

	Events:Unsubscribe( self.events.delayed_load )
	self.events.delayed_load = nil


	self.loaded_successfully = true

	local player = Player.GetById(0)

	if not player then return end
end

function ActorManager:MapLoadedTrigger()
	local player = Player.GetById(0)

	if not player then return end

	-- enable the following if you'd like to check out the taxi script

	-- local position = Vector3( -15746.348633, 203.157974, -2489.254150 ) -- long taxi path start
	-- player:SetPosition( position )
	-- local taxi = Taxi( position, Angle(), Faction.Citizen, 0 )
end

function ActorManager:ActorHitByCar( t, attacker )
	if not attacker or not IsValid( attacker ) then return end
	
	local WNO = t.WNO
	if not WNO or not IsValid(WNO) then return end

	local actor = self.actors_id[WNO:GetId()]

	if actor then
		t.attacker = attacker
		actor:HitByVehicle( t )
	end
end

function ActorManager:VehicleCollideEvent( t, attacker )
	if not attacker or not IsValid( attacker ) then return end

	local actor = self.actors_id[ t.WNO:GetId() ]
	if actor then
		t.attacker = attacker
		actor:VehicleCollision( t )
	end
end

function ActorManager:PlayerEnterVehicle( e )
	if not e.is_driver then return end

	local player = e.player
	if not player or not IsValid( player ) then return end

	local vehicle = e.vehicle
	if not vehicle or not IsValid( vehicle ) then return end

	-- driver

	local npc_id = vehicle:GetValue( 'NPCDriver' )

	if not npc_id then return end

	-- npc driver

	local old_driver = self.actors_id[npc_id]

	if not old_driver or not IsValid( old_driver ) then return end

	vehicle:SetValue( 'NPCDriver', nil )

	local network_object = old_driver.network_object

	network_object:SetNetworkValue( 'in_vehicle', nil )
	network_object:SetStreamDistance( 250 )

	old_driver:ConfigureNPC( { goal = AiGoal.Panic } )

	local jack_position = player:GetPosition()
	network_object:SetPosition( jack_position )
	local movement_lc = old_driver.logic_controller[1]
	movement_lc.position = jack_position
	local lc = old_driver.logic_controller[2]
	if lc then
		table.insert( lc.avoid, player )
	end

end

function ActorManager:GetCellObjects( x, y )
	-- returns the objects contained inside of the cell
	-- as well as the neighbouring cells objects
	local t = {}
	t[#t+1] = self:ReturnCellTable( x, y )
	t[#t+1] = self:ReturnCellTable( x-1, y-1 )
	t[#t+1] = self:ReturnCellTable( x+1, y+1 )
	t[#t+1] = self:ReturnCellTable( x-1, y+1 )
	t[#t+1] = self:ReturnCellTable( x+1, y-1 )
	t[#t+1] = self:ReturnCellTable( x-1, y )
	t[#t+1] = self:ReturnCellTable( x+1, y )
	t[#t+1] = self:ReturnCellTable( x, y-1 )
	t[#t+1] = self:ReturnCellTable( x, y+1 )

	return t
end

function ActorManager:ReturnCellTable( x, y )
	if self.cell_actors[x] and self.cell_actors[x][y] then
		return self.cell_actors[x][y]
	end

	return nil
end

last_id = 1
closest_entity_timer = Timer()

function ActorManager:LogicTick()
	if tGetMS(closest_entity_timer) > 100 then
		closest_entity_timer:Restart()
		self:RebuildClosestEntityWithFoV()
	end

	local id = last_id
	local t = self.actors
	local loop_timer = Timer()

	for i=id,#t do
		local actor = t[i]
		if actor then
			local class_timer = actor.timer
			local time = tGetMS( class_timer )
			if time > actor.time then
				class_timer:Restart()
				-- execute logic code
				actor:Tick( time / 1000 )
			end
		end

		if tGetMS(loop_timer) > 1 then
			last_id = i + 1
			return
		end
	end

	-- if code gets here, then we've fully cycled the actor table
	last_id = 1
end

function ActorManager:LogicTickExtended()
	local id = last_id
	local t = self.actors
	local loop_timer = Timer()

	for i=id,#t do
		local actor = t[i]
		if actor then
			local class_timer = actor.timer
			local time = tGetMS( class_timer )
			if time > actor.time then
				class_timer:Restart()
				-- execute logic code
				actor:Tick( time / 1000 )
			end
		end

		if tGetMS(loop_timer) > time_left then
			last_id = i + 1
			return
		end
	end

	-- if code gets here, then we've fully cycled the actor table
	last_id = 1
end

Console:Subscribe( 'actors', function()
	print(#AM.actors)
	local zero_count = 0
	for k,v in pairs(AM.actors) do
		local cell = v.cell

		local actor_cell = GetCell(cell.x, cell.y)

		print(cell.x, cell.y, #actor_cell.pedestrian_traffic, v.logic_controller[2])
		if #actor_cell.pedestrian_traffic == 0 then
			zero_count = zero_count + 1
		end
	end
	print('zero_count:', zero_count)
end )

function ActorManager:RebuildClosestEntityWithFoV()

	for c=1,#GlobalActiveCells do
		local cell = GlobalActiveCells[c]
		if cell and #cell.actors > 0 then
			local i = 1
			local actors = cell.actors
			local timer = Timer()
			while i <= #actors do
				if timer:GetSeconds() > 1 then
					print('ActorManager:RebuildClosestEntityWithFoV timeout')
					break
				end
				local actor = actors[i]
				local actor_fov = actor.fov
				if actor.in_vehicle and actor_fov then
					local closest_distance = 500
					local closest_entity = nil
					local is_player = false
					for k=1,#actors do
						local other_actor = actors[k]
						if actor ~= other_actor then
							local other_actor_position = other_actor.position
							if actor_fov:IsPointInside( other_actor_position ) then
								local distance = actor.position:Distance( other_actor_position )
								if distance < closest_distance then
									closest_entity = other_actor
									closest_distance = distance
								end
							end
						end
					end

					local players = cell.players
					for i=1, #players do
						local player = players[i]
						if player and IsValid(player) then
							local player_position = player:GetPosition()
							if actor_fov:IsPointInside( player_position ) then
								local distance = actor.position:Distance( player_position )
								if distance <= closest_distance then
									closest_entity = player
									closest_distance = distance
									is_player = true
								end
							end
						end
					end

					-- set closest entity
					if closest_entity then
						actor.closest_entity = closest_entity
						actor.closest_entity_distance = closest_distance
					else
						actor.closest_entity = nil
					end
				end
				i = i + 1
			end
		end
	end
end

function ActorManager:CleanupItems( ... )

	local i = 1
	while i <= #self.actors do
		local actor = self.actors[i]
		if actor and actor.network_object and IsValid( actor.network_object ) then
			actor:Remove()
		else
			i = i + 1
		end
	end

	for _,event in pairs(self.events) do
		if event then
			Events:Unsubscribe( event )
		end
	end

	for _,n_event in pairs(self.network_events) do
		if n_event then
			Network:Unsubscribe( n_event )
		end
	end
end

AM = ActorManager()