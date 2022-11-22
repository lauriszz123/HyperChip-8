-- Author: Laurynas Suopys (lauriszz123)
--
-- Description:
-- A simple assembler built for HyperChip-8

local function tokenize( name )
	local file, size = love.filesystem.read( name )
	local word = ""
	local tokens = {}
	for i=1, #file do
		local c = file:sub( i,i )
		if c:find( "[ \t\r\n,]" ) ~= nil then
			if #word > 0 then
				tokens[ #tokens + 1 ] = word
				word = ""
			end
		elseif c == ":" then
			if #word > 0 then
				tokens[ #tokens + 1 ] = ":"..word
				word = ""
			end
		else
			word = word .. c
		end
	end
	if #word > 0 then
		tokens[ #tokens + 1 ] = word
		word = ""
	end
	return tokens
end

local INSTRUCTIONS = {
	[ "CLS" ] = 1;
	[ "RET" ] = 1;
	[ "JP" ] = 2;
	[ "CALL" ] = 2;
	[ "SE" ] = 3;
	[ "SNE" ] = 3;
	[ "LD" ] = 3;
	[ "ADD" ] = 3;
	[ "OR" ] = 3;
	[ "AND" ] = 3;
	[ "XOR" ] = 3;
	[ "SUB" ] = 3;
	[ "SUBN" ] = 3;
	[ "SHR" ] = 2;
	[ "SHL" ] = 2;
	[ "RND" ] = 3;
	[ "DRW" ] = 4;
	[ "SKP" ] = 2;
	[ "SKNP" ] = 2;
	[ "LDI" ] = 3;
	[ "PUSH" ] = 2;
	[ "POP" ] = 2;
}

local pc = 0x200
local labels = {}
local function pre( tokens )
	pc = 0x200
	local i = 1
	while i <= #tokens do
		if tokens[ i ]:sub( 1, 1 ) == ":" then
			labels[ tokens[ i ]:sub( 2 ) ] = pc
			table.remove( tokens, i )
		else
			local instruction = tokens[ i ]:upper()
			if INSTRUCTIONS[ instruction ] then
				if instruction == "JP" then
					if tokens[ i + 1 ]:upper() == "V0" then
						i = i + INSTRUCTIONS[ instruction ] + 1
					else
						i = i + INSTRUCTIONS[ instruction ]
					end
				else
					i = i + INSTRUCTIONS[ instruction ]
				end
				pc = pc + 2
			else
				error( "Unknown Instruction! ["..instruction.."]", 0 )
			end
		end
	end
end

local DIGIT = 4
local INSTRUCTIONS_COMPILE = {
	[ "CLS" ] = function( prog )
		prog:push( 0x00E0 )
	end;
	[ "RET" ] = function( prog )
		prog:push( 0x00EE )
	end;
	[ "JP" ] = function( prog, addr, reg )
		addr = tonumber( addr )
		local inst = 0
		if reg then
			inst = bit.bor( 0xB000, addr )
		else
			inst = bit.bor( 0x1000, addr )
		end

		prog:push( inst )
	end;
	[ "CALL" ] = function( prog, addr )
		addr = tonumber( addr )
		local inst = bit.bor( 0x2000, addr )
		prog:push( inst )
	end;
	[ "SE" ] = function( prog, vx, vy )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		if vy:sub( 1, 1 ):upper() == "V" then
			local inst = 0x5000
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )

			inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bot( inst, bit.lshift( vy, DIGIT ) )

			prog:push( inst )
		else
			local inst = 0x3000
			vy = tonumber( vy )

			inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bot( inst, vy )

			prog:push( inst )
		end
	end;
	[ "SNE" ] = function( prog, vx, vy )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		if vy:sub( 1, 1 ):upper() == "V" then
			local inst = 0x9000
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )

			inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bot( inst, bit.lshift( vy, DIGIT ) )

			prog:push( inst )
		else
			local inst = 0x4000
			vy = tonumber( vy )

			inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bot( inst, vy )

			prog:push( inst )
		end
	end;
	[ "LD" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "I" then
			local inst = 0xA000
			if labels[ vy ] then
				vy = labels[ vy ]
			else
				vy = tonumber( vy )
			end
			inst = bit.bor( inst, vy )
			prog:push( inst )
		elseif vx:upper() == "DT" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF015, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		elseif vx:upper() == "ST" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF018, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		elseif vx:upper() == "F" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF029, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		elseif vx:upper() == "B" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF033, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		elseif vx:upper() == "I" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF055, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		else
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			if vy:sub( 1, 1 ):upper() == "V" then
				vy = tonumber( "0x"..vy:sub( 2, 2 ) )
				local inst = bit.bor( 0x8000, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bot( inst, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			elseif vy:upper() == "DT" then
				local inst = bit.bor( 0xF007, bit.lshift( vx, DIGIT * 2 ) )
				prog:push( inst )
			elseif vy:upper() == "K" then
				local inst = bit.bor( 0xF00A, bit.lshift( vx, DIGIT * 2 ) )
				prog:push( inst )
			elseif vy:upper() == "I" then
				local inst = bit.bor( 0xF065, bit.lshift( vx, DIGIT * 2 ) )
				prog:push( inst )
			else
				local inst = bit.bor( 0x6000, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, tonumber( vy ) )
				prog:push( inst )
			end
		end
	end;
	[ "ADD" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8004, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8004, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			else
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( vy )
				local inst = bit.bor( 0x7000, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, tonumber( vy ) )
				prog:push( inst )
			end
		elseif vx == "I" then
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0xF01E, bit.lshift( vy, DIGIT * 2 ) )
			prog:push( inst )
		end
	end;
	[ "OR" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8004, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "AND" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8002, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "XOR" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8003, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "SUB" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8005, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "SUBN" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8007, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "SHR" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x8006, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "SHL" ] = function( prog, vx, vy )
		if vx:sub( 1, 1 ):upper() == "V" then
			if vy:sub( 1, 1 ):upper() == "V" then
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				vy = tonumber( "0x"..vx:sub( 2, 2 ) )
				local inst = bit.bor( 0x8001, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( 0x800E, bit.lshift( vy, DIGIT ) )
				prog:push( inst )
			end
		end
	end;
	[ "RND" ] = function( prog, vx, kk )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		kk = tonumber( kk )

		local inst = bit.bor( 0xC000, bit.lshift( vx, DIGIT * 2 ) )
		inst = bit.bot( inst, vy )

		prog:push( inst )
	end;
	[ "DRW" ] = function( prog, vx, vy, n )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		local vy = tonumber( "0x"..vy:sub( 2, 2 ) )
		local n = tonumber( n )

		local inst = bit.bor( 0xD000, bit.lshift( vx, DIGIT * 2 ) )
		inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
		inst = bit.bor( inst, n )
		prog:push( inst )
	end;
	[ "SKP" ] = function( prog, vx )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		local inst = bit.bor( 0xE09E, bit.lshift( vx, DIGIT * 2 ) )
		prog:push( inst )
	end;
	[ "SKNP" ] = function( prog, vx )
		local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		local inst = bit.bor( 0xE0A1, bit.lshift( vx, DIGIT * 2 ) )
		prog:push( inst )
	end;
	[ "LDI" ] = function( prog, vx, vy )
		vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		vy = tonumber( "0x"..vy:sub( 2, 2 ) )
		local inst = bit.bor( 0x800F, bit.lshift( vx, DIGIT * 2 ) )
		inst = bit.bot( inst, bit.lshift( vy, DIGIT ) )
		prog:push( inst )
	end;
	[ "PUSH" ] = function( prog, vx )
		vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		local inst = bit.bor( 0xF000, bit.lshift( vx, DIGIT * 2 ) )
		prog:push( inst )
	end;
	[ "POP" ] = function( prog, vx )
		vx = tonumber( "0x"..vx:sub( 2, 2 ) )
		local inst = bit.bor( 0xF001, bit.lshift( vx, DIGIT * 2 ) )
		prog:push( inst )
	end;
}

local function compile( tokens )
	local prog = {
		push = function( self, inst )
			local a = bit.rshift( bit.band( inst, 0xFF00 ), DIGIT * 2 )
			local b = bit.band( inst, 0x00FF )
			table.insert( self, a )
			table.insert( self, b )
		end;
	}
	while #tokens > 0 do
		local inst = table.remove( tokens, 1 )
		local isReg = false
		if INSTRUCTIONS_COMPILE[ inst ] then
			local args = {}
			for i=1, INSTRUCTIONS[ inst ] - 1 do
				args[ #args + 1 ] = table.remove( tokens, 1 )
			end

			for i=1, #args do
				if args[ i ]:sub( 1, 1 ):upper() == "V" then
					if inst == "JP" then
						isReg = true
					end
				elseif labels[ args[ i ] ] then
					args[ i ] = labels[ args[ i ] ]
				end
			end

			if isReg == true then
				table.remove( args, 1 )
				local arg = table.remove( tokens, 1 )

				if labels[ arg ] then
					arg = labels[ arg ]
				else
					arg = tonumber( arg )
				end

				args[ #args + 1 ] = arg
				args[ #args + 1 ] = true
			end

			INSTRUCTIONS_COMPILE[ inst ]( prog, unpack( args ) )
		end
	end

	return prog
end

return {
	compile = function( inp, out )
		local toks = tokenize( inp )
		pre( toks )
		local prog = compile( toks )

		local file, errorstr = love.filesystem.newFile( out )
		if errorstr then print( errorstr ) end
		file:open( "w" )
		for i=1, #prog do
			file:write( string.char( prog[ i ] ), 1 )
		end
		file:close()
		file:release()

		return prog
	end;
}