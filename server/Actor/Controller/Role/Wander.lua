class 'AgentWander'

function AgentWander:__init( core )
	self.core = core

	-- pathfinding
	self.side = self.core.street_side or ceil(random(2))
	self.path = {}
	self.has_requested_path = false
	self.path_failed_count = 0
end

function AgentWander:Tick( core, frame_time )
	-- get movement lc
	local movement_lc = core.logic_controller[1]

	if not movement_lc then return end
	-- currently following a path?
	if movement_lc.path_destination or #movement_lc.path > 1 then return end

	local path = self.path

	if #path == 0 then
		-- random chance that the ped will just 'chill for a bit'
		-- aka save a little server performance by not having _every_
		-- pedestrian constantly walking / requesting paths
		local rand = random(4)
		if rand > 1.5 then

			if not self.wait_timer then
				self.wait_timer = Timer()
			end
		end

		local is_waiting = self.wait_timer

		if not is_waiting or is_waiting and is_waiting:GetSeconds() > 5 then
			if not self.has_requested_path then
				if #movement_lc.path == 1 then
					self:RequestNewPath( movement_lc.path[1].position )
				else
					self:RequestNewPath( movement_lc.position )
				end
			end
			-- cleanup wait timer
			if is_waiting then
				self.wait_timer = nil
			end
		end
	else
		local node = GetNodeById( path[#path].id, 1 )
		local position = GetSideWalkPosition( node, path[#path].yaw, self.side )
		-- make path request
		movement_lc:RequestPathToDestination( position )
		table.remove( self.path, #path )
	end
end

function AgentWander:HurtEvent( attacker )
	if not attacker or not IsValid( attacker ) then return end
	self.core:ConfigureNPC( { goal = AiGoal.Panic } )

	local lc = self.core.logic_controller[2]
	if lc then
		table.insert( lc.avoid, attacker )
	end
end

function AgentWander:RequestNewPath( start_position )
	self.has_requested_path = true
	-- no path, lets get one!
	local cell = GetCellFromPosition( start_position )
	if cell then
		local cell_nodes = cell.nodes[1]
		if cell_nodes then
			local random_node = cell_nodes[random( 1, #cell_nodes )]
			GeneratePath( start_position, random_node.position, self, 1, PathPriority.Low )
		end
	end
end

function AgentWander:PathSuccess( t )
	self.path = t.path
	self.has_requested_path = false
	self.path_failed_count = 0
end

function AgentWander:PathFailed()
	self.has_requested_path = false
	self.path_failed_count = self.path_failed_count + 1

	if self.path_failed_count > 3 then
		-- destroy ped
		self.core:Remove()
	end
end