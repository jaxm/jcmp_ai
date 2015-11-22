class 'AgentCore'

function AgentCore:__init( args )
	-- Bare minimum intiialization here
	self.position = args.position
	self.angle = args.angle or Angle()
	self.debug = {}
	self.timer = Timer()
	self.time = 250
	self.vehicle = args.vehicle
	self.fov = AddTriangle( self.position, 10 )
	self.flagged_for_deletion = false
	local vehicle_id = nil

	if self.vehicle then
		vehicle_id = self.vehicle:GetId()
	end

	-- network object
	self.network_object = WorldNetworkObject.Create( self.position, 
		{
			class = 'NPC', -- the name of the class that will handle this WNO on client
			type = 'Actor', -- will be handled by the ActorManager on the client
			angle = self.angle,
			speed = args.speed or 0,
			model_id = args.model_id,
			health = args.health or 100,
			max_health = args.health or 100,
			goal = args.goal,
			in_vehicle = vehicle_id,
			name = args.name
	} )
	local id = self.network_object:GetId()

	-- stream
	self.cell = {}
	self.cell.x, self.cell.y = GetCellXYFromPosition( self.position )
	AddActorToCell( self, self.cell.x, self.cell.y )

	-- network
	self.sync_tick = 6
	self.net_tick = self.sync_tick

	-- logic
	self.logic_controller = {}

	-- identity
	self.faction = args.faction

	-- configure
	self:ConfigureNPC( args )

	-- enter object into lookup table
	AM.actors_id[id] = self
end

function AgentCore:Tick( frame_time )
	local network_object = self.network_object

	if not network_object or not IsValid( network_object ) then return end

	if self.dead then
		if self.dead_timer:GetSeconds() > 15 then
			self:Remove()
		end
		return
	end

	-- if this npc is flagged for deletion, don't run logic this frame
	if self.flagged_for_deletion then
		return
	end

	-- net_tick logic
	self:CalcNetTick()

	-- run defined logic controllers
	local lc = self.logic_controller

	-- logic controllers
	-- When the agent enters a vehicle, its onfoot logic controller will be
	-- replaced with logic that suits the vehicle type. The previous logic
	-- is destroyed during this time and needs to be recreated when the agent
	-- leaves the vehicle.
	-- lc[1] = MOVEMENT, IE: OnFoot, [Land/Sea/Heli/Plane]Driver
	-- lc[2] = ROLE LOGIC, IE: Guard, Driver, Patrol, Pursue, Gunner, Pedestrian
	-- lc[3] = Team Logic Controller, if this exists, [1] and [2] aren't run here

	if not lc[3] then
		
		local controller = lc[1]
		if controller then
			controller:Tick( self, frame_time )
		end

		local controller = lc[2]
		if controller then
			controller:Tick( self, frame_time )
		end
	end

	self.fov:SetPosition( self.position )
	self.fov:SetAngle( self.angle )
end

function AgentCore:ConfigureNPC( args )
	local network_object = self.network_object
	if not network_object or not IsValid( network_object ) then return end
	local goal = args.goal
	self.goal = goal
	if network_object:GetValue( 'goal' ) ~= goal then
		network_object:SetNetworkValue( 'goal', goal )
	end

	-- cleanup old logic
	for i=1,4 do
		local controller = self.logic_controller[i]
		if controller then
			if controller.Remove then
				controller:Remove()
			end
			self.logic_controller[i] = nil
		end
	end
	
	-- set new logic
	if goal == AiGoal.Wander then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controller[1] = movement
		-- wander logic
		local logic = AgentWander( self )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 250
	elseif goal == AiGoal.Panic then
		-- movement
		local movement = AgentOnFootPanic( self )
		self.logic_controller[1] = movement
		-- wander logic
		local logic = AgentPanic( self )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.Traffic then
		-- movement
		local movement = AgentVehicleDriver( self, args )
		self.logic_controller[1] = movement
		-- traffic logic
		local logic = AgentTraffic( self, args )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.TaxiDriver then
		-- movement
		local movement = AgentVehicleDriver( self, args )
		self.logic_controller[1] = movement
		-- traffic logic
		local logic = TaxiDriver( self, args )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.Guard then
		-- movement

		-- guard logic
		local logic = AgentGuard( self, args )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 500
	elseif goal == AiGoal.Pursue then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controller[1] = movement
		-- pursue logic
		local logic = AgentPursue( self, args )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.HeliGuard then
		-- movement
		local movement = AgentHeliPilot( self, args )
		self.logic_controller[1] = movement
		-- guard logic
		local logic = AgentGuard( self, args )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.Zombie then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controller[1] = movement
		-- zombie logic
		local logic = AgentZombie( self )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	elseif goal == AiGoal.RescueObjective then
		-- movement
		local movement = AgentOnFoot( self )
		self.logic_controller[1] = movement
		-- role logic
		local logic = AgentRescue( self )
		self.logic_controller[2] = logic
		-- logic tick rate
		self.time = 100
	end
