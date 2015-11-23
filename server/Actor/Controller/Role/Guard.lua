class 'AgentGuard'

function AgentGuard:__init( core )
	self.core = core
	self.network_object = self.core.network_object
	self.los_npcs = {}
	self.los_players = {}
	self.overseer_task = {}
	self.ai_targets = {}

	-- weapon system
	self.last_aim_position = Vector3()
	self.firing = false

	-- player LoS
	self.los_update = Network:Subscribe( 'PlayerLoSUpdate'..tostring(self.network_object:GetId()), self, self.LoSUpdate )

	-- timers
	self.target_find = Timer()
end

function AgentGuard:Tick( core, frame_time )
	local network_object = core.network_object
	if not network_object or not IsValid(network_object) then return end

	self:EngageEnemyTargets( network_object:GetStreamedPlayers() )
end

function AgentGuard:LoSUpdate( has_los, sender )
	if not sender or not IsValid( sender ) then return end

	-- we can't do line of sight checks on the server, so we need the client
	-- to provide this information for us.
	if has_los then
		self.los_players[sender:GetId()] = true
	else
		self.los_players[sender:GetId()] = nil
	end
end

function AgentGuard:InLoS( player )
	if player and IsValid( player ) then
		return self.los_players[player:GetId()] or false
	end
	return false
end

function AgentGuard:GetPosition()
	return self.core.position
end

function AgentGuard:GetId()
	local network_object = self.core.network_object

	if network_object and IsValid( network_object ) then
		return network_object:GetId()
	end

	return 0
end

function AgentGuard:NPCInLoS( npc )
	local npc_network_object = npc.network_object
	if npc and IsValid( npc ) and npc_network_object and IsValid(npc_network_object) then
		local position = self.core.position
		local npc_position = npc.position
		local npc_network_id = npc_network_object:GetId()
		local info = self.los_npcs[npc_network_id]
		if info and info.result and info.result == 'requested' and info.timer:GetSeconds() < 3 then
			-- don't want to spam requests for the same NPC each frame
			-- if a request has already been made
			return false
		end
		local offset = Vector3( 0, 1, 0 )
		if not info then
			local distance = Distance2D( position, npc_position )
			if position ~= npc_position and distance < 300 then
				local b, taskId = OS:RequestLoSCalculation( self.core.cell, position+offset, npc_position+offset, self )
				self.overseer_task[taskId] = npc
				self.los_npcs[npc_network_id] = { result = 'requested', timer = Timer() }
				return false, true
			else
				-- too far away
				local t = { result = false, timer = Timer() }
				self.los_npcs[npc_network_id] = t

				-- share information, potentially saves a second distance check

				if npc.LoSRequest then
					npc.los_npcs[self.core.network_object:GetId()] = t
				end
			end
		else
			if info.timer:GetSeconds() > 3 then
				local distance = Distance2D( position, npc_position )
				if position ~= npc_position and distance < 300 then
					-- info is too old, request new, but return the result for this frame
					self.los_npcs[npc_network_id] = { result = 'requested', timer = Timer() }
					local b, taskId = OS:RequestLoSCalculation( self.core.cell, position+offset, npc_position+offset, self )
					self.overseer_task[taskId] = npc
					return info.result, true
				else
					-- too far away
					local t = { result = false, timer = Timer() }
					self.los_npcs[npc_network_id] = t

					-- share information, potentially saves a second distance check

					if npc.LoSRequest then
						npc.los_npcs[self.core.network_object:GetId()] = t
					end
				end
			else
				return info.result
			end
		end
	end
	return false
end

function AgentGuard:LoSRequest( info )
	-- returned info from Overseer
	local npc = self.overseer_task[info.taskId]
	local npc_network_object = npc.network_object
	if npc and IsValid( npc ) and npc_network_object and IsValid( npc_network_object ) then
		info.timer = Timer()
		self.los_npcs[npc_network_object:GetId()] = info

		-- share info with other NPC if applicable
		local network_object = self.core.network_object
		if network_object and IsValid( network_object ) and npc.LoSRequest then
			-- can take info
			npc.los_npcs[ network_object:GetId() ] = info
		end
	end
