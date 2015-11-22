class 'AgentZombie'

function AgentZombie:__init( core )
	self.core = core
	self.regen_timer = Timer()
	self.los_players = {}
	self.blacklisted_targets = {}
	self.attack_timer = Timer()
	self.max_speed = 10

	-- pathfinding
	self.side = self.core.street_side or ceil(random(2))
	self.path = {}
	self.has_requested_path = false
	self.path_failed_count = 0

	-- target
	self.target = nil
	self.target_last_position = nil

	-- player LoS
	self.los_update = Network:Subscribe( 'PlayerLoSUpdate'..tostring(self.core.network_object:GetId()), self, self.LoSUpdate )

	self.core.network_object:SetNetworkValue('name', 'Zombie')
end

function AgentZombie:Tick( core, frame_time )
	-- get movement lc
	local movement_lc = core.logic_controller[1]

	if not movement_lc then return end

	-- passive regeneration
	local timer = self.regen_timer
	if timer:GetSeconds() > 5 then
		timer:Restart()
		self:Regenerate( 10 )
	end

	local target = self.target
	-- don't have a target? get one
	if not target then
		target = self:FindNearbyTarget()
	end

	-- check if our current target is valid
	if self:IsValidZombieTarget( target ) then
		self.target = target
	else
		self.target = nil
		return
	end

	-- target is valid, eat it!
	local max_speed = self.max_speed

	-- distance check / combat
	local position = target:GetPosition()

	-- distance between targets current position and last known position
	local last_position = self.target_last_position

	if last_position then
		local distance = last_position:Distance( position )
		if distance > 1 then
			-- target has moved, request new path
			if not self.has_requested_path then
				self:RequestNewPath( movement_lc.position )
				self.target_last_position = position
			end
		end
	else
		-- initialize position
		self.target_last_position = position
	end

	if target then
		if movement_lc.movement.speed < max_speed then
			if movement_lc.movement.speed > 3 then
				movement_lc.movement.speed = movement_lc.movement.speed + 1
				if movement_lc.movement.speed > max_speed then
					movement_lc.movement.speed = max_speed
				end
			else
				-- minimum move speed for zombies
				-- make them faster to react
				movement_lc.movement.speed = 6
			end
		end
	end

	-- distance to target
	local distance = position:Distance( movement_lc.position )

	if distance <= 2 and self.attack_timer:GetMilliseconds() > 500 then
		-- in melee range
		self:BiteTarget( target )
		movement_lc.movement.speed = 0
	else
		-- move in range to bite target
		if distance > 5 then
			-- use pathing to get to target
			local path = movement_lc.path
			if #path <= 1 and not movement_lc.has_requested_path then
				if not self.has_requested_path then
					movement_lc.precision_movement = nil
					self:RequestNewPath( movement_lc.position )
					return
				end
				return
			end
			return
		else
			movement_lc.precision_movement = .25
			if distance > 2 then
				self.attack_timer:Restart()
			end
			-- run directly at target
			if target.__type ~= 'Player' then
				local velocity = target.velocity
				if velocity then
					movement_lc.path_destination = position + (velocity*2)
				else
					movement_lc.path_destination = position
				end
			else
				movement_lc.path_destination = position + target:GetLinearVelocity()
			end
		end
	end
end

function AgentZombie:IsValidZombieTarget( target )
	if target then
		if IsValid( target ) then
			if target.__type ~= 'Player' then
				-- npc
				if not target.removed and not target.vehicle and not target.immune then
					if not target.dead then
						if target.goal ~= AiGoal.Zombie then
							local id = target:GetId()
							local blacklist_timer = self.blacklisted_targets[id]
							if not blacklist_timer or blacklist_timer:GetSeconds() > 30 then
								-- passes for a valid zombie target
								if id then
									self.blacklisted_targets[id] = nil
								end
								return true
							end
						end
					else
						-- target is dead, convert to zombie
						self.core.spawnset.event:ConvertNPCToZombie( target )
					end
				end
			else
				-- player
				if target:GetHealth() > 0 then
					local id = target:GetId()
					local blacklist_timer = self.blacklisted_targets[id]
					if not blacklist_timer or blacklist_timer:GetSeconds() > 30 then

						-- clear blacklist
						self.blacklisted_targets[id] = nil
						return true
					end
				end
			end
		end
	end
	return false
end

function AgentZombie:ClearTarget()
	self.target = nil
	self.path = {}
	local movement_lc = self.core.logic_controller[1]
	if movement_lc then
		movement_lc.path = {}
		movement_lc.movement.speed = 0
	end
	self.target_last_position = nil
end

function AgentZombie:LoSUpdate( has_los, sender )
	if not sender or not IsValid( sender ) then return end

	-- we can't do line of sight checks on the server, so we need the client
	-- to provide this information for us.

	if has_los then
		self.los_players[sender:GetId()] = true
	else
		self.los_players[sender:GetId()] = nil
	end
end

function AgentZombie:InLoS( player )
	if player and IsValid( player ) then
		return self.los_players[player:GetId()] or false
	end
	return false
end

function AgentZombie:FindNearbyTarget()

	-- only want to find a target that isn't a zombie
	-- either normal ped or player
	-- prioritize players that are in LoS over NPC's
	local movement_lc = self.core.logic_controller[1]
	local position = movement_lc.position

	-- first check zombies current cell
	local cell = GetCellFromPosition( position )
	local target, distance = self:FindTargetInCell( position, cell, 512 )

	if not target then
		local cell_table = GetNearbyCells( cell.x, cell.y )
		for c=1,#cell_table do
			local cell = cell_table[c]
			if cell then
				target, distance = self:FindTargetInCell( position, cell, distance )
				if distance < 50 then
					break
				end
			end
		end
	end

	return target
