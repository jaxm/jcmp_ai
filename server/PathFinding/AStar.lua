
GeneratedPaths = {}
RequestedPaths = {}
time_left = 0

function GeneratePath( from, to, entity, type, priority, starting_yaw )
	-- path requests are all made through this function
	if not type then
		type = 1
	end

	local start_node = nil
	local end_node = nil
	local search_type = AStarSearch
	local cell = nil
	local x = nil
	local y = nil

	if type == 2 then

		-- mesh navigation
		local t = {
			from = from,
			to = to,
			entity = entity,
			type = type,
			priority = priority
		}
		if starting_yaw then
			t.starting_yaw = starting_yaw
		end

		table.insert( RequestedPaths, t )

		return
	else
		if from.__type == 'Vector3' then
    		start_node = GetClosestNode( from, type )
    	else
    		start_node = from
    	end
    	if to.__type == 'Vector3' then
			end_node = GetClosestNode( to, type )
		else
			end_node = to
		end
	end


	if start_node and end_node then
		-- start and end node are valid
		
		local co = coroutine.create( search_type )
		local success, error_msg = coroutine.resume( co, start_node, end_node, entity, type, priority, starting_yaw, cell )
		if not success then
			error(error_message)
		end
		if priority == PathPriority.High then
			table.insert( CurrentPaths.High, co )
		elseif priority == PathPriority.Medium then
			table.insert( CurrentPaths.Medium, co )
		else
			table.insert( CurrentPaths.Low, co )
		end
	else
		-- path generation failed
		table.insert( GeneratedPaths, { entity = entity, success = false, reason = 'start or end invalid' } )
	end
end

function AStarSearch( start, goal, entity, type, priority, starting_yaw, cell )
	local frontier = PriorityQueue()
	frontier:Put( start, 0 )
	local came_from = {}
   	local cost_so_far = {}
   	came_from[start] = nil
   	cost_so_far[start] = 0
  	local time_so_far = 0 -- time this operation has taken in ms
  	local previous = start
  	local last_yaw = {}
  	last_yaw[start] = starting_yaw
  	local reached_goal = false
  	local timed_out = false
  	local frame_timer = Timer()
  	local goal_position = goal.position
  	local timeout = 2000
  	if priority == PathPriority.Medium then
  		timeout = 3000
  	elseif priority == PathPriority.High then
  		timeout = 5000
  	end
  	local reason = nil

  	local bidirectional = TraverseType.BIDIRECTIONAL

  	while not frontier:Empty() do

  		if time_so_far > timeout then
  			-- safeguard for infinite loops
  			reason = 'timeout'
  			timed_out = true
  			break
  		end

  		if not entity then
  			print('break, entity nil')
  			reason = 'entity invalid'
  			break
  		end

  		local frame_limit = time_left
   		local current = frontier:Get()[1]
	   	
   		if current == goal then
   			-- we've reached our goal
   			reached_goal = true
   			if came_from[goal] == nil then
   				came_from[goal] = previous
   			end
   			break
   		end

	   	local parent = came_from[current]

	   	local current_traverse_type = current.info.traverse_type or nil
	   	local current_position = current.position

   		for _,next in ipairs( current.neighbours ) do
   			local next_yaw = next.yaw
   			local next = GetNodeById(next.id, type)

   			if next then
   				local n_position = next.position
   				local next_traverse_type = next.info.traverse_type or nil
	   			local new_cost = cost_so_far[current] + Heuristic.EUCLIDIAN( current_position, n_position ) -- current , next
	   			if current_traverse_type and next_traverse_type then
		   			if current_traverse_type == bidirectional and next_traverse_type == bidirectional then
			   			-- only add sharp cornering expense on two way streets
			   			local parent_yaw = last_yaw[parent]
			   			if parent_yaw then
				   			local yaw_diff = DegreesDifference( next_yaw, parent_yaw )
				   			if yaw_diff and yaw_diff > 170 then 
				   				new_cost = new_cost + 500 
				   			end
				   		end
			   		end
			   	end

	   			local next_cost = cost_so_far[next]
	   			if next_cost == nil or new_cost < next_cost then
	   				cost_so_far[next] = new_cost

	   				local priority = new_cost + Heuristic.EUCLIDIAN( n_position, goal_position )
	   				frontier:Put( next, priority )
	   				came_from[next] = current
	   				previous = current
	   				last_yaw[next] = next_yaw

					local running_time = tGetMS(frame_timer)
					if running_time > frame_limit then
						time_so_far = time_so_far + running_time
						frame_timer:Restart()
						coroutine.yield()
					end
		   		end
	   		end
   		end
   	end

   	if reached_goal then
	   	came_from = ReconstructPath( came_from, start, goal, last_yaw, frame_timer )
		table.insert( GeneratedPaths, { entity = entity, success = true, start = start, goal = goal, path = came_from, type = type } )
	else
		table.insert( GeneratedPaths, { entity = entity, success = false, reason = reason } )
	end

	frontier = nil
	came_from = nil
   	cost_so_far = nil
  	last_yaw = nil
