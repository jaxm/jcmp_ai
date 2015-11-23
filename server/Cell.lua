MapCells = {}
CellTimer = Timer()
CellRoutine = nil
ModuleUnloading = false
-- next 2 defines are per cell around the player
-- so 5 peds per cell, can potentially be 45 pedestrians
-- around a player. Each cell is 128m^2 in size.
CellVehicleTrafficLimit = 2
CellPedTrafficLimit = 4 -- 6
DelayedTrafficRemove = {}

local id = 1
for x=-128,128,1 do
	for y=-128,128,1 do
		if not MapCells[x] then
			MapCells[x] = {}
		end
		MapCells[x][y] = {
			x = x,
			y = y,
			actors = {},
			vehicles = {},
			vehicle_traffic = {},
			pedestrian_traffic = {},
			nodes = {},
			players = {},
			id = id
		}
		id = id + 1
	end
end

function GetNearbyCells( x, y )
	return {
		GetCell( x, y ), -- middle
		GetCell( x-1, y-1 ), -- top left
		GetCell( x-1, y ), -- middle left
		GetCell( x-1, y+1 ), -- bottom left
		GetCell( x+1, y-1 ), -- top right
		GetCell( x+1, y ), -- middle right
		GetCell( x+1, y+1 ), -- bottom right
		GetCell( x, y-1 ), -- top
		GetCell( x, y+1 ) -- bottom
	}
end

function AddNodeToCell( node, id, x, y )
	if not MapCells[x][y].nodes[id] then
		MapCells[x][y].nodes[id] = {}
	end
	table.insert( MapCells[x][y].nodes[id], node )
end

function AddPlayerToCell( player, x, y )
	table.insert( MapCells[x][y].players, player )
end

function AddActorToCell( actor, x, y )
	if MapCells[x] and MapCells[x][y] then
		table.insert( MapCells[x][y].actors, actor )
	else
		-- error( 'AddActorToCell called on invalid cell', actor, x, y )
		print( 'AddActorToCell called on invalid cell', actor, x, y )
	end
end

function AddVehicleTrafficToCell( traffic, x, y )
	table.insert( MapCells[x][y].vehicle_traffic, traffic )
end

function AddPedestrianTrafficToCell( traffic, x, y )
	table.insert( MapCells[x][y].pedestrian_traffic, traffic )
end

function RemoveVehicleTrafficFromCell( traffic, x, y )
	local i = 1
	while i<= #MapCells[x][y].vehicle_traffic do
		local cell_vehicle_traffic = MapCells[x][y].vehicle_traffic[i]
		if cell_vehicle_traffic and IsValid(cell_vehicle_traffic) then
			if cell_vehicle_traffic == traffic then
				table.remove( MapCells[x][y].vehicle_traffic, i )
				break
			else
				i = i + 1
			end
		else
			table.remove( MapCells[x][y].vehicle_traffic, i )
		end
	end
end

function RemovePedestrianTrafficFromCell( traffic, x, y )
	local i = 1
	while i<= #MapCells[x][y].pedestrian_traffic do
		local cell_pedestrian_traffic = MapCells[x][y].pedestrian_traffic[i]
		if cell_pedestrian_traffic == traffic then
			table.remove( MapCells[x][y].pedestrian_traffic, i )
			break
		else
			i = i + 1
		end
	end
end

function RemovePlayerFromCell( player, x, y )
	local i = 1
	while i<=#MapCells[x][y].players do
		local cell_player = MapCells[x][y].players[i]
		if cell_player and IsValid(cell_player) then
			if cell_player == player then
				table.remove( MapCells[x][y].players, i )
				break
			else
				i = i + 1
			end
		else
			table.remove( MapCells[x][y].players, i )
		end
	end
end

function RemoveActorFromCell( actor, x, y )
	local t = MapCells[x][y].actors
	for i=1, #t do
		local cell_actor = t[i]
		if cell_actor == actor then
			table.remove( MapCells[x][y].actors, i )
			break
		end
	end
end

function AddVehicleToCell( vehicle, x, y )
	table.insert( MapCells[x][y].vehicles, vehicle )
end

function RemoveVehicleFromCell( vehicle, x, y )
	-- for i=1, #MapCells[x][y].vehicles do
	local i = 1
	while i<= #MapCells[x][y].vehicles do
		local cell_vehicle = MapCells[x][y].vehicles[i]
		if cell_vehicle and IsValid(cell_vehicle) then
			if cell_vehicle == vehicle then
				table.remove( MapCells[x][y].vehicles, i )
				return
			else
				i = i + 1
			end
		else
			table.remove( MapCells[x][y].vehicles, i )
		end
	end
