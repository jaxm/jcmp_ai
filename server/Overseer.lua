class 'Overseer'

function Overseer:__init( ... )
	-- The Overseer is a helper class, an entity makes a request to the Overseer to get information
	-- from a clients game, line of sight is the only request at the moment.
	-- The Overseer takes that request, finds a player that's in the area relevant to the request
	-- sends the request off to the player then hands the information back to the entity that 
	-- requested it when its received.
	self.recent_requests = {}
	self.task_queue = {}
	Network:Subscribe( 'PlayerCalculationReceive', self, self.PlayerCalculationReceive )

	self.task_id = 0

	self.callbacks = {}
end

function Overseer:Tick()
	if #self.task_queue == 0 then return end

	-- task_queue is a backlog of requests, they're automatically killed if not handed to a player
	-- within 2 seconds of the request being made.

	local i = 1
	while i <= #self.task_queue do
		local task = self.task_queue[i]
		if task.timer:GetSeconds() > 2 then
			-- remove task, request has likely become irrelevant
			table.remove( self.task_queue, i )
		else
			if task.entity and IsValid( task.entity ) and task.entity.network_object and IsValid(task.entity.network_object) then
				local found_slave = self:RequestLoSCalculation( task.cell, task.a, task.b, task.entity, task.taskId, true )

				if found_slave then
					-- task was issued successfully
					table.remove( self.task_queue, i )
				else
					i = i + 1
				end
			else
				-- entity which made the request no longer valid
				table.remove( self.task_queue, i )
			end
		end
	end
end

function Overseer:RequestLoSCalculation( cell, a, b, entity, taskId, tickTask )
	local player_table = {}

	local found_slave = false
	if not taskId then
		taskId = self:GetTaskId()
	end

	if entity and IsValid(entity) then
		for player in entity.network_object:GetStreamedPlayers() do
			if player and IsValid(Player) then
				local pId = player:GetId()
				if not self.recent_requests[pId] then
					-- this player hasn't been tasked recently
					self.recent_requests[pId] = Timer()
					self:RequestPlayerCalculation( player, a, b, entity, taskId )
					found_slave = true
					break
				else
					if self.recent_requests[pId]:GetMilliseconds() > 200 then
						self.recent_requests[pId]:Restart()
						self:RequestPlayerCalculation( player, a, b, entity, taskId )
						found_slave = true
						break
					end
				end
			end
		end
	end
	-- if the task is coming from the tick event, we don't want to add it to the
	-- task_queue again.

	if tickTask then
		return found_slave, taskId
	end

	-- code will only go past this point if the request came directly from an entity

	if not found_slave then
		local task = {
			cell = cell,
			a = a,
			b = b,
			entity = entity,
			timer = Timer(),
			taskId = taskId
		}
		table.insert( self.task_queue, task )
	end
	return found_slave, taskId
end

function Overseer:RequestPlayerCalculation( player, a, b, entity, taskId )
	local entityId = entity.network_object:GetId()
	local t = {
		from = a,
		to = b,
		entityId = entityId,
		taskId = taskId
	}

	Network:Send( player, 'RequestPlayerCalculation', t )

	t.entity = entity
	self.callbacks[entityId] = t
end

function Overseer:PlayerCalculationReceive( t, sender )
	local entityId = t.entityId

	local info = self.callbacks[entityId]
	if info then
		local entity = info.entity

		info.result = t.result

		-- hand the info back to the entity

		if entity and IsValid(entity) then
			entity:LoSRequest( info )
		end
	end

	-- cleanup

	self.callbacks[entityId] = nil
end

function Overseer:GetTaskId( ... )
	if self.task_id > 1000 then
		self.task_id = 0
	end
	self.task_id = self.task_id + 1
	return self.task_id
end

OS = Overseer()