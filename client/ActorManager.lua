class 'ActorManager'

function ActorManager:__init( ... )
	self.actors = {}
	self.actors_grender = {}
	self.actor_aim = {}
	self.actor_on_screen = {}
	self.unloading = false
	self.actor_count = 0
	self.delayed_actor_remove = {}

	self.timers = {
		vehicle_collide = Timer()
	}

	self.events = {
		unload = Events:Subscribe( 'ModuleUnload', self, self.ModuleUnload ),
		object_render = Events:Subscribe( 'Render', self, self.Render ),
		object_tick = Events:Subscribe( 'PostTick', self, self.Tick ),
		object_gamerender = Events:Subscribe( 'GameRender', self, self.GameRender ),
		actor_collide = Events:Subscribe( 'VehicleCollide', self, self.VehicleCollide )
	}
end

Console:Subscribe( 'actors', function()
	print(AM.actor_count)
end )

function ActorManager:VehicleCollide( e )
	if e.entity and IsValid( e.entity ) and e.attacker and IsValid(e.attacker) then
		local vehicle = LocalPlayer:GetVehicle()
		if not vehicle then return end
		if not vehicle or not IsValid(vehicle) then return end
		if not vehicle:GetId() == e.attacker:GetId() then return end
		if e.attacker:GetDriver() == nil then return end
		if not e.attacker:GetDriver() == LocalPlayer then return end

		-- only want this code firing if its the LocalPlayer doing the colliding

		local entity = e.entity
		local entityType = entity.__type
		if entityType == 'ClientActor' then
			local actor = self.actor_aim[e.entity:GetId()]
			if actor and not actor.in_vehicle then
				local timer = self.timers.vehicle_collide

				if timer:GetMilliseconds() > 125 or actor.network_object:GetId() ~= self.last_hit then
					if e.attacker:GetLinearVelocity():Length() > .5 then
						timer:Restart()

						local hit_dir = e.entity:GetPosition() - e.attacker:GetPosition()
						local hit_angle = Angle.FromVectors( Vector3.Forward, hit_dir )
						Network:Send( 'ActorHitByCar', { 
							WNO = actor.network_object,
							angle = hit_angle,
							impulse = (e.impulse / 5) -- actor mass
						} )
						self.last_hit = actor.network_object:GetId()
					end
				end
			end
		elseif entityType == 'Vehicle' then
			local actorId = entity:GetValue( 'NPCDriver' )
			if actorId then
				local actor = self.actor_aim[actorId]
				if actor then
					-- actor in vehicle
					if e.attacker.__type == 'Vehicle' then
						local driver = e.attacker:GetDriver()
						if driver and IsValid(driver) then
							if driver == LocalPlayer then
								-- LocalPlayer is driving
								if self.timers.vehicle_collide:GetMilliseconds() > 125 and e.attacker:GetLinearVelocity():Length() > 1 then
									self.timers.vehicle_collide:Restart()
									local hit_dir = actor.position - e.attacker:GetPosition()
									local hit_angle = Angle.FromVectors( Vector3.Forward, hit_dir )
									Network:Send( 'VehicleCollideEvent', { 
										WNO = actor.network_object,
										angle = hit_angle,
										impulse = (e.impulse / actor.vehicle:GetMass()),
										angularVelocity = actor.vehicle:GetAngularVelocity()
									} )
								end
							end
						end
					end
				end
			end
		end
	end
end

function ActorManager:Tick( e )
	if not LocalPlayer:IsTeleporting() then
		for i,class_obj in pairs(self.actors) do

			if not class_obj then return end

			local obj_WNO = class_obj.network_object

			if obj_WNO and IsValid( obj_WNO ) then
				if class_obj.Tick then
					class_obj:Tick( e )
				end
			end
		end
	end

	collectgarbage('step', 100)
end

