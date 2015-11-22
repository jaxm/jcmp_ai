class 'AgentPanic'

function AgentPanic:__init( core )
	self.core = core
	self.avoid = {}

	-- pathfinding
	self.side = self.core.street_side or ceil(random(2))
	self.path = {}
	self.has_requested_path = false
	self.path_failed_count = 0
end

function AgentPanic:Tick( core, frame_time )
	-- get movement lc
	local movement_lc = core.logic_controller[1]

	if not movement_lc then return end
	-- currently following a path?
	if movement_lc.path_destination or #movement_lc.path > 1 then return end

	local path = self.path

	if #path == 0 then
		if not self.has_requested_path then
			if #movement_lc.path == 1 then
				self:RequestNewPath( movement_lc.path[1].position )
			else
				self:RequestNewPath( movement_lc.position )
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

function AgentPanic:RequestNewPath( start_position )
	self.has_requested_path = true
	local avoid_target = nil
	if #self.avoid > 0 then
		local i = 1
		local timer = Timer()
		while i<= #self.avoid do

			if timer:GetSeconds() > 1 then
				print('AgentPanic:RequestNewPath timeout')
				break
			end

			local attacker = self.avoid[i]
			if attacker and IsValid(attacker) then
				local distance = self.core.position:Distance( attacker:GetPosition() )
				if distance < 300 then
					avoid_target = attacker
					break
				else
					table.remove( self.avoid, i )
				end
			else
				table.remove(self.avoid, i)
			end
		end
	end

	if avoid_target then
		local avoid_dir = start_position - avoid_target:GetPosition()
		-- GeneratePath( start_position, start_position + ( avoid_dir * 50 ), self, 1, PathPriority.Low )
		local movement_lc = self.core.logic_controller[1]
		movement_lc:RequestPathToDestination( start_position + ( avoid_dir * 50 ) )
		self.has_requested_path = false
	else
		-- calm down / return to wander logic
		self.core:ConfigureNPC( { goal = AiGoal.Wander } )
		self.has_requested_path = false
	end
end

function AgentPanic:HurtEvent( attacker )
	if not attacker or not IsValid( attacker ) then return end

	-- don't add duplicates
	local id = attacker:GetId()
	for i=1,#self.avoid do
		local avoid_target = self.avoid[i]

		if avoid_target:GetId() == id then
			return
		end
	end

	table.insert( self.avoid, attacker )
end

function AgentPanic:PathSuccess( t )
	self.path = t.path
	self.has_requested_path = false
	self.path_failed_count = 0
end

function AgentPanic:PathFailed()
	self.has_requested_path = false
	self.path_failed_count = self.path_failed_count + 1

	if self.path_failed_count > 3 then
		-- destroy ped
		self.core:Remove()
	end
end