end

function AgentCore:CalcNetTick()
	self.net_tick = self.net_tick + 1
	if self.net_tick == self.sync_tick + 1 then
		self.net_tick = 1
	end
end

function AgentCore:SetStreamDistance( n )
	self.network_object:SetStreamDistance( n )
end
function AgentCore:GetPosition()
	local network_object = self.network_object
	if network_object and IsValid( network_object ) then
		return network_object:GetPosition()
	end

	return self.position
end

function AgentCore:GetHealth()
	local network_object = self.network_object
	local health = 0
	if network_object and IsValid( network_object ) then
		health = network_object:GetValue('health') or 0
	end
	return health
end

function AgentCore:GetId()
	local network_object = self.network_object
	if network_object and IsValid( network_object ) then
		return network_object:GetId()
	end
end

function AgentCore:Damage( attacker, weapon )
	if self.network_object and IsValid( self.network_object ) then

		if self.immune then return end

		local is_npc = ( attacker.__type ~= 'Player' )

		local health = self.network_object:GetValue( 'health' )

		if health <= 0 then return end

		local damage = weapon.damage

		-- shotgun modifier
		if weapon.is_shotgun then
			local distance = attacker:GetPosition():Distance( self:GetPosition() )
			local ratio = 1 - distance / 60
			local base_damage = Copy( weapon.damage )
			damage = ceil(base_damage * ( 8*ratio ))
		end

		if damage and damage > 0 then
			health = health - damage
			self.network_object:SetNetworkValue( 'health', health )

			if health <= 0 then

				-- player heat level

				if attacker.__type == 'Player' then
					if self.faction == Faction.Citizen or self.faction == Faction.PanauMilitary then
						H:IncreasePlayerHeatLevel( attacker, 100 )
					end
				end

				self:Kill( attacker )
			else
				local logic_lc = self.logic_controller[2]
				H:IncreasePlayerHeatLevel( attacker, damage*.5 )
				if logic_lc then
					if logic_lc.HurtEvent then
						logic_lc:HurtEvent( attacker, damage )
					end
				end
			end
		end
	end
end

function AgentCore:Hurt( attacker, damage )
	-- use this function to deal damage to the agent without using the weapon system
	if self.immune then return end
	local network_object = self.network_object
	if not network_object or not IsValid( network_object ) then return end
	local health = network_object:GetValue( 'health' )

	if health <= 0 then return end
	local new_health = health - damage
	network_object:SetNetworkValue( 'health', new_health )

	if new_health <= 0 then
		self:Kill( attacker )
	end
end

function AgentCore:Kill( attacker )
	local movement_lc = self.logic_controller[1]
	if movement_lc then
		movement_lc.movement.speed = 0
	end

	self.dead_timer = Timer()
	self.dead = true
	local network_object = self.network_object
	if network_object and IsValid(network_object) then
		local health = network_object:GetValue('health')

		if health > 0 then
			network_object:SetNetworkValue( 'health', 0 )
		end
	end
end

function AgentCore:HitByVehicle( t )
	local impulse = t.impulse
	local health_damage = impulse / 10
	
	local hit_angle = t.angle

	local current_velocity = self.velocity or Vector3()

	local new_velocity = current_velocity + (hit_angle * (Vector3.Forward * impulse))

	local movement_lc = self.logic_controller[1]

	if movement_lc then
		movement_lc.collisionVelocity = new_velocity
		movement_lc.collisionMode = true
	end