end

function GetCell( x, y )
	-- returns empty table if out of bounds
	if not MapCells[x] then return nil end
	return MapCells[x][y] --or {}
end

function GetCellFromPosition( position )
	local x = floor(position.x / 128)
	local y = floor(position.z / 128)

	return GetCell( x, y )
end

function GetCellXYFromPosition( position )
	local x = floor(position.x / 128)
	local z = floor(position.z / 128)
	return x, z
end

GlobalActiveCells = {}
local ActiveCellTimer = Timer()
function CellMainLoop( e )
	if not bMapLoaded then return end
	if ActiveCellTimer:GetMilliseconds() < 500 then return end
	ActiveCellTimer:Restart()
	local ActiveCells = {}
	local EmptyCells = {}
	local CellCleanupList = {}
	local CellList = {}
	local insert = table.insert
	-- cycle through players, get their cells to build a list of cells that
	-- we want to process

	for p in Server:GetPlayers() do
		local position = p:GetPosition()
		local cell = GetCellFromPosition( position )
		if cell then
			if not ActiveCells[cell.id] then
				ActiveCells[cell.id] = true
				insert( CellList, cell )

				local connected_cells = GetNearbyCells( cell.x, cell.y )

				for i=1,#connected_cells do
					local connected_cell = connected_cells[i]
					if not ActiveCells[connected_cell.id] then
						ActiveCells[connected_cell.id] = true
						insert( CellList, connected_cell )
					end
				end
			end

			-- check player cell traversal

			local x = cell.x
			local y = cell.y

			local last_cell = p:GetValue( 'cell' )
			if not last_cell then
				AddPlayerToCell( p, x, y )
				p:SetValue( 'cell', {x=x, y=y} )
			else
				if last_cell.x ~= x or last_cell.y ~= y then
					-- cell doesn't match up, the player has moved cell
					-- update cells of this
					RemovePlayerFromCell( p, last_cell.x, last_cell.y )
					last_cell = GetCell(last_cell.x, last_cell.y)
					-- CheckCellForCleanup( last_cell.x, last_cell.y )
					if not EmptyCells[last_cell.id] and #last_cell.players == 0 then
						EmptyCells[last_cell.id] = true
						insert( CellCleanupList, last_cell )
					end
					AddPlayerToCell( p, x, y )
					p:SetValue( 'cell', {x=x,y=y} )
				end
			end
		end
	end

	-- process cells, populate

	for i=1,#CellList do
		local cell = CellList[i]
		ProcessCell( cell.x, cell.y )
	end

	GlobalActiveCells = CellList

	-- process cells, unload if needed
	for i=1,#CellCleanupList do
		local cell = CellCleanupList[i]
		CheckCellForCleanup( cell.x, cell.y )
	end

	-- attempt to remove any delayed vehicle removal requests
	local i = 1
	while i<= #DelayedTrafficRemove do
		local traffic = DelayedTrafficRemove[i]
		if traffic then
			local position = traffic:GetPosition()
			if position then
				local cell = GetCellFromPosition( position )
				if cell then
					if not IsPositionInCellPlayersFoV( position, cell ) then
						traffic:Remove()
						table.remove( DelayedTrafficRemove, i )
					else
						i = i + 1
					end
				else
					i = i + 1
				end
			else
				i = i + 1
			end
		else
			table.remove( DelayedTrafficRemove, i )
		end
	end
end