end

function AgentZombie:FindTargetInCell( position, cell, closest_distance )
	local target = nil
	local getDist = Vector3.Distance
	if cell then
		for i=1,#cell.actors do
			if not found_close_ped then
				local ped = cell.actors[i]
				if ped then
					if self:IsValidZombieTarget( ped ) then
						local distance = getDist( ped.position, position )
						if distance < closest_distance then
							closest_distance = distance
							target = ped
							if distance < 25 then
								-- found close target, break early
								break
							end
						end
					end
				end
			end
		end

		for i=1,#cell.players do
			if not found_close_player then
				local player = cell.players[i]
				if self:IsValidZombieTarget( player ) then
					local distance = getDist( player:GetPosition(), position )
					if distance < closest_distance then
						closest_distance = distance
						target = player
						if distance < 25 then
							-- found close target, break early
							break
						end
					end
				end
			end
		end
	end

	return target, closest_distance
end

function AgentZombie:HurtEvent( attacker )
	if not attacker or not IsValid( attacker ) then return end
	if attacker.goal and attacker.goal == AiGoal.Traffic or attacker.goal == AiGoal.Zombie then return end
	local target = self.target
	if target and not IsValid(target) then
		self.target = nil
		target = nil
	end

	-- wake up
	if self.core.time > 100 then
		self.core.time = 100
	end

	-- type check
	if target and target.__type == attacker.__type then
		-- already chasing attacker?
		if target and target == attacker then return end
	end

	if attacker.__type == 'Player' then

		-- clear blacklist if needed

		local id = attacker:GetId()

		if self.blacklisted_targets[id] then
			self.blacklisted_targets[id] = nil
		end

		-- hurt timer to stop two players from kiting a zombie between them
		-- max it'll switch is every 10 seconds
		if self.hurt_target_switch then
			if self.hurt_target_switch:GetSeconds() < 10 then
				return
			end
		end

		-- create timer
		self.hurt_target_switch = Timer()
	end

	self.target = attacker
	self.path = {}
	local movement_lc = self.core.logic_controller[1]
	movement_lc.path = {}
	self.target_last_position = nil
	if not self.has_requested_path then
		self:RequestNewPath( movement_lc.position )
	end
end

function AgentZombie:BiteTarget( target )
	local is_npc = ( target.__type ~= 'Player' )

	local network_object = self.core.network_object

	if not network_object or not IsValid(network_object) then return end

	if is_npc then
		-- agent
		-- turn target into zombie
		local target = self.target
		if target and IsValid( target ) then
			local target_network_object = target.network_object
			if target_network_object and IsValid(target_network_object) then
				local health = target_network_object:GetValue('health')
				if health > 0 then
					self.attack_timer:Restart()
					local bite_damage = 25
					-- hurt
					self:Regenerate( 25 )
					target:Hurt( self, bite_damage )
					local id = target:GetId()
					network_object:SetNetworkValue( 'npc_melee_attack', id )
				end
			else
				self:ClearTarget()
			end
		else
			self:ClearTarget()
		end

	else
		-- player
		local health = self.target:GetHealth()
		if health > 0 then
			local new_health = health - .1
			self.target:SetHealth( new_health )
			self:Regenerate( 50 )
			network_object:SetNetworkValue( 'player_melee_attack', target:GetId() )
			self.attack_timer:Restart()
			if new_health <= 0 then
				-- create zombie!
				self.core.spawnset.event:ConvertPlayerToZombie( self.target )

				-- clear target
				self.target = nil
				self.target_last_position = nil
			end
		end
	end
end

function AgentZombie:Regenerate( n )
	local network_object = self.core.network_object
	local current_health = network_object:GetValue( 'health' )
	local max_health = network_object:GetValue( 'max_health' )

	-- scale move speed based on health
	self.max_speed = ceil((current_health / max_health) * 10)

	if self.max_speed < 7 then
		self.max_speed = 7
	end

	-- check if healing required
	if current_health < max_health then
		local new_health = current_health + n
		-- cap out at max health
		if new_health > max_health then
			new_health = max_health
		end
		-- set new health value
		network_object:SetNetworkValue( 'health', new_health )
	end
end

function AgentZombie:RequestNewPath( start_position )

	-- no path, lets get one!
	if self.target then
		local target_position = self.target:GetPosition()
		local distance = start_position:Distance( target_position )
		if distance > 4 then
			GeneratePath( start_position, target_position, self, 2, PathPriority.Medium )
			self.has_requested_path = true
		end
	end
end

function AgentZombie:PathSuccess( t )
	local movement_lc = self.core.logic_controller[1]
	if movement_lc then
		movement_lc.precision_movement = nil
		t.path[#t.path] = nil
		movement_lc.path = t.path
	end
	self.has_requested_path = false
end

function AgentZombie:PathFailed()
	self.has_requested_path = false
	local target = self.target
	if target and IsValid(target) then
		local id = target:GetId()
		if id then
			if not self.blacklisted_targets[id] then
				self.blacklisted_targets[id] = Timer()
			end
		end
	end
	self:ClearTarget()
end

function AgentZombie:Remove()
	-- remove player los update network subscription
	if self.los_update then
		Network:Unsubscribe( self.los_update )
		self.los_update = nil
	end
end
