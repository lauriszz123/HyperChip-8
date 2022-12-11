-- Output object that pushes asm code
local function output()
	return {

		-- Make ASM code pretty with concatination
		push = function( self, ... )
			local topush = { ... }
			local args = table.concat( topush, ", ", 2 )
			self[ #self + 1 ] = topush[ 1 ].." "..args
		end;
		pop = function( self )
			local v = self[ #self ]
			self[ #self ] = nil
			return v
		end;
	}
end

return {
	create = function()
		return output()
	end;
}