function ProcessCell( x, y )
	if not MapCells[x] then
		return
	end
	local remove = table.remove
	local cell = MapCells[x][y] 

	local cells_players, cells_traffic, cells_pedestrians = GetConnectedCellsInfo( x, y )

	-- only process cells that have players in them
	if cells_players > 0 then

		local road_nodes = cell.nodes[1]

		if road_nodes and #road_nodes > 1 then
			if #cell.vehicle_traffic < CellVehicleTrafficLimit then
				-- add vehicle traffic

				local random_node = table.randomvalue( road_nodes )
				local neighbours = #random_node.neighbours
				if random_node and neighbours > 0 and neighbours < 3 and random_node.vehicle_node then
					SpawnVehicleAtNode( random_node, cell )
				end
			end
			local current_pedestrians = #cell.pedestrian_traffic
			if current_pedestrians < CellPedTrafficLimit then
				-- add pedestrian traffic
				-- this while loop will attempt to fully populate the cell with pedestrians
				-- as each node won't fit the requirements, its likely to require a few loops 
				-- to fully populate the cell.
				local spawn_limit_frame = floor(CellPedTrafficLimit - current_pedestrians )*.25
				local i = 1
				while i <= spawn_limit_frame do
					local random_node = table.randomvalue( road_nodes )
					local neighbours = #random_node.neighbours
					if random_node and random_node.pedestrian_node and neighbours > 0 and neighbours < 3 then
						SpawnPedestrianAtNode( random_node, cell )
					end
					i = i + 1
				end
			end
		end

		if #cell.pedestrian_traffic > 0 then
			local i = 1
			while i<= #cell.pedestrian_traffic do
				local pedestrian = cell.pedestrian_traffic[i]
				if not pedestrian or not pedestrian.npc then
					remove( cell.pedestrian_traffic, i )
				else
					i = i + 1
				end
			end
		end

		if #cell.pedestrian_traffic > 0 then
			-- process pedestrian traffic
			local traffic = cell.pedestrian_traffic
			local i = 1
			while i <= #traffic do
				local ped = traffic[i]
				if ped and IsValid( ped ) then
					local position = ped:GetPosition()
					if position then
						local px, py = GetCellXYFromPosition( position )
						if px ~= x or py ~= y then
							-- changed cell, move if cell contains players

							local new_cells_players, new_cells_traffic, new_cells_pedestrians = GetConnectedCellsInfo( px, py )

							-- if cell contains players and is currently under the CellPedTrafficLimit, transfer ped
							if new_cells_players > 0 and new_cells_pedestrians < CellPedTrafficLimit then
								RemovePedestrianTrafficFromCell( ped, x, y )
								AddPedestrianTrafficToCell( ped, px, py )
							else
								-- no players or limit exceeded, remove ped
								ped:Remove()
								remove( cell.pedestrian_traffic, i )
							end
						else
							i = i + 1
						end
					else
						i = i + 1
					end
				else
					-- invalid ped, remove
					remove( cell.pedestrian_traffic, i )
				end
			end
		end

		if #cell.vehicles > 0 then
			-- process vehicles and calculate blocked nav mesh nodes
			local meshX = floor(cell.x *.25) --4
			local meshY = floor(cell.y *.25) --4
			local meshCell = MeshCell[meshX][meshY]
			if IsCellLoaded( meshX, meshY ) then
				for i=1, #meshCell.nodes do
					local node = meshCell.nodes[i]
					if node.blocked then
						node.blocked = nil
					end
				end
				for i=1, #cell.vehicles do
					local vehicle = cell.vehicles[i]

					if vehicle and IsValid(vehicle) then
						local model = vehicle:GetModelId()
						local position = vehicle:GetPosition()
						local angle = vehicle:GetAngle()
						local meshQuarter = GetMeshQuarterFromPosition( meshX, meshY, position )
						for n=1, #meshQuarter do
							local node = meshQuarter[n]
							if node.position:IsObscuredByVehicleEfficient( model, position, angle ) then
								if not node.blocked then
									node.blocked = true
									for c=1, #node.neighbours do
										local neighbour = node.neighbours[c]
										neighbour = GetMeshNodeById( neighbour.id, meshCell )
										if neighbour then
											neighbour.blocked = true
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function CheckCellForCleanup( x, y )
	local cells = GetNearbyCells( x, y )

	for i=1, #cells do
		local cell = cells[i]

		local cells_players, cells_traffic, cells_pedestrians = GetConnectedCellsInfo( cell.x, cell.y )

		if cells_players == 0 then
			if cells_traffic > 0 or cells_pedestrians > 0 then
				CleanupCell( cell.x, cell.y )
			end
		end
	end
end

function CleanupCell( x, y )
	local vehicle_traffic_table = MapCells[x][y].vehicle_traffic
	if #vehicle_traffic_table > 0 then
		for i=1,#vehicle_traffic_table do
			local vehicle = vehicle_traffic_table[i]
			if vehicle and not vehicle.marked_for_removal then
				vehicle.marked_for_removal = true
				table.insert( DelayedTrafficRemove, vehicle )
			end
		end
	end

	-- cleanup pedestrian traffic
	local ped_traffic_table = MapCells[x][y].pedestrian_traffic
	if #ped_traffic_table > 0 then
		local remove = table.remove
		local i = 1
		while i <= #ped_traffic_table do
			local ped = ped_traffic_table[i]
			if ped then
				if ped.npc and ped.npc.goal ~= AiGoal.Zombie then
					ped.npc.flagged_for_deletion = true
					ped:Remove()
				end
			end
			remove( ped_traffic_table, i )
		end
	end
