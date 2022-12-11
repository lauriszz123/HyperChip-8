--------------------------------------------------
-- Name: wrapper
--
-- Arguments:
--	file - whole file as a string, that
--			is already read.
--
-- Description: Wrap file contents into an object
-- for simpler tokenization.
--------------------------------------------------
local function wrapper( file )

	-- Add a new-line for bug fixing
	file = file .. "\n"
	local i = 1
	local line = 1
	return {
		peek = function()
			return file:sub( i, i )
		end;
		next = function()
			local v = file:sub( i, i )
			i = i + 1
			if v == "\n" then
				line = line + 1
			end
			return v
		end;
		eof = function()
			return i >= #file
		end;
		getLine = function()
			return line
		end;
	}
end

return {
	eatFile = function( file )
		return wrapper( file )
	end;
}