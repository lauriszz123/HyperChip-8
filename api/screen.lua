local lgp = love.graphics.print
local localScreen = {}

return {
	create = function( w, h, s )
		return {
			width = w;
			height = h;
			scale = s;

			init = function( self )
				local ok = love.window.setMode( self.width * self.scale, self.height * self.scale )
				if not ok then error( "Unable to set up the screen.", 0 ) end
				self.canvas = love.graphics.newCanvas( self.width, self.height )
				self.canvas:setFilter( "nearest", "nearest" )
				self.font = love.graphics.newFont( "font.ttf", 4 )
				love.graphics.setFont( self.font )

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
				love.graphics.clear()
				localScreen = {}
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

			draw = function( self )
				love.graphics.setColor( 1, 1, 1 )
				love.graphics.draw( self.canvas, 0, 0, 0, self.scale, self.scale )
			end;
		}
	end;
}