end

function GetYawDifference( next_yaw, last_yaw )
	if not next_yaw or not last_yaw or next_yaw == 0 or last_yaw == 0 then
		return nil, nil
	end

	local a0 = Angle( rad(next_yaw), 0, 0 )
	local a1 = Angle( rad(last_yaw), 0, 0 )

	local deltaRotation = ( a1 * a0:Inverse() )

	return deg(abs( deltaRotation.yaw )), a0
end

function ReconstructPath( came_from, start, goal, yaw_table, frame_timer )
	-- previously returned just position, now returning entire node
	local current = goal
	local path = { { position = current.position, id = current.id, yaw = yaw_table[current] } }
	local previous = nil
	local time_out = Timer()
	local frame_limit = time_left
	local insert = table.insert

	while current ~= start do

		local running_time = tGetMS(frame_timer)
		if running_time > frame_limit then
			frame_timer:Restart()
			coroutine.yield()
		end

		current = came_from[current]
		if current == nil then
			break
		end
		if time_out:GetSeconds() > 5 then
			-- time out
			print('ReconstructPath timeout')
			break
		end
		if previous ~= nil and came_from[current] == came_from[previous] then
			-- skip
		else
			insert( path, { position = current.position, id = current.id, yaw = yaw_table[current] } )
			previous = current
		end
	end
	-- table.insert(path, {position = start.position, id = start.id, yaw = yaw_table[start]})
	return path
end

function GetNodeFromPosition( position, type )
	local t = Maps[type]

	for _,node in pairs(t) do
		if node.position == position then
			return node
		end
	end
	return nil
end

function GetNodeById( id, type )
	local t = Maps[type]

	return t[id]
end

function GetClosestNode( position, type )
	-- takes position, returns node
	
	local x, y = GetCellXYFromPosition( position )

	local connected_cells = GetNearbyCells( x, y )
	local last_dist = 10000
	local last_node = nil
	local yDiff = 200

	for i=1,#connected_cells do
		local connected_cell = connected_cells[i]
		if connected_cell and connected_cell.nodes then
			local t = connected_cell.nodes[type]
			if t then
				for j=1,#t do
					local node = t[j]
					local n_position = node.position
					local dist = position:Distance( n_position )
					if dist <= last_dist then
						local y_diff = abs(position.y - n_position.y)
						if y_diff <= yDiff then
							last_node = node
							last_dist = dist

							if dist < 1.5 then
								return node
							end
						end
					end
				end
			end
		end
	end

	if last_node then
		return last_node
	end

	-- old fallback

	local timer = Timer()
	t = Maps[type]

	local last_dist = 10000
	local last_node = nil
	for _,node in pairs(t) do

		local dist = position:Distance( node.position )
		if dist <= last_dist then
			last_node = node
			last_dist = dist

			if dist < 1.5 then
				return node
			end
		end
	end

	return last_node
end

Heuristic = {}

function Heuristic.MANHATTAN( a, b )
	local dx = abs(a[1] - b[1])
	local dy = abs(a[3] - b[3])
	return (dx + dy) 
end

function Heuristic.EUCLIDIAN( a, b )
	-- local dx = a.x - b.x
	-- local dy = a.z - b.z
	-- local result = sqrt(dx*dx+dy*dy)
	return a:Distance(b)
end

function Heuristic.DIAGONAL( a, b )
	local dx = abs(a[1] - b[1])
	local dy = abs(a[3] - b[3])	
	return math.max(dx,dy)
end

function Heuristic.CARDINTCARD( a, b )
	local dx = abs(a[1] - b[1])
	local dy = abs(a[3] - b[3])	
    return min(dx,dy) * sqrt(2) + math.max(dx,dy) - min(dx,dy)
end