end

function SpawnPedestrianAtNode( node, cell )
	-- choose a side of the street to spawn the pedestrian on
	local side = ceil(random(2))
	local ped = Pedestrian( {
			position = GetSideWalkPosition( node, nil, side ),
			angle = Angle(),
			faction = Faction.Citizen
		} )

	ped.street_side = side
	-- add new pedestrian to the cells ped pool
	AddPedestrianTrafficToCell( ped, cell.x, cell.y )
end

function SpawnVehicleAtNode( node, cell )
	if node then
		-- get correct facing for spawning the vehicle here
		local node_neighbour = node.neighbours[1]
		local angle = Angle()
		if node_neighbour and node_neighbour.yaw then
			angle = Angle( rad( node_neighbour.yaw ), 0, 0 )
		end

		local position = nil

		if node_neighbour then
			local node_neighbour = GetNodeById( node_neighbour.id, 1 )
			position = GetLanePosition( node, node_neighbour, nil )
		else
			position = Copy( node.position )
		end

		if SpawnSpaceAvailable( position, cell ) then

			local traffic_vehicle = Traffic( position, angle, Faction.Citizen, lane, cell )
			AddVehicleTrafficToCell( traffic_vehicle, cell.x, cell.y )
		end
	end
end

function SpawnSpaceAvailable( position, cell )
	-- checks cell's vehicles against the position
	local vehicles = cell.vehicles
	for i=1,#vehicles do
		local vehicle = vehicles[i]
		if vehicle and IsValid(vehicle) then

			if position:Distance( vehicle:GetPosition() ) < 15 then
				return false
			end
			local driver_id = vehicle:GetValue( 'NPCDriver' )
			local vehicleDriver = nil
			if driver_id then
				vehicleDriver = AM.actors_id[driver_id]
			end

			if vehicleDriver and IsValid( vehicleDriver ) then
				if vehicleDriver.fov:IsPointInside( position ) then
					return false
				end
			else
				-- player vehicle
				if position:IsObscuredByVehicle( vehicle ) then
					return false
				end
			end
		end
	end
	-- no squashing players!
	local players = cell.players
	for i=1,#players do
		local player = players[i]
		if player and IsValid( player ) then
			if position:Distance( player:GetPosition() ) < 25 then
				return false
			end
			if IsPositionInPlayerFoV( position, player ) then
				return false
			end
		end
	end

	return true
end

function GetConnectedCellsInfo( x, y )
	local cells_players = 0
	local cells_traffic = 0
	local cells_pedestrians = 0

	local connected_cells = GetNearbyCells( x, y )

	for i=1,#connected_cells do
		local connected_cell = connected_cells[i]
		cells_players = cells_players + #connected_cell.players
		cells_traffic = cells_traffic + #connected_cell.vehicle_traffic
		cells_pedestrians = cells_pedestrians + #connected_cell.pedestrian_traffic
	end

	return cells_players, cells_traffic, cells_pedestrians
end

function GetSideWalkPosition( node, yaw, side )
	local position = node.position
	local check_road_direction = false
	local reverse_direction = false

	if not yaw then
		local node_neighbour = node.neighbours[1]
		yaw = node_neighbour.yaw
	else
		-- a yaw has been provided, we can now compare the yaw provied 
		-- vs the direction of the road this should minimize how often
		-- the peds want to cross the road.

		check_road_direction = true
	end
	local angle = Angle()
	if yaw then
		angle = Angle( rad( yaw ), 0, 0 )
	end

	if check_road_direction then
		local node_neighbour = node.neighbours[1]
		local road_direction = Angle( rad( node_neighbour.yaw ), 0, 0 )
		local angle_difference = deg(abs((angle * road_direction:Inverse()).yaw))
		if angle_difference > 90 then
			reverse_direction = true
		end
	end
	
	local size = node.info.size
	local n = RoadLanes[size]
	local road_width = RoadWidth[size] / n

	-- left or right?
	if not side then
		side = ceil(random(2))
	end
	local direction = nil
	local offset = 0
	local sidewalk_width = 0

	if side == 1 then
		-- left
		if not reverse_direction then
			direction = Vector3.Left
		else
			direction = Vector3.Right
		end
		offset = node.info.sidewalk_offset_left
		sidewalk_width = node.info.sidewalk_left
	else
		-- right
		if not reverse_direction then
			direction = Vector3.Right
		else
			direction = Vector3.Left
		end
		offset = node.info.sidewalk_offset_right
		sidewalk_width = node.info.sidewalk_right
	end

	local dist = road_width + offset + (sidewalk_width*(.45+random(-.05, .05)))

	position = position + (( angle * direction ) * dist)

	return position
