--------------------------------------------------
-- Name: environment
--
-- Arguments:
--	parent - a parent environment object.
--
-- Description: create a variable and function
-- environemnt which can have a parent
-- environment.
--------------------------------------------------
local function environment( parent )
	return {
		parent = parent;
		variables = {};
		localCount = 0;
		define = function( self, tree, varType, value )
			self.variables[ tree.name ] = {
				type = varType,
				value = value
			}
		end;
		lookup = function( self, tree )
			local current = self
			while current ~= nil do
				if current.variables[ tree.name ] then
					return current
				else
					current = current.parent
				end
			end
			error( "Line:"..tree.line..": Variable '"..tree.name.."' not found.", 0 )
		end;
		get = function( self, tree )
			local current = self:lookup( tree )
			return current.variables[ tree.name ]
		end;
	}
end

return {
	new = function( parent )
		return environment( parent )
	end;
}