request_timer = Timer()
function LoadRequestedMeshPathsCells()
	if request_timer:GetMilliseconds() < 250 then return end
	request_timer:Restart()

	local i = 1
	while i<= #RequestedPaths do
		local info = RequestedPaths[i]
		local start_x = 0
		local start_y = 0
		local start_cell = nil

		if info.from.__type == 'Vector3' then
			start_x, start_y, start_cell = GetMeshCellFromPosition( info.from )
		else
			start_x, start_y, start_cell = GetMeshCellFromPosition( info.from.position )
		end

		if not IsCellLoaded( start_x, start_y ) then
			if not IsCellLoading( start_x, start_y ) then
				LoadCell( start_x, start_y )
			end
		end
		local x = nil
		local y = nil
		if info.to.__type == 'Vector3' then
			x, y = GetMeshCellFromPosition( info.to )
		else
			x, y = GetMeshCellFromPosition( info.to.position )
		end

		if not IsCellLoaded( x, y ) then
			if not IsCellLoading( x, y ) then
				LoadCell( x, y )
			end
			i = i + 1
		else
			if x and y then
				if info.from.__type == 'Vector3' then
					info.from = MeshCellGetClosestNodeToPosition( start_x, start_y, info.from )
				end
				if info.to.__type == 'Vector3' then
					info.to = MeshCellGetClosestNodeToPosition( x, y, info.to )
				end
				if info.from and info.to and info.entity then
					local co = coroutine.create( MeshSearch )
					local success, error_msg = coroutine.resume( co, info.from, info.to, info.entity, info.type, info.priority, info.starting_yaw, start_cell )
					if not success then
						error(error_message)
					end
					if info.priority == PathPriority.High then
						table.insert( CurrentPaths.High, co )
					elseif info.priority == PathPriority.Medium then
						table.insert( CurrentPaths.Medium, co )
					else
						table.insert( CurrentPaths.Low, co )
					end
					table.remove( RequestedPaths, i )
				else
					-- path generation failed
					table.insert( GeneratedPaths, { entity = info.entity, success = false, reason = 'start or end invalid' } )
					table.remove( RequestedPaths, i )
				end
			else
				table.remove( RequestedPaths, i )
			end
		end
	end
end

function GlobalPathsTick()

	local remove = table.remove
	local status = coroutine.status
	local resume = coroutine.resume

	-- hand back paths generated in previous frame
	local i = 1
	while i <= #GeneratedPaths do
		local path = GeneratedPaths[i]
		local entity = path.entity

		if entity then
			-- entity valid, hand back path and cleanup
			if path.success then
				if entity.PathSuccess then
					entity:PathSuccess( path )
				end
			else
				if entity.PathFailed then
					entity:PathFailed( path.reason )
				end
			end
			remove( GeneratedPaths, i )
		else
			-- entity invalid, remove path
			remove( GeneratedPaths, i )
		end
	end 

	-- trickle down system, no medium paths while a high path exists
	-- no low paths while a medium path exists
	-- max of 1 of any type of path being generated at once

	local frame_timer = Timer()
	local i = 1
	while i <= #CurrentPaths.High do
		local elapsed_ms = tGetMS(frame_timer)
		UpdateFrameTime( elapsed_ms )
		frame_timer:Restart()
		if time_left <= 0 then return end
		local co = CurrentPaths.High[i]
		if status( co ) == 'dead' then
			-- cleanup
			remove( CurrentPaths.High, i )
		else
			local success, error_msg = resume( co )
			if not success then
				error(error_msg)
			end
			i = i + 1	
		end
	end

	if #CurrentPaths.High > 0 then return end

	local i = 1
	while i <= #CurrentPaths.Medium do
		local elapsed_ms = tGetMS(frame_timer)
		UpdateFrameTime( elapsed_ms )
		frame_timer:Restart()
		if time_left <= 0 then return end
		local co = CurrentPaths.Medium[i]
		if status( co ) == 'dead' then
			-- cleanup
			remove( CurrentPaths.Medium, i )	
		else
			local success, error_msg = resume( co )
			if not success then
				error(error_msg)
			end
			i = i + 1
		end
	end

	if #CurrentPaths.Medium > 0 then return end

	local i = 1
	while i <= #CurrentPaths.Low do
		local elapsed_ms = tGetMS(frame_timer)
		UpdateFrameTime( elapsed_ms )
		frame_timer:Restart()
		if time_left <= 0 then return end
		local co = CurrentPaths.Low[i]
		if status( co ) == 'dead' then
			-- cleanup
			remove( CurrentPaths.Low, i )	
		else
			-- if i < max_concurrent_paths then
				local success, error_msg = resume( co )
				if not success then
					error(error_msg)
				end
			-- end
			i = i + 1
		end
	end
end

Console:Subscribe( 'paths', function( ... )
	print( 'RequestedPaths: ', #RequestedPaths )
	print( 'High Priority Paths: ', #CurrentPaths.High )
	print( 'Medium Priority Paths: ', #CurrentPaths.Medium )
	print( 'Low Priority Paths: ', #CurrentPaths.Low )
	print( 'GeneratedPaths: ', #GeneratedPaths )
end )