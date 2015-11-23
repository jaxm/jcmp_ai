class 'HeatEvent'

function HeatEvent:__init( t )
	self.current_level = 1
	self.agents = {}
	self.target = t.target
end

function HeatEvent:Tick()
	local target = self.target
	if not target or not IsValid(target) then return end

	local agents = self.agents

	if self.current_level == 0 then
		if #agents > 0 then
			self:Remove()
		end
		return 
	end

	if #agents < (self.current_level * 5) then
		-- spawn more agents

		local position = target:GetPosition()
		local cell = GetCellFromPosition( position )

		-- don't want to spawn heat in the player cell, but instead the cells surrounding the player
		local cell_table = GetNearbyCells( cell.x, cell.y )
		if cell_table and #cell_table > 0 then
			local random_cell = table.randomvalue( cell_table )

			if random_cell and random_cell ~= cell then
				-- find node within random_cell to spawn heat agent at
				local nodes = random_cell.nodes[1]
				if nodes and #nodes > 0 then
					local random_node = table.randomvalue( nodes )

					if random_node and random_node.vehicle_node then
						-- spawn agent
						local side = ceil(random(2))
						local agent = nil
						if self.current_level == 1 then
							-- police officer
							agent = PoliceGuard( {
								position = GetSideWalkPosition( random_node, nil, side ),
								angle = Angle(),
								faction = Faction.PanauMilitary,
								goal = AiGoal.Pursue,
								target = target
							} )
						elseif self.current_level == 2 then
							agent = HeatMilitaryBasic( {
								position = GetSideWalkPosition( random_node, nil, side ),
								angle = Angle(),
								faction = Faction.PanauMilitary,
								goal = AiGoal.Pursue,
								target = target
							} )
						elseif self.current_level == 3 then
							agent = HeatMilitaryMedium( {
								position = GetSideWalkPosition( random_node, nil, side ),
								angle = Angle(),
								faction = Faction.PanauMilitary,
								goal = AiGoal.Pursue,
								target = target
							} )
						elseif self.current_level == 4 then
							agent = HeatMilitaryHeavy( {
								position = GetSideWalkPosition( random_node, nil, side ),
								angle = Angle(),
								faction = Faction.PanauMilitary,
								goal = AiGoal.Pursue,
								target = target
							} )
						elseif self.current_level == 5 then
							agent = HeatMilitaryFinal( {
								position = GetSideWalkPosition( random_node, nil, side ),
								angle = Angle(),
								faction = Faction.PanauMilitary,
								goal = AiGoal.Pursue,
								target = target
							} )
						end
						if agent then
							agent.event = self
							local npc = agent.npc
							if npc and IsValid(npc) then
								local logic = npc.logic_controller[2]
								if logic then
									logic.target = target
								end
							end
							table.insert( self.agents, agent )
						end
					end
				end
			end
		end
	end

	-- evading heat
	for i=1,#self.agents do
		local agent = self.agents[i]

		if agent then
			local npc = agent.npc
			if npc then
				local logic = npc.logic_controller[2]
				if logic then
					local has_los = logic:InLoS( target )
					if has_los then
						-- spotted, kill evade sequence
						if self.evade_timer then
							self.evade_timer = nil
						end
						return
					end
				end
			end
		end
	end

	-- code will only get here if none of the agents currently have the player spotted
	if not self.evade_timer then
		self.evade_timer = Timer()
	else
		if self.evade_timer:GetSeconds() > (10 * self.current_level) then
			-- player has evaded the heat
			H:ResetPlayerHeat( target )
			self.current_level = 0
			self.evade_timer = nil
		end
	end
end

function HeatEvent:AddAgent( agent )
	table.insert( self.agents, agent )
end

function HeatEvent:RemoveAgent( target_agent )
	if self.removing then return end
	if target_agent then
		local i = 1
		while i <= #self.agents do
			local agent = self.agents[i]
			if agent then
				if agent == target_agent then
					table.remove( self.agents, i )
					return
				else
					i = i + 1
				end
			else
				table.remove( self.agents, i )
			end
		end
	end
end

function HeatEvent:Remove()
	self.removing = true
	local t = self.agents
	local timer = Timer()
	local i = 1
	while i<= #self.agents do

		-- // Debugging
		if timer:GetSeconds() > 1 then
			print('HeatEvent:Remove timeout')
			break
		end
		-------

		local agent = self.agents[i]
		if agent then
			local npc = agent.npc
			if npc then
				local logic = npc.logic_controller[2]
				if logic then
					local target = logic.target
					if target and IsValid(target) then
						if target.__type == 'Player' then
							if self.target and IsValid( self.target ) and self.target == target then
								-- target is the current target, remove
								agent:Remove()
								table.remove( self.agents, i )
							else
								-- agent is currently engaging another player
								-- move this agent to the Heat event for target player
								local id = target:GetId()
								local event = H:GetPlayerHeatEvent( target )
								if not event then
									-- create heat event for player
									event = H:CreatePlayerHeatEvent( target )
								end
								-- add agent to heat event
								event:AddAgent( agent )
								table.remove( self.agents, i )
							end
						else
							-- target isn't a player, remove
							agent:Remove()
							table.remove( self.agents, i )
						end
					else
						-- no target, remove
						agent:Remove()
						table.remove( self.agents, i )
					end
				else
					-- logic nil, remove
					agent:Remove()
					table.remove( self.agents, i )
				end
			else
				-- npc nil or invalid
				agent:Remove()
				table.remove( self.agents, i )
			end
		else
			-- agent isn't valid, remove
			table.remove(self.agents, i)
		end
	end
	self.agents = {}
	self.removing = nil
end