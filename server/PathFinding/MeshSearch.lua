-- build list of available nav mesh files
GridCellSaved = {}
CellsLoaded = 0
CellsLoadedLimit = 80 -- increasing this value will keep more mesh cells loaded in memory
LoadedCellTimers = {}

function RegisterFile( x, y, name )
	x = tonumber(x)
	y = tonumber(y)
	if not GridCellSaved[x] then
		GridCellSaved[x] = {}
	end
	GridCellSaved[x][y] = name
end

local nav = io.files( 'Nav' )
local count = 0
for _,filename in pairs(nav) do
	local xStart = string.find( filename, 'x' )
	local x = string.sub(filename, 4, xStart-1 )
	local y = string.sub( filename, xStart+1 )
	RegisterFile( x, y, filename )
	count = count + 1
end

-- system for loading / unloading nav mesh files

MeshCell = {}
for x=-32,32,1 do
	for y=-32,32,1 do
		if not MeshCell[x] then
			MeshCell[x] = {}
		end
		MeshCell[x][y] = {}
	end
end

QuarterTemplate = {}
for x=1,16 do
	QuarterTemplate[x] = {}
	for y=1,16 do
		QuarterTemplate[x][y] = {}
	end
end

function IsCellLoaded( x, y )
	return MeshCell[x][y].loaded or false
end

function IsCellLoading( x, y )
	return MeshCell[x][y].loading or false
end

function LoadCell( x, y )
	local load_failed = false
	-- check / unloaded any unused cells

	local can_load = CheckCellStatus()

	if not can_load then
		return false
	end

	local list = {}
	if IsCellLoaded(x, y) or IsCellLoading(x, y) then
		load_failed = true
	else
		if GridCellSaved[x] then
			local file_name = GridCellSaved[x][y]

			if not file_name then
				load_failed = true
			else
				MeshCell[x][y].loading = true
				-- success!
				-- local load_path = 'Nav\\'..file_name
				local load_path = 'Nav/'..file_name
				local file, file_error = io.open( load_path , "rb" )

			    if file_error then 
			            error(file_error)
			        return 
			    end

			    if file ~= nil then 
			        local data = file:read("*a")
			        if data ~= nil then
			        	-- data = string.trim( data )
			        	local co = coroutine.create( LoadCellMesh )
						local success, error_msg = coroutine.resume( co, MeshCell[x][y], data, x, y )
						if not success then
							error(error_msg)
						end
						table.insert( meshLoadTable, co )
			        end
				    file:close()
			    end
			end
		else
			load_failed = true
		end
	end

	return not load_failed
end

meshLoadTable = {}
meshLoadCo = nil

function MeshLoadTick()
	local i = 1
	while i <= #meshLoadTable do
		-- only run 1 coroutine at a time
		local meshLoadCo = meshLoadTable[i]
		if coroutine.status( meshLoadCo ) == 'dead' then
			-- cleanup
			table.remove( meshLoadTable, i )
			return
		else
			local success, error_msg = coroutine.resume( meshLoadCo )
			if not success then
				error(error_msg)
			end
			return	
		end
	end
end

