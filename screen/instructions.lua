return {
	[ 0 ] = function( self, value )
		self:clear()
	end;
	[ 1 ] = function( self, value )
		self.termX = value
	end;
	[ 2 ] = function( self, value )
		self.termY = value
	end;
	[ 3 ] = function( self, value )
		lgp( string.char( value ), self.termX * 4, self.termY * 6 )
	end;
}