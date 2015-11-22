class 'WNOInterface'

function WNOInterface:__init( ... )
	self.object_stream_in = Events:Subscribe( 'WorldNetworkObjectCreate', self, self.Create )
	self.object_stream_out = Events:Subscribe( 'WorldNetworkObjectDestroy', self, self.Destroy )
	self.object_value_change = Events:Subscribe( 'NetworkObjectValueChange', self, self.ValueChange )

	self.type_register = {}
	self.type_register['Actor'] = AM -- ActorManager
	self.type_register['Entity'] = EM -- EntityManager
	self.type_register['Object'] = OM -- ObjectManager
	self.type_register['VehicleObject'] = VOM -- VehicleObjectManager
end

function WNOInterface:Create( e )
	local object = e.object
	local type = object:GetValue( 'type' )
	-- if there's no type, its probably for an object we dont care about
	if not type then return end

	local manager = self.type_register[type]	

	if manager then
		-- call manager function to handle this event
		manager:WorldNetworkObjectCreate( e )
	end
end

function WNOInterface:Destroy( e )
	local object = e.object
	local type = object:GetValue( 'type' )
	-- if there's no type, its probably for an object we dont care about
	if not type then return end

	local manager = self.type_register[type]

	if manager then
		-- call manager function to handle this event
		manager:WorldNetworkObjectDestroy( e )
	end
end

function WNOInterface:ValueChange( e )
	local object = e.object
	local type = object:GetValue( 'type' )
	-- if there's no type, its probably for an object we dont care about
	if not type then return end

	local manager = self.type_register[type]

	if manager then
		-- call manager function to handle this event
		manager:NetworkObjectValueChange( e )
	end
end

WNOI = WNOInterface()