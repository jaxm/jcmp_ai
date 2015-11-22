class 'GameModeManager'

function GameModeManager:__init( ... )
	-- current active gamemode
	self.current_gamemode = nil
	-- events for creating / destroying current gamemode
	self.game_mode_created_event = Events:Subscribe( 'NetworkObjectCreate', self, self.CreateGameMode )
	self.game_mode_removed_event = Events:Subscribe( 'NetworkObjectDestroy', self, self.DestroyGameMode )

end

function GameModeManager:CreateGameMode( e )
	local object = e.object
	if object:GetName() == 'GameMode' then
		local class = object:GetValue( 'class' )

		if class then
			if _G[class] then
				local new_mode = _G[class]( object )

				if new_mode then
					self.current_gamemode = new_mode
				end
			end
		end
	end
end

function GameModeManager:DestroyGameMode( e )
	local object = e.object

	if object:GetName() == 'GameMode' then
		if self.current_gamemode then
			self.current_gamemode:Remove()
			self.current_gamemode = nil
		end
	end
end

GMM = GameModeManager()