end

function AgentGuard:EngageEnemyTargets( streamed_players )
	if self.target then
		if IsValid(self.target) then
			if self.target.__type ~= 'Player' then
				-- actor target, aim and fire
				if not self.target.dead then
					local has_los = self:NPCInLoS( self.target )
					if has_los then
						self:AttackNPC( self.target )
					else
						self.target = nil
						self:SetFiring( false )
					end
				else
					self.target = nil
					self:SetFiring( false )
				end
			elseif self:InLoS( self.target ) then
				-- player target, aim and fire
				self:AttackPlayer( self.target )
			else
				-- lost LoS
				self.target = nil
				self:SetFiring( false )
			end
		else
			-- target is invalid
			self.target = nil
			self:SetFiring( false )
		end
	else
		if target ~= nil then
			self.target = target
			return
		end

		local agent_faction = self.core.faction

		for p in streamed_players do
			local player_faction = p:GetValue('faction') or 6

			if agent_faction ~= player_faction and not IsFriendly[agent_faction][player_faction] then
				if self:InLoS( p ) then
					self.target = p
					break
				end
			end
		end
		-- return if we've found a player target
		if self.target then return end

		if self.target_find:GetSeconds() > 1 then
			self.target_find:Restart()
			-- no player targets, find an AI target
			local current_cell = self.core.cell
			local cells = GetNearbyCells( current_cell.x, current_cell.y )
			local actors = {}
			-- collect all actors in nearby cells
			for i=1,#cells do
				local cell = cells[i]
				if cell then
					for j=1,#cell.actors do
						local actor = cell.actors[j]
						if not actor.dead and not IsFriendly[agent_faction][actor_faction] then
							table.insert( actors, actor )
						end
					end
				end
			end
			self.ai_targets = actors
		end
		-- check nearby actors for potential targets
		local frame_requests = 0
		local t = self.ai_targets
		for i=1,#t do
			local actor = t[i]
			if actor then
				local actor_faction = actor.faction
				if agent_faction ~= actor_faction then
					local has_los, request_made = self:NPCInLoS( actor )
					if request_made then
						frame_requests = frame_requests + 1
						if frame_requests >= 1 then
							-- max 1 NPC LoS requests per tick
							break
						end
					end
					if has_los then
						self.target = actor
					end
				end
			end
		end
	end
end

function AgentGuard:AttackNPC( actor )
	local health = actor.network_object:GetValue( 'health' )

	if health > 0 then
		local position = actor:GetPosition() + Vector3( 0, 1, 0 )
		self:UpdateFireLocation( position )

		local weapon = self.core:GetEquippedWeapon()

		if not weapon then return end

		local weapon_info = WI:GetWeaponInfo( weapon.id )

		if not weapon_info then return end

		actor:Damage( self, weapon_info )

		self:SetFiring( true )
	else
		-- target is dead
		self:SetFiring( false )
		self.target = nil
	end
end

function AgentGuard:AttackPlayer( player )
	if player:GetHealth() > 0 then
		local position = player:GetPosition() + Vector3( 0, 1, 0 )
		
		self:UpdateFireLocation( position )
		self:SetFiring( true )
	else
		-- target dead
		self:SetFiring( false )
		self.target = nil

		-- clear LoS
		self.los_players[player:GetId()] = nil
	end
end


function AgentGuard:UpdateFireLocation( position )
	if self.last_aim_position ~= position then
		self.last_aim_position = position
		self.network_object:SetNetworkValue( 'aim_position', position )
	end
end

function AgentGuard:SetFiring( b )
	if self.firing ~= b then
		self.firing = b
		self.network_object:SetNetworkValue( 'fire', b )
	end
end

function AgentGuard:Remove()
	-- remove player los update network subscription
	if self.los_update then
		Network:Unsubscribe( self.los_update )
		self.los_update = nil
	end
end