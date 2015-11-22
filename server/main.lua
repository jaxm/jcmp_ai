-- called from server/pathfinding/MapLoad after all maps have been loaded
function CreateMainPostTickLoop()
	Events:Subscribe( 'PostTick', MainPostTick )
end
total_timer = Timer()
function MainPostTick( e )
	local total_timer = total_timer
	local tGetMS = Timer.GetMilliseconds
	local tRestart = Timer.Restart
	local partial_time = Timer()
	total_timer:Restart()
	time_left = 16.7
	-- agent logic
	SetUnicode(false)
	AM:LogicTick(e)
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)

	if time_left <= 0 then SetUnicode(true) return end
	-- Overseer
	OS:Tick()
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)

	if time_left <= 0 then SetUnicode(true) return end

	-- cell logic
	CellMainLoop(e)
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)

	if time_left <= 0 then SetUnicode(true) return end

	-- mesh loading / processing
	MeshLoadTick()
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)
 
	if time_left <= 0 then SetUnicode(true) return end

	-- A* navigation / path handback
	GlobalPathsTick()
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)

	if time_left <= 0 then SetUnicode(true) return end

	-- agent logic extended
	AM:LogicTickExtended(e)
	UpdateFrameTime( tGetMS(partial_time) )
	tRestart(partial_time)

	SetUnicode(true)

	local total_time = total_timer:GetMilliseconds()
	if total_time < 1 then
		collectgarbage('step', 100)
	end
end

function UpdateFrameTime( time_spent )
	time_left = time_left - time_spent
end