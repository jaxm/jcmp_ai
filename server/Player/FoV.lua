
PlayerFoV = {}

function CreateNewPlayerFoV( player )
	local fov = MeshTriangle( player:GetPosition(), 20 )
	fov.width_multi = 3
	PlayerFoV[player:GetId()] = fov
end

Events:Subscribe( 'ModuleLoad', function()
	for p in Server:GetPlayers() do
		CreateNewPlayerFoV( p )
	end
end )

Events:Subscribe( 'PlayerJoin', function( e )
	CreateNewPlayerFoV( e.player )
end )

Events:Subscribe( 'PlayerQuit', function( e )
	local player = e.player
	PlayerFoV[player:GetId()] = nil
end )

Network:Subscribe( 'PlayerFoVUpdate', function( t, sender )
	if not sender or not IsValid(sender) then return end

	local fov = PlayerFoV[sender:GetId()]

	if fov then
		fov:UpdatePositionAndAngle( t.position, Angle( t.yaw, 0, 0 ) )
	end
end )

function IsPositionInCellPlayersFoV( position, cell )
	local connected_cells = GetNearbyCells( cell.x, cell.y )
	for c=1,#connected_cells do
		local cell = connected_cells[c]
		for i=1,#MapCells[cell.x][cell.y].players do
			local player = MapCells[cell.x][cell.y].players[i]
			if player and IsValid(player) then
				if position:Distance( player:GetPosition() ) < 45 then
					return true
				end

				if IsPositionInPlayerFoV( position, player ) then
					return true
				end
			end
		end
	end

	return false
end

function IsPositionInPlayerFoV( position, player )
	if player and IsValid( player ) then
		local fov = PlayerFoV[player:GetId()]
		if fov then
			if fov:IsPointInside( position ) then
				return true
			end
		end
	end
	return false
end