return {
	devices = {};
	setCPU = function( self, cpu )
		self.cpu = cpu
	end;
	registerDevice = function( self, deviceName, device )
		local id = table.insert( self.devices, {
			name = deviceName,
			device = device
		} )

		print( "Registered: ", deviceName )
		return id
	end;
	removeDevice = function( self, id )
		table.remove( self.devices, id )
	end;
	addEvent = function( self, deviceId, instruction, value )
		if self.devices[ deviceId ] then
			self.devices[ deviceId ].device:addEvent( instruction, value )
		end
	end;
	handle = function( self )
		for i=1, #self.devices do
			self.devices[ i ].device:handle()
		end
	end;
}