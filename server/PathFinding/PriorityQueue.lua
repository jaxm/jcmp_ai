class 'PriorityQueue'

function PriorityQueue:__init( ... )
	self.elements = {}
	self.heap = BinaryHeap( function(a,b)
		return a[2] < b[2]
	 end )
end

function PriorityQueue:Empty( ... )
	return self.heap:empty()
end

function PriorityQueue:Put( item, priority )
	self.heap:add( FooTuple( item, priority ), self.elements ) 
end

function PriorityQueue:Get( ... )
	local result = self.heap:pop()
	local tuple, priority = result()
	return tuple
end