class 'AgentGuard'

function AgentGuard:__init( core )
	self.core = core
	self.firing = false
	self.aim_timer = Timer()
	self.notice_delay = Timer()
	self.last_update_time = 500
	-- vehicles
	self.delayed_enter = false
	self.secondary_delay = Timer()

	-- player LoS
	self.los_timer = Timer()
	self.has_los = false
	self.network_id = self.core.network_object:GetId()

	-- init selected weapon
	local network_object = self.core.network_object
	if network_object and IsValid( network_object ) then
		local weapon = network_object:GetValue('equipped_weapon')
		if weapon then
			if weapon == 14 then
				-- sniper
				if not self.added_to_grender then
					self.added_to_grender = true
					table.insert( AM.actors_grender, self )
				end
			end
			self:EquipWeapon( weapon )
		end
	end

	-- init enter vehicle if required
	local vehicle_id = core.network_object:GetValue( 'in_vehicle' )
	if vehicle_id then
		self:EnterVehicle( vehicle_id )
	end
end

function AgentGuard:Update( e )
	local key = e.key
	local value = e.value

	if key == 'equipped_weapon' then
		self:EquipWeapon( value )
		if value == 14 then
			-- sniper
			if not self.added_to_grender then
				self.added_to_grender = true
				table.insert( AM.actors_grender, self )
			end
		end
	elseif key == 'aim_position' then
		self:SetAimPosition( value )
		self.last_update_time = self.aim_timer:GetMilliseconds()
		self.aim_timer:Restart()
	elseif key == 'fire' then
		self.firing = value
		self.notice_delay:Restart()
	end
end

function AgentGuard:Tick()
	if self.delayed_enter then
		self:EnterVehicle( self.core.network_object:GetValue( 'in_vehicle' ) )
	elseif self.delayed_equip then
		self:EquipWeapon( self.delayed_equip )
	elseif self.delayed_aim then
		self:SetAimPosition( self.delayed_aim )
	end
	if self.aim_timer:GetMilliseconds() < 1000 then
		local actor = self.core.actor
		if not actor:GetVehicle() then
			actor:SetUpperBodyState( AnimationState.UbSAiming )
		end
	end
	if self.firing then
		local actor = self.core.actor
		if not actor:GetVehicle() then

			-- check weapon ammo
			local weapon = actor:GetEquippedWeapon()

			if weapon and weapon.ammo_clip == 0 then
				if weapon.ammo_reserve > 0 then
					-- can reload
					actor:SetUpperBodyState( AnimationState.UbSReloading )
					actor:SetInput( Action.Reload, 1 )	
				end
			else

				if weapon then
					-- weapon_info
					local weapon_info = WI:GetWeaponInfo( weapon.id )

					if weapon_info then
						if weapon_info.firemode == 0 then
							-- weapons with firemode 0 need to unset the fire input as they are 
							-- 'click to fire' weapons
							if self.last_frame_fire then
								actor:SetInput( Action.FireRight, 0 )
								if self.fire_timer and self.fire_timer:GetMilliseconds() >= weapon_info.ai_fire_rate then
									self.last_frame_fire = false
									self.fire_timer = nil
								end
								return
							end
						end
						if weapon_info.ai_aim_time then
							if self.notice_delay:GetMilliseconds() < weapon_info.ai_aim_time then
								return
							end
						end
					end
					-- have ammo, fire weapon
					if not self.fire_timer and self.notice_delay:GetMilliseconds() > 333 then
						actor:SetInput( Action.FireRight, 1 )
						actor:SetInput( Action.FireLeft, 1 )
						actor:SetInput( Action.Fire, 1 )
						self.last_frame_fire = true
						self.fire_timer = Timer()
					end
				end
			end
		else
			actor:SetInput( Action.VehicleFireLeft, 1 )
			local t = self.secondary_delay
			if t:GetSeconds() > 5 then
				t:Restart()
				actor:SetInput( Action.VehicleFireRight, 1 )
			end
		end
	end
	local timer = self.los_timer
	if timer:GetMilliseconds() > 250 then
		timer:Restart()
		local los = self:GetPlayerInLoS()
		if los ~= self.has_los then
			-- update server
			self.has_los = los
			Network:Send( 'PlayerLoSUpdate'..tostring( self.network_id ), los )
		end
	end
end

function AgentGuard:EquipWeapon( id )
	if self.core then
		local actor = self.core.actor
		if actor and IsValid(actor) then
			actor:GiveWeapon( 1, Weapon( id, 1000, 1000 ) )
			self.delayed_equip = nil
		else
			self.delayed_equip = id
		end
	end
end

function AgentGuard:SetAimPosition( position )
	if self.core then
		local actor = self.core.actor
		if actor and IsValid(actor) then
			actor:SetAimPosition( position )
			self.last_aim_position = self.aim_position
			self.aim_position = position
			self.delayed_aim = nil
		else
			self.delayed_aim = position
		end
	end
end

function AgentGuard:GetPlayerInLoS()
	local actor = self.core.actor
	local player_position = LocalPlayer:GetPosition() 
	if IsNaN( player_position ) then return end
	player_position = player_position + Vector3(0, 1.5, 0)
	local actor_position = actor:GetPosition()

	if not actor:GetVehicle() then
		actor_position = actor_position + Vector3( 0, 1.5, 0 )
	end

	local ray_angle = actor_position - player_position

	ray_angle:Normalize()

	local aim_table = Physics:Raycast( player_position, ray_angle, 0, 1000, true )

	local entity = aim_table.entity

	if entity == nil then return false end -- no LoS

	if entity and IsValid( entity ) then
		local entity_type = entity.__type
		local vehicle = self.core.vehicle
		if entity_type == 'ClientActor' then
			if entity == actor then
				-- ray hit this NPC
				return true
			end
			local entity_vehicle = entity:GetVehicle()
			if entity_vehicle and vehicle and IsValid(vehicle) and entity_vehicle == vehicle then
				-- in the case the ray hits another passenger of this NPC's vehicle
				return true
			end
		elseif entity_type == 'Vehicle' then
			if vehicle and IsValid(vehicle) and entity == vehicle then
				-- ray hit this NPC's vehicle
				return true
			end
		end
	end

	return false
end

function AgentGuard:GameRender( dt )
	local t = self.aim_timer
	if t and t:GetMilliseconds() < 1000 then
		local actor = self.core.actor
		if actor and IsValid( actor ) then
			if self.last_aim_position and self.aim_position then
				local lerp_ratio = t:GetMilliseconds() / self.last_update_time
				if lerp_ratio > 1 then lerp_ratio = 1 end
				local position = math.lerp( self.last_aim_position, self.aim_position, lerp_ratio )

				-- raycast, so our sniper laser doesn't go through walls / objects
				local current_position = actor:GetPosition() + Vector3(0, 1, 0)
				local raycast = Physics:Raycast( current_position, (position - current_position), 0, 300 )
				Render:DrawLine( current_position, raycast.position, Color(255,0,0,255*.8) )
			end
		end
	end
end

function AgentGuard:EnterVehicle( vehicle_id )
	if not vehicle_id then
		self.delayed_enter = false
		return
	end
	local vehicle = Vehicle.GetById( vehicle_id )
	local actor = self.core.actor
	if vehicle and IsValid( vehicle ) and actor and IsValid( actor ) then
		self.core.vehicle = vehicle
		actor:EnterVehicle( vehicle, VehicleSeat.Driver )
		self.delayed_enter = false
		self.core.in_vehicle = true
	else
		-- delayed enter
		self.delayed_enter = true
	end
end

function AgentGuard:Remove()
	AM:RemoveFromGrender( self )
end