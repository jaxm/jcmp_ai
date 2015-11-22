class 'AgentOnFoot'

function AgentOnFoot:__init( core )
	-- initialize
	self.core = core
	self.position = core.position
	self.angle = core.angle

	-- pathfinding
	self.path = {}
	self.path_destination = nil
	self.requested_destination = nil
	self.has_requested_path = false
	self.current_node = nil

	-- movement
	self.movement = {
		speed = 0,
		max_speed = 5,
		max_turn_rate = 2
	}
end

function AgentOnFoot:Tick( core, frame_time )
	
	local position = self.position

	-- request a path, calculate distance from destination etc
	self:PathLogic( position )
	local path_destination = self.path_destination

	if not path_destination then
		-- no where to go, kill movement speed
		if self.movement.speed > 0 then
			self.movement.speed = 0
		end

		if self.collisionMode then
			self:MovementStep( position, self.angle, 0, frame_time )
		end

		return
	end

	-- we have a destination, move there!

	local move_dir = Angle.NormalisedDir( path_destination, position )
	local move_angle = Angle.FromVectors( Vector3.Forward, move_dir )
	-- no rolling about!
	move_angle.roll = 0
	-- move_angle.pitch = 0

	-- increase speed, // rewrite this into proper speed handler
	if self.movement.speed < 1 then
		self.movement.speed = 1
	end

	self:MovementStep( position, move_angle, self.movement.speed, frame_time )
end

function AgentOnFoot:MovementStep( position, angle, speed, frame_time )
	-- governs movement through 3d space for our agent

	local new_position = nil

	if self.collisionMode then
		local collisionVelocity = self.collisionVelocity

		if collisionVelocity:Length() > .1 then
			new_position = position + collisionVelocity
			self.collisionVelocity = self.collisionVelocity * .75
			self.movement.speed = 1

			self.core.network_object:SetNetworkValue( 'ragdollforce', collisionVelocity )

			if (new_position.y - position.y) > 1 then
				new_position.y = new_position.y - .25
			end

			-- force network updates for collision
			self.core.net_tick = self.core.sync_tick
			-- change logic tick rate tempoarily
			if self.core.time > 100 then
				-- store current tick rate
				self.core.time_backup = self.core.time
				-- lower logic tick rate for more frequent updates
				self.core.time = 100
			end
		else
			self.collisionMode = false
			-- disable ragdoll mode on the client
			self.core.network_object:SetNetworkValue( 'ragdollforce', Vector3() )
			if self.core.time_backup then
				self.core.time = self.core.time_backup
				self.core.time_backup = nil
			end
			new_position = position + ( ( angle * Vector3.Forward ) * (speed*frame_time) )
		end
	else
		local velocity = ( ( angle * Vector3.Forward ) * (speed*frame_time) )
		self.velocity = velocity
		new_position = position + velocity

	end

	if not new_position or IsNaN(new_position) then return end

	-- update stored position
	self.position = new_position
	self.core.position = new_position

	if self.angle ~= angle then
		self.angle = angle
		self.core.angle = angle
	end

	-- is it a network tick?

	if self.core.net_tick == self.core.sync_tick then
		-- logic runs 3 times for every network update by default
		local network_object = self.core.network_object
		-- sync position
		if network_object:GetPosition() ~= new_position then
			network_object:SetPosition( new_position )
		end
		-- sync speed
		if network_object:GetValue( 'speed' ) ~= speed then
			network_object:SetNetworkValue( 'speed', speed )
		end
		-- sync angle
		if network_object:GetValue( 'angle' ) ~= angle then
			network_object:SetNetworkValue( 'angle', angle )
		end

		-- update cell info, doesn't have to be done so often
		self.core:CalculateCell( new_position )
	end
	-- update core position
	self.core.position = new_position
end

function AgentOnFoot:PathLogic( position )
	-- work out where we're going
	local path = self.path

	-- do we need to change where we're moving?
	if self.requested_destination then
		self:RequestPathToDestination( self.requested_destination )
		return
	end

	-- do we need to move?

	if not self.path_destination then
		-- get next path position
		if #path > 0 then
			self.path_destination = path[#path].position
		end
	end

	-- if self.path_destination then

	-- 	-- is our path blocked?

	-- 	if self.current_node then
	-- 		-- we have a node to check against
	-- 		if self.current_node.blocked then
	-- 			self.path = {}
	-- 			self.path_destination = nil
	-- 			self.current_node = nil
	-- 			return
	-- 		end
	-- 	end

		-- have we arrived at our destination?
		local distance = Distance2D( position, self.path_destination )

		local check = self.precision_movement or self.movement.speed*.5

		-- if distance <= (.25+(self.movement.speed*.5)) then
		-- if distance <= 1 then
		if distance <= check then
			-- we've arrived!
			table.remove( self.path, #path )

			if #self.path > 0 then
				-- get next node along path
				-- check if next node is blocked
				local position = self.path[#self.path].position
				-- local x, y, cell = GetMeshCellFromPosition( position )
				-- if IsCellLoaded( x, y ) then
				-- 	local node = GetMeshNodeById( self.path[#self.path].id, cell )
				-- 	self.current_node = node
				-- 	if node and node.blocked then
				-- 		self.path = {}
				-- 		self.path_destination = nil
				-- 		return
				-- 	end
				-- end

				self.path_destination = position
			else
				self.path_destination = nil

				-- kill movement speed

				if self.movement.speed > 0 then
					self.movement.speed = 0
					self.core.network_object:SetNetworkValue( 'speed', 0 )
				end
			end
		end
	-- end
end

function AgentOnFoot:RequestPathToDestination( position, priority )
	-- if we've already requested a path, wait for the pathfinder
	-- to return a successful path or a failed path notifier
	if self.debug then
		print('RequestPathToDestination')
	end
	if not priority then
		priority = PathPriority.Low
	end
	if not self.has_requested_path then
		self.has_requested_path = true
		-- send request to the pathfinder
		GeneratePath( self.position, position, self, 2, priority )

		-- clear destination request
		self.requested_destination = nil
	end
end

function AgentOnFoot:PathSuccess( t )
	local network_object = self.core.network_object

	if network_object and IsValid( network_object ) then

		self.path = t.path

		if self.debug then
			print('PathSuccess')
		end

		-- if self.zombie then

		-- 	self.core.network_object:SetNetworkValue( 'path', t.path )
		-- end

		-- clear bool so new path can be requested
		self.has_requested_path = false
	end
end

function AgentOnFoot:PathFailed()
	-- pathfinder failed to find a suitable path
	-- clear bool so new path can be requested
	if self.debug then
		print('PathFailed')
	end
	self.has_requested_path = false
end