
Events:Subscribe( 'ModuleLoad', function( ... )
	-- Map load requests are added here.
	-- id specified is then used when requesting a path to use that map.

	-- LoadMap( filename, id )
	-- SetUnicode(false)
	LoadMap( 'GroundVehicleNavigation', 1 )
	-- 2 is reserved for mesh navigation

	map_load_event_tick = Events:Subscribe( 'PostTick', LoadRequestedMaps )
    
end )

function LoadRequestedMaps( e )

	-- forcing only 1 coroutine at a time might not be required
	-- will revisit this code once i have multiple maps being loaded
	-- i figure it's likely to cause a bottleneck if it's loading 
	-- loads of maps at the same time each frame.

	local i = 1
	while i <= #MapsLoading do
		-- only run 1 coroutine at a time
		if i > 1 then return end

		local co = MapsLoading[i]
		if coroutine.status( co ) == 'dead' then
			-- cleanup
			table.remove( MapsLoading, i )
		else
			SetUnicode( false )
			local success, error_msg = coroutine.resume( co )
			if not success then
				error(error_msg)
			end
			SetUnicode( true )
			i = i + 1	
		end
	end

	-- still loading? return

	if #MapsLoading > 0 then return end

	-- loading complete, allow path requests
	bMapLoaded = true
	print('--> Maps loaded, PathFinding ready! <--')
	CreateMainPostTickLoop()
	Events:Fire( 'MapsLoaded' )
	-- cleanup
	if map_load_event_tick then
		Events:Unsubscribe( map_load_event_tick )
		map_load_event_tick = nil
	end
end

function LoadMap( name, id )
	-- load map from file
	co = coroutine.create( LoadMesh )
	SetUnicode( false )
	local success, error_msg = coroutine.resume( co, name, id )
	if not success then
		error(error_msg)
	end
	SetUnicode( true )
	table.insert( MapsLoading, co )
end

function LoadMesh( path, map_id )
    local msg = require 'MessagePack'

    local file, file_error = io.open( path , "rb" )

    if file_error then 
            error(file_error)
        return
    end

    local temp_table = {}

    if file ~= nil then 
        local data = file:read("*a")
        if data ~= nil then
        	-- data = string.trim( data )
            temp_table = msg.unpack(data)
            file:close()
        end
    end

    local id_table = {}
    local count = 0
    for _,node in pairs(temp_table) do
        node.position = TableToVector3( node.position )

        -- define node properties
        if node.info.sidewalk_left ~= 0 or node.info.sidewalk_right ~= 0 then
        	node.pedestrian_node = true
        end

        -- add node to cell
        local cell_x, cell_y = GetCellXYFromPosition( node.position )

        AddNodeToCell( node, map_id, cell_x, cell_y )

        for i,neighbour in pairs(node.neighbours) do
            neighbour.position = TableToVector3( neighbour.position )
        end
        -- build id map for fast node lookup
        id_table[node.id] = node

        count = count + 1
        if count > maxLoadCalcPerFrame then
			count = 0
			coroutine.yield()
		end
    end

    MapLoaded( temp_table, id_table, map_id )
end

function MapLoaded( map, map_id, id )
	Maps[id] = map
	Maps_id[id] = map_id
end