local lgp = love.graphics.print
local localScreen = {}

local switch = {
	[ 0 ] = function( self )
		self:clear()
	end;
}

return {
	create = function( w, h, s )
		return {
			mode = 0;
			width = w;
			height = h;
			scale = s;
			events = {};

			init = function( self )
				self.canvas = love.graphics.newCanvas( self.width, self.height )
				self.canvas:setFilter( "nearest", "nearest" )
				self.font = love.graphics.newFont( "font.ttf", 4 )
				love.graphics.setFont( self.font )
				self.font:setLineHeight( 2 )

				self:set()

				love.graphics.clear( 0, 0, 0 )

				self:reset()

				print( "Screen initiated." )
			end;

			set = function( self )
				if self.canvas then
					love.graphics.setCanvas( self.canvas )
				else
					error( "No canvas created.", 0 )
				end
			end;
			reset = function()
				love.graphics.setCanvas()
			end;

			clear = function ( self )
				love.graphics.clear( 0, 0, 0 )
				localScreen = {}
			end;

			pushEvent = function( self, t, ... )
				table.insert( self.events, {
					type = t,
					args = { ... }
				} )
			end;

			putPixel = function( x, y, on )
				if on then
					love.graphics.setColor( 1, 1, 1 )
					localScreen[ y * 64 + x ] = 1
				else
					love.graphics.setColor( 0, 0, 0 )
					localScreen[ y * 64 + x ] = 0
				end
				love.graphics.points( x, y )
			end;

			getPixel = function( x, y )
				local v = localScreen[ y * 64 + x ]
				return (v == nil or v == 0) and 0 or 1
			end;

			putCharConsole = function( x, y, char )
				lgp( char, x * 4, y * 6 )
			end;

			putChar = function( x, y, char )
				lgp( char, x, y )
			end;

			handle = function( self )
				self:set()
				while #self.events > 0 do
					local event = table.remove( self.events, 1 )
					switch[ event.type ]( self, unpack( event.args ) )
				end
				love.graphics.setCanvas()
			end;

			draw = function( self, x, y )
				love.graphics.draw( self.canvas, x, y, 0, 3, 3 )
			end;
		}
	end;
}