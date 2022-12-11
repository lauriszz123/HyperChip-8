local instructionToBytecode = require "lang.assembler.instructionToBytecode"
local instructionSize = require "lang.assembler.instructionSize"

local DIGIT = 4

local function compile( tokens, labels, aliases )
	if type( instructionToBytecode ) == "function" then
		instructionToBytecode = instructionToBytecode( aliases )
	end
	local prog = {
		push = function( self, inst )
			local a = bit.rshift( bit.band( inst, 0xFF00 ), DIGIT * 2 )
			local b = bit.band( inst, 0x00FF )
			table.insert( self, a )
			table.insert( self, b )
		end;
		push2 = function( self, byte )
			table.insert( self, byte )
		end;
	}

	local function checkForDot( arg )
		local first, second
		for i=1, #arg do
			local c = arg:sub( i, i )
			if c == '.' then
				first = arg:sub( 1, i - 1 )
				second = arg:sub( i + 1, #arg )
			end
		end
		if second == nil then
			return arg
		end
		return first, second
	end

	local function convert( a, b )
		if b == 'low' then
			return bit.band( a, 0xFF )
		elseif b == 'high' then
			return bit.rshift( bit.band( a, 0xFF00 ), 8 )
		else
			error()
		end
	end

	while #tokens > 0 do
		local inst = table.remove( tokens, 1 ):upper()
		local isReg = false
		if instructionToBytecode[ inst ] then
			local args = {}
			for i=1, instructionSize[ inst ] - 1 do
				args[ #args + 1 ] = table.remove( tokens, 1 )
			end

			for i=1, #args do
				local arg, func = checkForDot( args[ i ] )
				if arg:sub( 1, 1 ):upper() == "V" and #arg == 2 then
					if inst == "JP" then
						isReg = true
					end
				elseif labels[ arg ] then
					if func then
						args[ i ] = convert( labels[ arg ], func )
					else
						args[ i ] = labels[ arg ]
					end
				end
			end

			if isReg == true then
				table.remove( args, 1 )
				local arg, func = checkForDot( table.remove( tokens, 1 ) )

				if labels[ arg ] then
					if func then
						args[ i ] = convert( labels[ arg ], func )
					else
						args[ i ] = labels[ arg ]
					end
				else
					arg = tonumber( arg )
				end

				args[ #args + 1 ] = arg
				args[ #args + 1 ] = true
			end

			--print( inst )
			--print( args )

			instructionToBytecode[ inst ]( prog, unpack( args ) )
		elseif inst:upper() == "DB" then
			local count = tonumber( table.remove( tokens, 1 ) )
			for i=1, count do
				prog:push2( tonumber( table.remove( tokens, 1 ) ) )
			end
		end
	end

	return prog
end

return {
	compile = function( tokens, labels, aliases )
		return compile( tokens, labels, aliases )
	end;
}