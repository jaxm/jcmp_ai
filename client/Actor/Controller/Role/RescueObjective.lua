class 'AgentRescue'

function AgentRescue:__init( core )
	self.core = core
	self.network_id = self.core.network_object:GetId()
	self.currently_following = nil
	self.input_event = nil
	self.input_antispam = Timer()
	self.following_me = false
	self.in_range = false
	self.follow_string = '[E] - Follow Me'
	self.stop_follow_string = '[E] - Stop Following'
	self.following_other_string = 'Following Player'

	local actor = self.core.actor
	if actor and IsValid(actor) then
		actor:DisableAutoAim()
	else
		self.delayed_autoaim = true
	end
end

function AgentRescue:Update( e )
	local key = e.key
	local value = e.value
	if key == 'currently_following' then
		self.currently_following = value
		if value then
			local id = LocalPlayer:GetId()
			if id == self.currently_following then
				self.following_me = true
			else
				self.following_me = false

				local player = Player.GetById(value)
				if player and IsValid(player, false) then
					local name = player:GetName()
					self.following_other_string = 'Following '..tostring(name)
				else
					self.following_other_string = 'Following Player'
				end
			end
		else
			self.following_me = false
		end
	end
end

function AgentRescue:Tick()
	local actor = self.core.actor
	local distance = actor:GetPosition():Distance( LocalPlayer:GetPosition() )

	if self.delayed_autoaim then
		actor:DisableAutoAim()
		self.delayed_autoaim = nil
	end

	if distance < 6 then
		local target = LocalPlayer:GetAimTarget().entity
		if target and target.__type == 'ClientActor' then
			if target == actor then
				if not self.input_event then
					self.in_range = true
					self.input_event = Events:Subscribe( 'LocalPlayerInput', self, self.Input )
				end
			else
				-- not aiming at this actor
				self:ClearInputEvent()
			end
		else
			-- no aim target or not aiming at an actor
			self:ClearInputEvent()
		end
	else
		-- too far away to interact
		self:ClearInputEvent()
	end
end

function AgentRescue:Input( e )
	local input = e.input

	if input == Action.UseItem then
		local t = self.input_antispam
		if t:GetMilliseconds() > 125 then
			t:Restart()

			if not self.currently_following then
				-- not currently following anyone
				Network:Send( 'RescueFollowMe'..tostring(self.network_id) )
			else
				-- following a player
				if self.following_me then
					-- following the LocalPlayer
					Network:Send( 'RescueStop'..tostring(self.network_id) )
				end
			end
		end
	end
end

function AgentRescue:Render( wts )
	local actor = self.core.actor
	if not actor then return end

	local wts, on_screen = Render:WorldToScreen( actor:GetPosition() + Vector3(0, 1, 0) )
	if on_screen then
		if self.in_range then
			if self.following_me then
				-- following LocalPlayer
				self:DrawString( wts, self.stop_follow_string, Color.White )
			else
				if self.currently_following then
					-- following another player
					self:DrawString( wts, self.following_other_string, Colour.LightBlue )
				else
					-- not following anyone
					self:DrawString( wts, self.follow_string, Color.White )
				end
			end
		end
	end
end

function AgentRescue:DrawString( wts, string, colour )
	Render:DrawText( wts+Vector2.One, string, Color.Black )
	Render:DrawText( wts, string, colour )
end

function AgentRescue:ClearInputEvent()
	self.in_range = false
	if self.input_event then
		Events:Unsubscribe( self.input_event )
		self.input_event = nil
	end
end

function AgentRescue:Remove()
	self:ClearInputEvent()
end