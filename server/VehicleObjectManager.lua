class 'VehicleObjectManager'

function VehicleObjectManager:__init( ... )
	self.vehicles = {}

	self.events = {
		unload = Events:Subscribe( 'ModuleUnload', self, self.CleanupItems )
	}
end

function VehicleObjectManager:CleanupItems( ... )
	for _,vehicle in pairs(self.vehicles) do
		if vehicle and IsValid(vehicle) then
			vehicle:Remove()
		end
	end
end

VOM = VehicleObjectManager()