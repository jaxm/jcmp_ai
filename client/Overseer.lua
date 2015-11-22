class 'Overseer'

function Overseer:__init( ... )
	self.n_event = Network:Subscribe( 'RequestPlayerCalculation', self, self.RequestPlayerCalculation )
end

function Overseer:RequestPlayerCalculation( t )
	local a = t.from
	local b = t.to
	local entityId = t.entityId

	local distance = a:Distance( b )

	local dir = Angle.NormalisedDir( b, a )

	local raycast = Physics:Raycast( a, dir, 0, 1000 )
	local result = false
	if raycast.distance >= distance then
		result = true
	end

	local rTable = { result = result, entityId = entityId }

	Network:Send( 'PlayerCalculationReceive', rTable )
end

OS = Overseer()