class 'AgentPursue'

function AgentPursue:__init( core )
	self.core = core
	self.network_object = self.core.network_object
	self.los_npcs = {}
	self.los_players = {}
	self.overseer_task = {}
	self.ai_targets = {}
	self.target = nil

	-- pathfinding
	self.has_requested_path = false

	-- weapon system
	self.last_aim_position = Vector3()
	self.firing = false

	-- player LoS
	self.los_update = Network:Subscribe( 'PlayerLoSUpdate'..tostring(self.network_object:GetId()), self, self.LoSUpdate )

	-- timers
	self.target_find = Timer()
end

function AgentPursue:Tick( core, frame_time )
	local network_object = core.network_object
	if not network_object or not IsValid(network_object) then return end

	self:EngageEnemyTargets( network_object:GetStreamedPlayers() )
end

function AgentPursue:EngageEnemyTargets( streamed_players )
	local target = self.target
	local movement_lc = self.core.logic_controller[1]
	if target then
		if IsValid(target) then

			local weapon = self.core.equipped_weapon

			local weapon_info = WI:GetWeaponInfo( weapon.id )

			if target.__type ~= 'Player' then
				-- actor target, aim and fire
				if not target.dead then
					local has_los = self:NPCInLoS( target )
					if has_los then
						self:AttackNPC( target )
					else
						self:DropTarget()
					end
				else
					-- target dead, reset
					self:DropTarget()
				end
			elseif self:InLoS( target ) and movement_lc.position:Distance( target:GetPosition() ) <= weapon_info.max_range then
				-- player target, aim and fire
				self:AttackPlayer( target )

				-- stop moving
				movement_lc.movement.speed = 0
				-- in LoS again, clear pursue timer
				if self.pursue_timer then
					self.pursue_timer = nil
				end
			else
				-- no LoS, try and move closer to gain LoS
				if not self.pursue_timer then
					-- request path
					self.pursue_timer = Timer()
					self:RequestNewPath()
				else
					-- run path for 15 seconds or until LoS is regained
					-- if no LoS after 15 seconds, drop target
					if self.pursue_timer:GetSeconds() > 15 then
						-- drop target
						self:DropTarget()
					else
						if #movement_lc.path > 0 then
							if movement_lc.movement.speed < 5 then
								movement_lc.movement.speed = movement_lc.movement.speed + 1
							end
						end
					end
				end
				-- self.target = nil
				self:SetFiring( false )
			end
		else
			-- target is invalid
			self:DropTarget()
		end
	else
		-- currently no target
		-- check threat lists first
		local target = nil
		local highest = 0
		if self.threat_table then
			local i = 1
			-- cycle through threat table to find highest threat
			local timer = Timer()
			while i<= #self.threat_table do

				if timer:GetSeconds() > 1 then
					print('AgentPursue:EngageEnemyTargets-threat_table timeout')
					break
				end

				local info = self.threat_table[i]
				local threat = info.target
				
				if threat and IsValid(threat) and info.timer:GetSeconds() < 30 then
					-- target is valid
					if info.threat > highest then
						if threat:GetHealth() <= 0 then
							-- target is dead
							table.remove( self.threat_table, i )
						else
							-- target is alive, is current highest threat
							target = threat
							highest = info.threat
							i = i + 1
						end
					else
						-- threat isn't higher than current highest
						i = i + 1
					end
				else
					-- threat nil or invalid
					table.remove( self.threat_table, i )
				end
			end
		end

		if target ~= nil then
			self.target = target
			return
		end

		local agent_faction = self.core.faction

		for p in streamed_players do

			-- heat value
			local heat_level = p:GetValue( 'heat' )

			if heat_level and heat_level > 0 then
				local player_faction = p:GetValue('faction') or 6

				if agent_faction ~= player_faction and not IsFriendly[agent_faction][player_faction] then
					if self:InLoS( p ) then
						self.target = p
						break
					end
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
						if not actor.dead and agent_faction ~= actor.faction and not IsFriendly[agent_faction][actor.faction] then
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
			if actor and IsValid( actor ) then
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

function AgentPursue:DropTarget()
	self.target = nil
	self:SetFiring(false)
	if self.pursue_timer then
		self.pursue_timer = nil
	end
end

function AgentPursue:HurtEvent( attacker, threat )
	if not attacker or not IsValid( attacker ) then return end

	-- init threat table
	if not self.threat_table then
		self.threat_table = {}
	end

	-- init or increase threat
	local id = attacker:GetId()
	if not self.threat_table[id] then
		-- start threat out at 10
		self.threat_table[id] = { threat = threat, target = attacker, timer = Timer() }
	else
		-- increase threat for attacker
		self.threat_table[id].threat = self.threat_table[id].threat + threat
		self.threat_table[id].timer:Restart()
	end

	-- compare target threat with attacker threat
	local target = self.target
	if target then
		local target_id = target:GetId()
		if not self.threat_table[target_id] then
			-- have no threat on current target, switch
			self:DropTarget()
			self.target = attacker
		else
			-- compare threat levels
			if self.threat_table[id].threat > self.threat_table[target_id].threat then
				-- attacker is more a higher threat, switch to engage attacker
				self:DropTarget()
				self.target = attacker
			end
		end
	else
		-- don't have a target, set attacker as our new target
		self:DropTarget()
		self.target = attacker
	end
end

function AgentPursue:LoSUpdate( has_los, sender )
	if not sender or not IsValid( sender ) then return end

	-- we can't do line of sight checks on the server, so we need the client
	-- to provide this information for us.
	if has_los then
		self.los_players[sender:GetId()] = true
	else
		self.los_players[sender:GetId()] = nil
	end
end

function AgentPursue:InLoS( player )
	if player and IsValid( player ) then
		return self.los_players[player:GetId()] or false
	end
	return false
end

function AgentPursue:GetPosition()
	return self.core.position
end

function AgentPursue:GetId()
	local network_object = self.core.network_object

	if network_object and IsValid( network_object ) then
		return network_object:GetId()
	end

	return 0
end

function AgentPursue:NPCInLoS( npc )
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

function AgentPursue:LoSRequest( info )
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

function AgentPursue:AttackNPC( actor )
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

function AgentPursue:AttackPlayer( player )
	if player and IsValid(player) and player:GetHealth() > 0 then
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


function AgentPursue:UpdateFireLocation( position )
	if self.last_aim_position ~= position then
		self.last_aim_position = position
		self.network_object:SetNetworkValue( 'aim_position', position )
	end
end

function AgentPursue:SetFiring( b )
	if self.firing ~= b then
		self.firing = b
		self.network_object:SetNetworkValue( 'fire', b )
	end
end

function AgentPursue:RequestNewPath()
	local movement_lc = self.core.logic_controller[1]
	if movement_lc then
		self.has_requested_path = true
		GeneratePath( movement_lc.position, self.target:GetPosition(), self, 2, PathPriority.Medium )
	end
end

function AgentPursue:PathSuccess( t )
	self.has_requested_path = false
	local movement_lc = self.core.logic_controller[1]

	if movement_lc then
		t.path[#t.path] = nil
		movement_lc.path = t.path
	end
end

function AgentPursue:PathFailed()
	self.has_requested_path = false
	if self.pursue_timer and self.pursue_timer:GetSeconds() > 15 then
		self:DropTarget()
	else
		self.pursue_timer = Timer()
	end
end

function AgentPursue:Remove()
	-- remove player los update network subscription
	if self.los_update then
		Network:Unsubscribe( self.los_update )
		self.los_update = nil
	end
end