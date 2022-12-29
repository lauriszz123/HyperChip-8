return {
	devices = {};
	current = -1;
	setCPU = function( self, cpu )
		self.cpu = cpu
	end;
	registerDevice = function( self, deviceName, device )
		self.devices[ #self.devices + 1 ] = {
			name = deviceName,
			device = device
		} 
		local id = #self.devices

		print( "Registered: ", deviceName, "[ID:"..(id or "nil").."]" )
		return id
	end;
	removeDevice = function( self, id )
		table.remove( self.devices, id )
	end;
	setCurrentDevice = function( self, deviceId )
		if self.devices[ deviceId ] then
			self.current = id
		end
	end;
	addEvent = function( self, deviceId, instruction, value )
		if self.devices[ deviceId ] then
			self.devices[ deviceId ].device:addEvent( instruction, value )
		else
			print( "No Device:", deviceId )
		end
	end;
	handle = function( self )
		for i=1, #self.devices do
			self.devices[ i ].device:handle()
		end
	end;
}