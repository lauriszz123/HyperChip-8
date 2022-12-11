local instructionSize = require "lang.assembler.instructionSize"

local pc = 0x200
local labels = {}
local aliases = {}
local function interpret( tokens )
	pc = 0x200
	local i = 1
	while i <= #tokens do
		if tokens[ i ]:sub( 1, 1 ) == ":" then
			labels[ tokens[ i ]:sub( 2 ) ] = pc
			print( tokens[ i ]:sub( 2 ), pc )
			table.remove( tokens, i )
		elseif tokens[ i ]:upper() == "ALIAS" then
			table.remove( tokens, i )
			local alias = table.remove( tokens, i )
			aliases[ alias ] = table.remove( tokens, i )
		elseif tokens[ i ]:upper() == "DB" then
			i = i + 1
			local count = tonumber( tokens[ i ] )
			pc = pc + count
			i = i + (count + 1)
		else
			local instruction = tokens[ i ]:upper()
			if instructionSize[ instruction ] then
				if instruction == "JP" then
					if tokens[ i + 1 ]:upper() == "V0" then
						i = i + instructionSize[ instruction ] + 1
					else
						i = i + instructionSize[ instruction ]
					end
				else
					i = i + instructionSize[ instruction ]
				end
				pc = pc + 2
			else
				error( "Unknown Instruction! ["..instruction.."]", 0 )
			end
		end
	end
end

return {
	runThrough = function( tokens )
		interpret( tokens )
		return labels, aliases
	end;
}