function ActorManager:Render( e )

	if HeatTimer:GetMilliseconds() > 3000 then
		for i,class_obj in pairs(self.actors) do

			if not class_obj then return end

			local obj_WNO = class_obj.network_object

			if obj_WNO and IsValid( obj_WNO ) and not class_obj.dead then
				if class_obj.Render then
					class_obj:Render( e )
				end

				local wtm, success = Render:WorldToMinimap( obj_WNO:GetPosition() )
				if success then
					local goal = obj_WNO:GetValue( 'goal' )
					if goal and goal == AiGoal.Zombie then
						Render:FillCircle( wtm, 6 , Color.Black )
						Render:FillCircle( wtm, 5, Color.Red )
					elseif goal and goal == AiGoal.RescueObjective then
						Render:FillCircle( wtm, 4 , Color.Black )
						Render:FillCircle( wtm, 3, Color.LightBlue )
					elseif goal and goal == AiGoal.Pursue then
						if not class_obj.minimap_timer then
							class_obj.minimap_timer = Timer()
							class_obj.minimap_colour = Color.Red
							class_obj.minimap_colour_alternate = Color.LightBlue
						else
							local t = class_obj.minimap_timer
							local time = t:GetMilliseconds()
							if time > 1500 then
								t:Restart()
								if class_obj.minimap_colour == Color.Red then
									class_obj.minimap_colour = Color.LightBlue
									class_obj.minimap_colour_alternate = Color.Red
								else
									class_obj.minimap_colour = Color.Red
									class_obj.minimap_colour_alternate = Color.LightBlue
								end
							end

							-- build colour
							local ratio = time / 1500
							if ratio > 1 then ratio = 1 end
							local colour = math.lerp( class_obj.minimap_colour, class_obj.minimap_colour_alternate, ratio )
							Render:FillCircle( wtm, 4 , Color.Black )
							Render:FillCircle( wtm, 3, colour )
						end
					else
						Render:FillCircle( wtm, 3 , Color.Black )
						Render:FillCircle( wtm, 2, Color.White )
					end
				end
			end
		end
	end

	if LocalPlayer:GetVehicle() then return end

	local aim_target = LocalPlayer:GetAimTarget()
	if aim_target.entity and aim_target.entity.__type == 'ClientActor' then

		local class_obj = self.actor_aim[aim_target.entity:GetId()]

		if not class_obj then return end

		local obj_WNO = class_obj.network_object

		if obj_WNO and IsValid( obj_WNO ) then
			local text_size = 20
			local string = obj_WNO:GetValue('name') or obj_WNO:GetValue('class') or 'NoName'
			local string_w = Render:GetTextWidth( string, text_size )
			local string_h = Render:GetTextHeight( string, text_size )
			local actor = self.actors[obj_WNO:GetId()]
			local position = nil
			if actor then
				position = actor.position
			end
			local wts, on_screen = Render:WorldToScreen( position or obj_WNO:GetPosition() )

			local colour = Color.LawnGreen

			if class_obj.goal then
				local goal = class_obj.goal
				if goal == AiGoal.Zombie then
					colour = Color.Red
				elseif goal == AiGoal.RescueObjective then
					colour = Color.LightBlue
				else
					colour = Color.White
				end
			end

			wts = wts - Vector2( string_w/2, 0 )
			if on_screen then
				Render:DrawText( wts + Vector2.One, string, Color.Black, text_size )
				Render:DrawText( wts, string, colour, text_size )

				local health = obj_WNO:GetValue( 'health' )
				
				if health then
					wts.y = wts.y + string_h
					Render:FillArea( wts, Vector2( string_w, 6), Color.Black )
					if health > 0 then
						local ratio = health / obj_WNO:GetValue( 'max_health' )
						Render:FillArea( wts, Vector2( (string_w+1)*ratio, 4), colour )
					end
				end

				if class_obj.CustomRender then
					class_obj:CustomRender( wts, string_w )
				end
			end
		end
	end
end

function ActorManager:GameRender( dt )

	for i,class_obj in pairs(self.actors_grender) do

		if not class_obj then return end
		if class_obj.GameRender then
			class_obj:GameRender( dt )
		end
	end
end

function ActorManager:RemoveFromGrender( obj )
	local i = 1
	while i <= #self.actors_grender do
		local object = self.actors_grender[i]
		if object and IsValid( object ) then
			if object == obj then
				table.remove( self.actors_grender, i )
			else
				i = i + 1
			end
		else
			table.remove( self.actors_grender, i )
		end
	end
end

function ActorManager:NetworkObjectValueChange( e )
	if e.object and IsValid( e.object ) then
		local obj = self.actors[e.object:GetId()]
		if not obj then return end
		obj:Update( e )
		if e.key == 'health' then
			local previous_health = obj.previous_health or e.object:GetValue( 'max_health' )
			obj.previous_health = e.value
			local damage = previous_health - e.value
			if damage > 0 then
				local wts, on_screen = Render:WorldToScreen( e.object:GetPosition() )

				if on_screen then
					Events:Fire( 'HudDamageDealt', { damage = damage, position = wts, crit = false, color = Color.White } )
				end
			end
		end
	end
end

function ActorManager:WorldNetworkObjectCreate( e )
	local object = e.object

	local class = object:GetValue( 'class' )
	
	if class then
		if _G[class] then
			local new_obj = _G[class]( object )

			if new_obj then
				self.actors[object:GetId()] = new_obj
				self.actor_count = self.actor_count + 1
			else
				print('failed to create object from WNO', object, class, new_obj)
			end
		end
	end
end

function ActorManager:WorldNetworkObjectDestroy( e )
	local id = e.object:GetId()
	if self.actors[id] then
		self.actors[id]:Remove()
		self.actors[id] = nil
		self.actor_count = self.actor_count - 1
	end
end

function ActorManager:ModuleUnload( ... )
	self.unloading = true

	-- cleanup events
	for _,event in pairs(self.events) do
		if event then
			Events:Unsubscribe( event )
		end
	end

	-- cleanup objects
	for _,v in pairs(self.actors) do
		if v then
			v:Remove()
		end
	end
end

AM = ActorManager()