function LoadCellMesh( cell, data, x, y )
	local timer = Timer()
	local NodePosById = {}
	local midPoint = Vector3( x*512, 0, y*512 )
	local quarters = Copy( QuarterTemplate )
	local frame_timer = Timer()
	local ms = 0
	local yields = 0

	local msg = require 'MessagePack'

    local t = {}
	for _, v in msg.unpacker(data) do
		local node = v
		t[#t+1] = node
    	node.position = TableToVector3( node.position )
    	node.x = x
    	node.y = y
        NodePosById[node.id] = node

        local clamp = math.clamp

        local x = clamp( floor( (node.position.x - midPoint.x) / 32 ), 1, 16 )
        local z = clamp( floor( (node.position.z - midPoint.z) / 32 ), 1, 16 )

        if quarters[x][z] then
        	quarters[x][z][#quarters[x][z]+1] = node
        end

        local time = frame_timer:GetMilliseconds()
        if time > time_left then
        	frame_timer:Restart()
        	-- co_count = 0
        	yields = yields + 1
        	ms = ms + time
        	coroutine.yield()
        end
    end

    MeshCell[x][y].nodes = t
    MeshCell[x][y].id = NodePosById
    MeshCell[x][y].quarters = quarters
    MeshCell[x][y].timer = Timer()
    MeshCell[x][y].loaded = true
    MeshCell[x][y].loading = false
    table.insert(LoadedCellTimers, { timer = MeshCell[x][y].timer, x = x, y = y } )
    -- print('NavMeshLoad (x:'..tostring(x)..', y:'..tostring(y)..') took '..tostring(ms)..'ms, actual:'..tostring(timer:GetMilliseconds())..'ms, yield count: '..tostring(yields), 'Nodes:',#t, 'nodes/ms:', #t/ms )
    CellsLoaded = CellsLoaded + 1
end

function CheckCellStatus()
	if CellsLoaded > CellsLoadedLimit then
		return false
	end

	-- iterate the LoadedCellTimers table and unload and cells that haven't
	-- been used recently
	local cells_removed = 0
	local remove = table.remove
	if CellsLoaded > CellsLoadedLimit then
		local i = 1
		while i <= #LoadedCellTimers do
			local cell = LoadedCellTimers[i]
			if cell.timer:GetSeconds() > 15 then
				UnloadCell( cell.x, cell.y )
				remove( LoadedCellTimers, i )
				cells_removed = cells_removed + 1
			else
				i = i + 1
			end
		end
	end

	return true
end

function UnloadCell( x, y )
	if IsCellLoaded( x, y ) then
		MeshCell[x][y].nodes = nil
		MeshCell[x][y].id = nil
		MeshCell[x][y].quarters = nil
		MeshCell[x][y].timer = nil
		MeshCell[x][y].loaded = nil
		CellsLoaded = CellsLoaded - 1
	end
end

function MeshCellGetClosestNodeToPosition( x, y, position )
	if IsCellLoaded(x, y) then
		-- fast lookup
		local quarter, qx, qy = GetMeshQuarterFromPosition( x, y, position )

		local closest = nil
		local closest_distance = 500
		for i=1, #quarter do
			local node = quarter[i]
			if not node.blocked then
				local dist = node.position:Distance( position )
				if dist < closest_distance then
					closest_distance = dist
					closest = node
					if dist < 2 then
						return closest
					end
				end
			end
		end

		if not closest then
			-- slow lookup ~5ms in dense cell
			local cell = GetMeshCell( x, y )
			for i=1, #cell.nodes do
				local node = cell.nodes[i]
				if not node.blocked then
					local dist = node.position:Distance( position )
					if dist < closest_distance then
						closest_distance = dist
						closest = node
						if dist < 2 then
							return closest
						end
					end
				end
			end
		end

		return closest
	end
	return nil
end

function GetMeshNodeById( id, cell )
	return cell.id[id]
end

Console:Subscribe( 'cells_loaded', function()
	print(CellsLoaded, 'Cells loaded..')
end )

function GetMeshCell( x, y )
	if MeshCell[x][y].timer then
		MeshCell[x][y].timer:Restart()
	end
	return MeshCell[x][y]
end

function GetMeshCellFromPosition( position )
	local x = floor(position.x / 512)
	local z = floor(position.z / 512)

	return x, z, MeshCell[x][z]
end

function GetMeshQuarterFromPosition( x, y, position )
	local cell = MeshCell[x][y]
	if cell then
	    cell.timer:Restart()
		local midPoint = Vector3( x*512, 0, y*512 )

	    local qx = floor( (position.x - midPoint.x) / 32 )
	    local qz = floor( (position.z - midPoint.z) / 32 )
	    if cell.quarters[qx] and cell.quarters[qx][qz] then
	    	return cell.quarters[qx][qz], qx, qz
	    end
	    return {}, qx, qz
	end
    return {}
end

function MeshSearch( start, goal, entity, type, priority, starting_yaw, cell )
	-- works like Theta* but uses precomputed neighbours instead of LineOfSight()
	local frontier = PriorityQueue()
	frontier:Put( start, 0 )
	local came_from = {}
   	local cost_so_far = {}
   	came_from[start] = nil
   	cost_so_far[start] = 0
  	local time_so_far = 0
  	local previous = start
  	local last_yaw = {}
  	last_yaw[start] = nil
  	local reached_goal = false
  	local co_count = 0
  	local frame_timer = Timer()
  	local timeout = 1000
  	local goal_position = goal.position
  	if priority == PathPriority.Medium then
  		timeout = 2000
  	elseif priority == PathPriority.High then
  		timeout = 5000
  	end
  	while not frontier:Empty() do
  		if time_so_far > timeout then
  			break
  		end
   		local current = frontier:Get()[1] -- 1 is tuple, 2 is priority
	   	local frame_limit = time_left
   		if current == goal then
   			-- we've reached our goal
   			reached_goal = true
   			if came_from[goal] == nil then
   				came_from[goal] = previous
   			end
   			break
   		end

   		local current_position = current.position

 		for i = 1, #current.neighbours do
 			local next = current.neighbours[i]
 			if next ~= nil then
	   			local next_yaw = next.yaw
	   			local next = GetMeshNodeById( next.id, cell )

	   			-- cell traversal start
	   			if next ~= nil then
	   				local n_position = next.position
		   			local cell_x, cell_y = GetMeshCellFromPosition( n_position )
		   			if cell_x ~= next.x or cell_y ~= next.y then
		   				-- pause pathfinding until cell is loaded
		   				while not IsCellLoaded( cell_x, cell_y ) do
		   					if not IsCellLoading( cell_x, cell_y ) then
		   						LoadCell( cell_x, cell_y )
		   					end
		   					local running_time = tGetMS(frame_timer)
							time_so_far = time_so_far + running_time
							frame_timer:Restart()
		   					coroutine.yield()
		   				end
		   				-- mesh cell traversal
		   				local node = MeshCellGetClosestNodeToPosition( cell_x, cell_y, n_position )
		   				if node then
			   				local new_cost = cost_so_far[current] + Heuristic.EUCLIDIAN( current_position, n_position )
			   				local next_cost = cost_so_far[node]
			   				if next_cost == nil or new_cost < next_cost then
			   					cost_so_far[node] = new_cost
				   				local priority = new_cost + Heuristic.EUCLIDIAN( node.position, goal_position )
				   				frontier:Put( node, priority )
				   				came_from[node] = current
				   				previous = current

				   				if current == goal then
						   			-- we've reached our goal
						   			reached_goal = true
						   			if came_from[goal] == nil then
						   				came_from[goal] = previous
						   			end
						   			break
						   		end
				   			end
				   		end
		   			end
			   	end

		   		-- cell traversal end

	   			-- is it a valid node?
	   			-- is the node blocked by something?
	   			if next and not next.blocked then
	   				local parent = came_from[current]
	   				if parent and last_yaw[parent] == next_yaw then
	   					local new_cost = cost_so_far[parent] + Heuristic.EUCLIDIAN( next.position, parent.position )
	   					local next_cost = cost_so_far[next]
	   					if not next_cost or new_cost < next_cost then
	   						cost_so_far[next] = new_cost
			   				local priority = new_cost + Heuristic.EUCLIDIAN( goal.position, next.position )
			   				frontier:Put( next, priority )
			   				came_from[next] = parent
			   				previous = parent
			   			end
	   				else
			   			local new_cost = cost_so_far[current] + Heuristic.EUCLIDIAN( current.position, next.position ) -- current , next
			   			local next_cost = cost_so_far[next]
			   			if next_cost == nil or new_cost < next_cost then
			   				cost_so_far[next] = new_cost
			   				local priority = new_cost + Heuristic.EUCLIDIAN( next.position, goal.position )
			   				frontier:Put( next, priority )
			   				came_from[next] = current
			   				previous = current
			   				last_yaw[next] = next_yaw
			   			end
			   		end
		   		end
		   	end

			local running_time = tGetMS(frame_timer)
			if running_time > frame_limit then
				time_so_far = time_so_far + running_time
				frame_timer:Restart()
				coroutine.yield()
			end
   		end
   	end

   	if reached_goal then
	   	came_from = ReconstructPath( came_from, start, goal, last_yaw )
		table.insert( GeneratedPaths, { entity = entity, success = true, start = start, goal = goal, path = came_from, type = type } )
	else
		table.insert( GeneratedPaths, { entity = entity, success = false } )
	end

	frontier = nil
	came_from = nil
   	cost_so_far = nil
  	last_yaw = nil
end