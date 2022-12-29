local lgp = love.graphics.print
local localScreen = {}

local instructions = require "screen.instructions"

return {
	create = function( w, h, s, deviceManager )
		return {
			mode = 0;
			width = w;
			height = h;
			scale = s;
			events = {};
			termX = 0;
			termY = 0;
			deviceManager = deviceManager;

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
				end
			end;
			reset = love.graphics.setCanvas;

			clear = function ( self )
				love.graphics.clear( 0, 0, 0 )
				localScreen = {}
				self.termX = 0
				self.termY = 0
			end;

			addEvent = function( self, t, value )
				table.insert( self.events, {
					type = t,
					value = value
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
				while #self.events > 0 do
					local event = table.remove( self.events, 1 )
					instructions[ event.type ]( self, event.value )
				end
			end;

			draw = function( self, x, y )
				if self.canvas then
					love.graphics.draw( self.canvas, x, y, 0, 3, 3 )
				end
			end;
		}
	end;
}