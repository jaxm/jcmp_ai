class 'PlayerFoV'

function PlayerFoV:__init()
	self.fov = MeshTriangle( LocalPlayer:GetPosition(), 20 )
	self.fov:SetPosition( LocalPlayer:GetPosition() )
	self.fov.width_multi = 3
	self.last_yaw = 0
	self.anti_spam = Timer()
	Events:Subscribe( 'PostTick', self, self.Update )
end

function PlayerFoV:Update()
	if self.fov then
		local yaw = Camera:GetAngle().yaw
		local fyaw = math.floor(math.deg(yaw))
		if fyaw ~= self.last_yaw then
			local angle = Angle( yaw, 0, 0 )
			self.fov:UpdatePositionAndAngle( Camera:GetPosition(), angle )
			local t = self.anti_spam
			if t:GetMilliseconds() > 250 then
				t:Restart()
				self.last_yaw = fyaw
				Network:Send( 'PlayerFoVUpdate', { position = Camera:GetPosition(), yaw = math.rad(fyaw) } )
			end
		end
	end
end

LPFoV = nil
Events:Subscribe( 'ModuleLoad', function()

	LPFoV = PlayerFoV()
end )