end

function AgentCore:VehicleCollision( t )
	local impulse = t.impulse
	local health_damage = impulse / 10

	-- vehicle health
	local vehicle = self.vehicle
	if vehicle and IsValid(vehicle) then
		vehicle:SetHealth( vehicle:GetHealth() - health_damage )
	end
	
	-- angle / velocity calculation
	local hit_angle = t.angle
	local current_velocity = self.velocity or Vector3()
	local new_velocity = current_velocity + (hit_angle * (Vector3.Forward * impulse))

	local movement_lc = self.logic_controller[1]

	if movement_lc then
		movement_lc.collisionVelocity = new_velocity
		movement_lc.collisionMode = true
	end
end

function AgentCore:CalculateCell( position )

	if not position then
		position = self.network_object:GetPosition()
	end

	local current_x, current_y = self.cell.x, self.cell.y
	local cell_x, cell_y = GetCellXYFromPosition( position )

	if cell_x ~= current_x or cell_y ~= current_y then
		-- move from one cell to the other
		RemoveActorFromCell( self, current_x, current_y )
		AddActorToCell( self, cell_x, cell_y )
		
		-- update saved cell info
		self.cell.x = cell_x
		self.cell.y = cell_y

		-- traffic
		if self.goal == AiGoal.Traffic then
			local new_cells_players = GetConnectedCellsInfo( cell_x, cell_y )

			if new_cells_players == 0 and not IsPositionInCellPlayersFoV( position, GetCell( cell_x, cell_y ) ) then
				-- new cell doesn't contain players or isn't connected to a cell with players in it
				-- remove traffic from system
				self:Remove()
			else
				-- new cell contains players or is connected to a cell with players in it
				-- update traffic cell
				local spawnset = self.spawnset
				RemoveVehicleTrafficFromCell( spawnset, current_x, current_y )
				AddVehicleTrafficToCell( spawnset, cell_x, cell_y )
				spawnset.cell.x = cell_x
				spawnset.cell.y = cell_y

				local cell = GetCell( cell_x, cell_y )

				if #cell.vehicle_traffic > CellVehicleTrafficLimit then
					if not self.spawnset.marked_for_removal then
						self.spawnset.marked_for_removal = true
						table.insert( DelayedTrafficRemove, self )
					end
				end
			end
		end

		-- update vehicle if driving
		local vehicle = self.vehicle
		if vehicle and IsValid(vehicle) then
			RemoveVehicleFromCell( vehicle, current_x, current_y )
			AddVehicleToCell( vehicle, cell_x, cell_y )
		end

	end
end

function AgentCore:GiveWeapon( slot, weapon )
	if not self.inventory then
		self.inventory = {}
	end
	self.inventory[slot] = weapon
	self.equipped_weapon = weapon
	self.network_object:SetNetworkValue( 'equipped_weapon', weapon.id )
end

function AgentCore:EquipWeaponSlot( slot )
	self.equipped_weapon = self.inventory[slot]
	if self.equipped_weapon then
		self.network_object:SetNetworkValue( 'equipped_weapon', self.equipped_weapon.id )
	else
		self.network_object:SetNetworkValue( 'equipped_weapon', nil )
	end
end

function AgentCore:GetEquippedWeapon( ... )
	return self.equipped_weapon
end

function AgentCore:Remove()
	local network_object = self.network_object

	if network_object and IsValid( network_object ) then
		for i=1,4 do
			if self.logic_controller[i] then
				if self.logic_controller[i].Remove then
					self.logic_controller[i]:Remove()
				end
				self.logic_controller[i] = nil
			end
		end
		if AM then
			AM.actors_id[network_object:GetId()] = nil
			AM:RemoveNPC( self )
		end
		network_object:Remove()

		if self.spawnset then
			self.spawnset:Remove()
		end

		RemoveActorFromCell( self, self.cell.x, self.cell.y )

		self = nil
		return true
	end
	return false
end