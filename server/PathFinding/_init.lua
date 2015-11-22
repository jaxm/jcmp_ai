-- all map loading / pathfinding global defines go here

-- load speed configuration
-- these variables change how quickly the script will try
-- to load the maps provided
-- reduce these numbers if you experience lockups on script load
-- IMPORTANT: these variables only effect load speed,
-- not path generation time.
maxLoadCalcPerFrame = 1000

-- globals

Maps = {}
Maps_id = {}
MapsLoading = {}
SpawnList = {}
bMapLoaded = false
map_load_event_tick = nil
CurrentPaths = {
	Low = {},
	Medium = {},
	High = {}
}

-- A*

FooTuple = require("TupleCache")
BinaryHeap = require("BinaryHeap")