end

function GetLanePosition( from_node, node, from_position, lane )
	if from_node then
		from_position = from_node.position
	end
	local position = Copy(node.position)
	local offset = Vector3()

	local vec_dir = position - from_position
	vec_dir:Normalize()

	local angle = Angle.FromVectors( Vector3.Forward, vec_dir )

	if not lane then
		lane = 0
	end

	if node.info and node.info.size then

		local info = node.info
		local isBiDirectional = (info.traverse_type == TraverseType.BIDIRECTIONAL)
		local size = info.size

		if size == RoadSize.SINGLE_LANE then
			return position, offset
		end

		local n = RoadLanes[size]
		local width = RoadWidth[size] / n

		if isBiDirectional then
			local numberOfLanes = n*.5
			local laneWidth = width
			-- lane = floor( random( -numberOfLanes, numberOfLanes ) )
			if lane > numberOfLanes then
				lane = numberOfLanes
			else
				lane = 0
			end

			local laneCalc = 0
			if lane > 0 then
				laneCalc = ( lane * laneWidth ) - ( laneWidth * .5 )
			else
				laneCalc = ( lane * laneWidth ) + ( laneWidth * .5 )
			end
			offset = angle * ( Vector3.Right * laneCalc )
			position = position + offset
		else
			-- one way road
			local numberOfLanes = n
			if lane > numberOfLanes then
				lane = numberOfLanes
			else
				lane = 0
			end
			local laneCalc = (width*lane) - ( width*.5 )
			offset = angle * (Vector3.Right * laneCalc)
			position = position + offset
		end
	end

	return position, offset
end

Events:Subscribe( 'ModuleLoad', function()
	for p in Server:GetPlayers() do
		if p and IsValid(p) then
			local position = p:GetPosition()
			local player_x, player_y = GetCellXYFromPosition( position )
			AddPlayerToCell( p, player_x, player_y )
			p:SetValue( 'cell', {x=player_x, y=player_y} )
		end
	end
end )

Events:Subscribe( 'PlayerQuit', function( e )
	local player = e.player
	local position = player:GetPosition()

	local last_cell = player:GetValue('cell')

	RemovePlayerFromCell( player, last_cell.x, last_cell.y )
	CheckCellForCleanup( last_cell.x, last_cell.y )
end )

Events:Subscribe( 'ModuleUnload', function()
	ModuleUnloading = true
	for p in Server:GetPlayers() do
		if p and IsValid(p) then
			p:SetValue( 'cell', nil )
		end
	end
end )

Events:Subscribe( 'EntitySpawn', function( e )
	if e.entity.__type ~= 'Vehicle' then return end
	local vehicle =  e.entity

	local cell_x, cell_y = GetCellXYFromPosition( vehicle:GetPosition() )
	local cell = {
		x = cell_x,
		y = cell_y
	}
	local saved_cell = vehicle:GetValue( 'cell' )

	if not saved_cell then
		-- first spawn
		AddVehicleToCell( vehicle, cell.x, cell.y )
		vehicle:SetValue( 'cell', cell )
	else
		-- respawn, check for cell change
		if cell.x ~= saved_cell.x or cell.y ~= saved_cell.y then
			-- cell change
			RemoveVehicleFromCell( vehicle, saved_cell.x, saved_cell.y )

			AddVehicleToCell( vehicle, cell.x, cell.y )

			vehicle:SetValue( 'cell', cell )
		end
	end
end )

Events:Subscribe( 'EntityDespawn', function( e )
	if ModuleUnloading then return end
	if e.entity.__type ~= 'Vehicle' then return end

	local vehicle =  e.entity
	local saved_cell = vehicle:GetValue( 'cell' )
	-- remove vehicle from cell
	if saved_cell then
		RemoveVehicleFromCell( vehicle, saved_cell.x, saved_cell.y )
	end
end )

Console:Subscribe( 'dumpcell', function()
	local player = Player.GetById(0)
	if not player then return end

	local cell = GetCellFromPosition( player:GetPosition() )

	for k,v in pairs(cell) do
		if type(v) == 'table' then
			print(k, v, #v)
		else
			print(k,v)
		end
	end
end )