local DIGIT = 4

return function( aliases )
	return {
		[ "HLT" ] = function( prog )
			prog:push( 0x0000 )
		end;
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
			if addr == "I" then
				prog:push( 0x0CA1 )
			else
				addr = tonumber( addr )
				local inst = bit.bor( 0x2000, addr )
				prog:push( inst )
			end
		end;
		[ "SE" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			if vy:sub( 1, 1 ):upper() == "V" then
				local inst = 0x5000
				vy = tonumber( "0x"..vy:sub( 2, 2 ) )

				inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )

				prog:push( inst )
			else
				local inst = 0x3000
				vy = tonumber( vy )

				inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, vy )

				prog:push( inst )
			end
		end;
		[ "SNE" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			if vy:sub( 1, 1 ):upper() == "V" then
				local inst = 0x9000
				vy = tonumber( "0x"..vy:sub( 2, 2 ) )

				inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )

				prog:push( inst )
			else
				local inst = 0x4000
				vy = tonumber( vy )

				inst = bit.bor( inst, bit.lshift( vx, DIGIT * 2 ) )
				inst = bit.bor( inst, vy )

				prog:push( inst )
			end
		end;
		[ "LD" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
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
			elseif vx:upper() == "*I" then
				vy = tonumber( "0x"..vy:sub( 2, 2 ) )
				local inst = bit.bor( 0xF055, bit.lshift( vy, DIGIT * 2 ) )
				prog:push( inst )
			else
				vx = tonumber( "0x"..vx:sub( 2, 2 ) )
				if type( vy ) == "number" then
					local inst = bit.bor( 0x6000, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, vy )
					prog:push( inst )
					return
				end
				if vy:sub( 1, 1 ):upper() == "V" then
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8000, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				elseif vy:upper() == "DT" then
					local inst = bit.bor( 0xF007, bit.lshift( vx, DIGIT * 2 ) )
					prog:push( inst )
				elseif vy:upper() == "K" then
					local inst = bit.bor( 0xF00A, bit.lshift( vx, DIGIT * 2 ) )
					prog:push( inst )
				elseif vy:upper() == "*I" then
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
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8004, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
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
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8004, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "AND" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8002, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "XOR" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8003, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "SUB" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8005, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "MUL" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8008, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "SUBN" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8007, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "SHR" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x8006, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "SHL" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x800E, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "RND" ] = function( prog, vx, kk )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			kk = tonumber( kk )

			local inst = bit.bor( 0xC000, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bor( inst, vy )

			prog:push( inst )
		end;
		[ "DRW" ] = function( prog, vx, vy, n )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local n = tonumber( n )

			local inst = bit.bor( 0xD000, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
			inst = bit.bor( inst, n )
			prog:push( inst )
		end;
		[ "SKP" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xE09E, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "SKNP" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			local vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xE0A1, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "LDI" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			vy = tonumber( "0x"..vy:sub( 2, 2 ) )
			local inst = bit.bor( 0x800F, bit.lshift( vx, DIGIT * 2 ) )
			inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
			prog:push( inst )
		end;
		[ "PUSH" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xF000, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "POP" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xF001, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "FLUSH" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xF004, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "NGET" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xF002, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "GET" ] = function( prog, vx )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			vx = tonumber( "0x"..vx:sub( 2, 2 ) )
			local inst = bit.bor( 0xF003, bit.lshift( vx, DIGIT * 2 ) )
			prog:push( inst )
		end;
		[ "NSET" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x800C, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
		[ "SET" ] = function( prog, vx, vy )
			if aliases[ vx ] then
				vx = aliases[ vx ]:upper()
			end
			if aliases[ vy ] then
				vy = aliases[ vy ]:upper()
			end
			if vx:sub( 1, 1 ):upper() == "V" then
				if vy:sub( 1, 1 ):upper() == "V" then
					vx = tonumber( "0x"..vx:sub( 2, 2 ) )
					vy = tonumber( "0x"..vy:sub( 2, 2 ) )
					local inst = bit.bor( 0x800D, bit.lshift( vx, DIGIT * 2 ) )
					inst = bit.bor( inst, bit.lshift( vy, DIGIT ) )
					prog:push( inst )
				end
			end
		end;
	}
end