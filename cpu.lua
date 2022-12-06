-- Author: Laurynas Suopys (lauriszz123)
--
-- Description:
-- This is a modified Chip-8 interpreter. Named as HyperChip-8.

-- Registers
local R = {
	ST = 0xA;
	DT = 0xB;
	I  = 0xC;
	SP = 0xD;
	PC = 0xE;
	FLAG = 0xF;
}

local instructions = require "instructions"

-- The font sprites for hexadecimal digits.
local MEM_FONT = {
    0xF0, 0x90, 0x90, 0x90, 0xF0,   -- 0
    0x20, 0x60, 0x20, 0x20, 0x70,   -- 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,   -- 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,   -- 3
    0x90, 0x90, 0xF0, 0x10, 0x10,   -- 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,   -- 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,   -- 6
    0xF0, 0x10, 0x20, 0x40, 0x40,   -- 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,   -- 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,   -- 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,   -- A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,   -- B
    0xF0, 0x80, 0x80, 0x80, 0xF0,   -- C
    0xE0, 0x90, 0x90, 0x90, 0xE0,   -- D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,   -- E
    0xF0, 0x80, 0xF0, 0x80, 0x80    -- F
}

local errors = {
	CYCLES_OUT_OF_BOUNDS = 0x1;
	UNKNOWN_INSTRUCTION = 0x02;
};

return {
	errors = errors;
	create = function( screen, speed, ramSize )
		print( "CPU Created." )
		return {
			speed = speed;
			memory = {};
			ramSize = ramSize;
			screen = screen;
			keypad = {};
			DT = 0;
			ST = 0;

			rV = {};
			interupt = false;

			isRunning = false;

			reset = function( self )
				for i=0, self.ramSize - 1 do
					if i <= #MEM_FONT then
						self.memory[ i ] = MEM_FONT[ i + 1 ]
					else
						self.memory[ i ] = 0x0
					end
				end

				for i=0, 0xF do
					self.rV[ i ] = 0x0
					self.keypad[ i ] = 0x0
				end

				self.rV[ R.PC ] = 0x200
				self.rV[ R.SP ] = self.ramSize - 1
				self.rV[ R.I ] = 0
				self.interupt = false;
				self.DT = 0;
				self.ST = 0;

				print( "CPU Reset." )
			end;

			loadProgram = function( self, name )
				local contents, size = love.filesystem.read( "ROM/"..name )
				for i=1, #contents do
					self.memory[ 0x200 + (i - 1) ] = contents:sub( i, i ):byte()
				end

				print( "Program loaded: "..name, "Size: "..size )
			end;

			running = function( self )
				return self.isRunning
			end;

			push = function( self, value )
				self.memory[ self.rV[ R.SP ] ] = value
				self.rV[ R.SP ] = self.rV[ R.SP ] + 1
			end;
			pop = function( self )
				self.rV[ R.SP ] = self.rV[ R.SP ] - 1
				return self.memory[ self.rV[ R.SP ] ]
			end;

			fetch = function( self )
				local pc = self.rV[ R.PC ]
				local byte = bit.bor( bit.lshift( self.memory[ pc ], 8 ), self.memory[ pc + 1 ] )
				self.rV[ R.PC ] = pc + 2
				return byte
			end;

			step = function( self, opcode )
				local inst = bit.band( opcode, 0xF000 )
				if instructions[ inst ] then
					return instructions[ inst ]( self, opcode )
				else
					return errors.UNKNOWN_INSTRUCTION
				end
			end;

			cycle = function( self )
				if self.isRunning == true then
					for i=0, self.speed do
						if self.rV[ R.PC ] >= 0x20000 then
							self.isRunning = false
							return errors.CYCLES_OUT_OF_BOUNDS
						end
						local err = self:step( self:fetch() )
						if err then
							return
						end
						if self.isRunning == false then
							break
						end
					end
					-- Decrement the delay timer.
				    if self.DT > 0 then
				        self.DT = self.DT - 1
				    end
				    
				    -- Decrement the sound timer.
				    if self.ST > 0 then
				        self.ST = self.ST - 1
				    end
			    end
			end;
		}
	end
}