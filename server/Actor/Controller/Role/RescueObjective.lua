class 'AgentRescue'

function AgentRescue:__init( core )
	self.core = core
	self.network_id = core.network_object:GetId()

	-- network events
	self.follow_event = Network:Subscribe( 'RescueFollowMe'..tostring(self.network_id), self, self.FollowTargetRequest )
	self.stop_event = Network:Subscribe( 'RescueStop'..tostring(self.network_id), self, self.StopTargetRequest )

	-- pathfinding
	self.has_requested_path = false

	self.following = nil
	self.target_last_position = nil
end

function AgentRescue:Tick( core, frame_time )
	-- get movement lc
	local movement_lc = core.logic_controller[1]

	if not movement_lc then return end
	
	local target = self.following
	-- are we currently following anyone?
	if not target then return end

	if not IsValid( target ) then
		-- the target we were following became invalid
		self:SetFollowTarget( nil )
		return
	end

	local position = target:GetPosition()
	if self.target_last_position then
		local distance = self.target_last_position:Distance( position )
		if distance > 2 then
			-- update path
			self:RequestNewPath( movement_lc.position )
			self.target_last_position = position
		end
	end

	local distance = position:Distance( movement_lc.position )

	if distance > 1 then
		if distance < 4 then
			movement_lc.path_destination = position
		else
			local speed = distance
			if speed > 5 then
				speed = 5
			end
			if movement_lc.path_destination or #movement_lc.path > 1 then
				local move_speed = movement_lc.movement.speed
				if move_speed < speed then
					movement_lc.movement.speed = move_speed + 1
					if move_speed > speed then
						movement_lc.movement.speed = speed
					end
				end
				return 
			end

			local path = movement_lc.path
			if #path == 0 and not movement_lc.has_requested_path then
				if distance <= 5 then
					movement_lc.path_destination = position
				else
					self:RequestNewPath( movement_lc.position )
				end
			end
		end
	end
end

function AgentRescue:HurtEvent( attacker )
	if not attacker or not IsValid( attacker ) then return end

end

function AgentRescue:RequestNewPath( start_position )
	self.has_requested_path = true
	GeneratePath( start_position, self.following:GetPosition(), self, 2, PathPriority.Medium )
end

function AgentRescue:PathSuccess( t )
	self.has_requested_path = false
	local movement_lc = self.core.logic_controller[1]

	if movement_lc then
		t.path[#t.path] = nil
		movement_lc.path = t.path
	end
end

function AgentRescue:PathFailed()
	self.has_requested_path = false
	-- can't path to our target, clear target
	self:SetFollowTarget( nil )
end

function AgentRescue:SetFollowTarget( target )
	self.following = target
	if target ~= nil then
		self.core.network_object:SetNetworkValue( 'currently_following', target:GetId() )
	else
		self.core.network_object:SetNetworkValue( 'currently_following', nil )
	end
end

function AgentRescue:FollowTargetRequest( e, sender )
	-- self.stop_follow allows the script to stop players from getting this NPC to follow them
	if self.stop_follow then return end
	if not sender or not IsValid(sender) then return end
	local target = self.following
	if not target or not IsValid( target ) then
		self:SetFollowTarget( sender )
	end
end

function AgentRescue:StopTargetRequest( e, sender )
	if not sender or not IsValid(sender) then return end
	local target = self.following
	if target and IsValid( target ) then
		-- target is valid
		if target == sender then
			-- sender is the current follow target, stop following
			self:SetFollowTarget( nil )
		end
	else
		-- player is nil or invalid
		self:SetFollowTarget( nil )
	end
end

function AgentRescue:ForceStopFollow()
	-- allows script to force this NPC to stop following its current target
	self:SetFollowTarget( nil )
end

function AgentRescue:DisableFollow()
	-- self.stop_follow allows the script to stop players from getting this NPC to follow them
	self.stop_follow = true
end

function AgentRescue:Remove()

	Events:Fire( 'ObjectiveLost', self.network_id )

	if self.follow_event then
		Network:Unsubscribe( self.follow_event )
		self.follow_event = nil
	end
	if self.stop_event then
		Network:Unsubscribe( self.stop_event )
		self.stop_event = nil
	end
end