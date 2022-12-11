local strf = string.format
local DIGIT = 4

local function opToText( n1, n2 )
	local opcode = bit.bor( bit.lshift( n1, 8 ), n2 )

	local inst = bit.band( opcode, 0xF000 )
	local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local byte = bit.band( opcode, 0x00FF )
    local y = bit.rshift( bit.band( opcode, 0x00F0 ), DIGIT )
	local address = bit.band( opcode, 0x0FFF )
	local op = bit.band( opcode, 0x000F )
	local nibble = op

	if inst == 0x0000 then
	    if address == 0x0000 then
	    	return "HLT"
	    -- HCE - Turn On HyperChip-8
	    elseif address == 0x00E1 then
	    	return "HCE"
	    -- LOW - Turn off HyperChip-8
	    elseif address == 0x00E2 then
	        return "LOW"
	    -- CLS
	    elseif address == 0x00E0 then
	    	return "CLS"
	    -- RET
	    elseif address == 0x00EE then
	        return "RET"
	    elseif address >= 0x00F0 and address <= 0x0CA0 then
	        -- SYSTEM CALLS PRE DEFINED
	        return "SYSCALL"
	    elseif address == 0x0CA1 then
	        return "CALL I"
	    end
	elseif inst == 0x1000 then
		return "JP "..strf( "%03x", address )
	elseif inst == 0x2000 then
		return "CALL "..strf( "%03x", address )
	elseif inst == 0x3000 then
		return "SE V" .. strf( "%01x", x ) .. ", "..strf( "%02x", byte )
	elseif inst == 0x4000 then
		return "SNE V" .. strf( "%01x", x ) .. ", "..strf( "%02x", byte )
	elseif inst == 0x5000 then
		return "SE V" .. strf( "%01x", x ) .. ", V"..strf( "%02x", y )
	elseif inst == 0x6000 then
		return "LD V" .. strf( "%01x", x ) .. ", "..strf( "%02x", byte )
	elseif inst == 0x7000 then
		return "ADD V" .. strf( "%01x", x ) .. ", "..strf( "%02x", byte )
	elseif inst == 0x8000 then
		-- LD Vx, Vy
	    if op == 0x0 then
	        return "LD V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- OR Vx, Vy
	    elseif op == 0x1 then
	        return "OR V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- AND Vx, Vy
	    elseif op == 0x2 then
	        return "AND V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- XOR Vx, Vy
	    elseif op == 0x3 then
	        return "XOR V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- ADD Vx, Vy
	    elseif op == 0x4 then
	        return "ADD V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- SUB Vx, Vy
	    elseif op == 0x5 then
	        return "SUB V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- SHR Vx
	    elseif op == 0x6 then
	        return "SHR V"..strf( "%01x", x )
	    -- SUBN Vx, Vy
	    elseif op == 0x7 then
	        return "SUBN V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- MUL Vx, Vy
	    elseif op == 0x8 then
	        return "MUL V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- DIV Vx, Vy
	    elseif op == 0x9 then
	        return "DIV V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- POW Vx, Vy
	    elseif op == 0xA then
	        return "POW V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- MOD Vx, Vy
	    elseif op == 0xB then
	        return "MOD V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- NSET Vx, Vy
	    elseif op == 0xC then
	        return "NSET V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- SET Vx, Vy
	    elseif op == 0xD then
	        return "SET V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    -- SHL Vx
	    elseif op == 0xE then
	        return "SHL V"..strf( "%01x", x )
	    -- LDI Vx, Vy
	    elseif op == 0xF then
	    	return "LDI V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	    end
	elseif inst == 0x9000 then
		return "SNE V"..strf( "%01x", x )..", V"..strf( "%01x", y )
	elseif inst == 0xA000 then
		return "LD I, "..strf( "%03x", addr )
	elseif inst == 0xB000 then
		return "JP V0, "..strf( "%03x", addr )
	elseif inst == 0xC000 then
		return "RND V"..strf( "%01x", x )..", "..strf( "%02x", byte )
	elseif inst == 0xD000 then
		-- DRW Vx, Vy, nibble( Vz[command] )
		return "DRW V"..strf( "%01x", x )..", V"..strf( "%01x", y )..", "..strf( "%01x", nibble )
	elseif inst == 0xE000 then
		-- SKP Vx
	    if byte == 0x9E then
	    	return "SKP V"..strf( "%01x", x )
	    -- SKPN Vx
	    elseif byte == 0xA1 then
	    	return "SKPN V"..strf( "%01x", x )
	    end
	elseif inst == 0xF000 then
		if byte == 0x00 then
	    	return "PUSH V"..strf( "%01x", x )
	    -- POP Vx
	    elseif byte == 0x01 then
	    	return "POP V"..strf( "%01x", x )
	    -- NGET Vx
	    elseif byte == 0x02 then
	        return "NGET V"..strf( "%01x", x )
	    -- GET Vx
	    elseif byte == 0x03 then
	        return "GET V"..strf( "%01x", x )
	    -- FLUSH Vx
	    elseif byte == 0x04 then
	        return "FLUSH V"..strf( "%01x", x )
	    -- LD Vx, DT
	    elseif byte == 0x07 then
	        return "LD V"..strf( "%01x", x )..", DT"
	    -- LD Vx, K
	    elseif byte == 0x0A then
	    	return "LD V"..strf( "%01x", x )..", K"
	    -- LD DT, Vx
	    elseif byte == 0x15 then
	        return "LD DT, V"..strf( "%01x", x )
	    -- LD ST, Vx
	    elseif byte == 0x18 then
	        return "LD ST, V"..strf( "%01x", x )
	    -- ADD I, Vx
	    elseif byte == 0x1E then
	        return "ADD I, V"..strf( "%01x", x )
	    -- LD F, Vx
	    elseif byte == 0x29 then
	        return "LD F, V"..strf( "%01x", x )
	    -- LD B, Vx
	    elseif byte == 0x33 then
	        return "LD B, V"..strf( "%01x", x )
	    -- LD [I], Vx
	    elseif byte == 0x55 then
	        return "LD [I], V"..strf( "%01x", x )
	    -- LD Vx, [I]
	    elseif byte == 0x65 then
	        return "LD V"..strf( "%01x", x )..", [I]"
	    end
	end

	return "UNKN"
end

return {
	convert = opToText;
}