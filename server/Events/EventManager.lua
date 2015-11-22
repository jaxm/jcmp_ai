class 'EventManager'

function EventManager:__init( ... )
	self.active_events = {}
	self.timer = Timer()
	self.event_post_tick = Events:Subscribe( 'PostTick', self, self.Tick )
	self.event_module_load = Events:Subscribe( 'MapsLoaded', self, self.LoadDebug )
end

function EventManager:LoadDebug()

	-- military base test event
	-- local t = {
	-- 	event_type = 'Populate',
	-- 	centerPoint = Vector3( -7747.413574, 203.999985, -6959.811523 ),
	-- 	activateDistance = 500,
	-- 	actors = {
	-- 		{ type = 'CombatGrunt', position = Vector3( -7723.378418, 209.999985, -7012.460449 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7704.593262, 208.884323, -7051.159180 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7686.826172, 208.880722, -7050.500000 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7651.135742, 210.219849, -7034.099121 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7651.875000, 210.196991, -7016.163086 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7741.729004, 218.979019, -7039.564941 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7633.865234, 238.945633, -6916.647461 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7666.199219, 214.699982, -6829.084961 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7681.496094, 210.000015, -6770.031250 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'CombatGrunt', position = Vector3( -7841.692871, 203.999557, -6916.616699 ), angle = Angle(), goal = AiGoal.Guard, faction = Faction.PanauMilitary },
	-- 		{ type = 'MilitaryAPC_Cannon', position = Vector3( -7749.505859, 204.006073, -6962.047363 ), angle = Angle( -0.803231, 0.000000, 0.000000 ), goal = AiGoal.Guard, faction = Faction.PanauMilitary }
	-- 	}
	-- }

	-- self:AddEvent( t )
end

function EventManager:AddEvent( args )
	local event = nil
	if args.event_type == 'Populate' then
		event = PopulateEvent( args )
	elseif args.event_type == 'Heat' then
		event = HeatEvent( args )
	end
	if event then
		table.insert( self.active_events, event )
	else
		error('Error loading event of type :', args.event_type)
	end

	return event
end

function EventManager:RemoveEvent( event )
	local t = self.active_events
	for i=1,#t do
		local e = t[i]
		if e == event then
			e:Remove()
			table.remove( self.active_events, i )
			return
		end
	end
end

function EventManager:Tick( ... )

	local t = self.timer
	if t:GetMilliseconds() < 250 then return end
	t:Restart()

	-- event logic currently runs every 250ms

	local t = self.active_events
	for i=1,#t do
		local event = t[i]

		event:Tick()

	end
end

EM = EventManager()