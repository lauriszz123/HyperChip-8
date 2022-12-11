--------------------------------------------------
-- Name: tokenize
--
-- Arguments:
--	input - wrapper file input
--
-- Description: tokenize a file from a string
-- to token objects.
--------------------------------------------------
local function tokenize( input )

	-- Check if a charachter contains word charachters and underscore
	local function isWord( v )
		return v:find( "[a-zA-Z_]" ) ~= nil
	end

	-- A whole word which also has numbers
	local function word( v )
		return v:find( "[a-zA-Z_0-9]" ) ~= nil
	end

	-- Check if a a charachter is a number
	local function isNumber( v )
		return v:find( "[0-9]" ) ~= nil
	end

	-- Check if a charachter is a whitespace
	local function isWhitespace( v )
		return v:find( "[ \n\t\r]" ) ~= nil
	end

	-- Check if a charachter is a precedence?
	local function isPrec( v )
		return v:find( "[:%(%);,%{%}]" ) ~= nil
	end

	-- Check if a charachter is an operator
	local function isOp( v )
		return v:find( "[%+%-%*/%^%%<!=>]" ) ~= nil
	end

	-- do while loops until a certain charachter is met.
	local function doWhile( f )
		local str = ""
		while input.eof() == false and f( input.peek() ) do
			str = str .. input.next()
		end
		return str
	end

	-- Magic
	-- Create tokens from charachters
	local function n()
		doWhile( isWhitespace )
		local peek = input.peek()
		if peek == "" or peek == nil or input.eof() then
			return
		end
		if isWord( peek ) then
			return {
				type = "id";
				value = doWhile( word );
			}
		elseif isNumber( peek ) then
			return {
				type = "num";
				value = doWhile( isNumber );
			}
		elseif isPrec( peek ) then
			return {
				type = "prec";
				value = input.next();
			}
		elseif isOp( peek ) then
			return {
				type = "op";
				value = doWhile( isOp );
			}
		else
			error( "Line:"..input.getLine()..": Tokenizing error.", 0 )
		end
	end

	-- Object related stuff
	local ptr = nil
	local function _next()
		if ptr then
			local v = ptr
			ptr = nil
			return v
		else
			return n()
		end
	end

	local function p()
		if ptr == nil then
			ptr = n()
			return ptr
		else
			return ptr
		end
	end

	-- Return the object
	return {
		-- This is a hacky way to remove 'self' object.
		next = _next;
		peek = p;
		eof = function()
			return input.eof() and p() ~= nil
		end;
		error = function( msg )
			error( "Line:"..input.getLine()..": "..msg, 0 )
		end;
		getLine = input.getLine;
	}
end

return {
	tokenize = function( wrapper )
		return tokenize( wrapper )
	end;
}