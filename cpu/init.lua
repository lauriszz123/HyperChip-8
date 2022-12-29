-- Author: Laurynas Suopys (lauriszz123)
--
-- Description:
-- This is a modified Chip-8 interpreter. Named as HyperChip-8.

-- Chip-8 Modified Instruction Set
local instructions = require "cpu.instructions"

-- The font sprites for hexadecimal digits.
local MEM_FONT = require "cpu.font"

-- Registers
local R = require "cpu.registers"

local errors = {
	CYCLES_OUT_OF_BOUNDS = 0x1;
	UNKNOWN_INSTRUCTION = 0x02;
};

local bor = bit.bor
local blshift = bit.lshift
local band = bit.band

return {
	errors = errors;
	create = function( screen, deviceManager, speed, ramSize )
		return {
			speed = speed;
			memory = {};
			keypad = {};
			interuptTable = {};

			ramSize = ramSize;
			deviceManager = deviceManager;
			screen = screen;
			DT = 0;
			ST = 0;

			rV = {};
			interupt = false;
			softInterupt = false;
			interupted = false;

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

				self.interuptTable = {}

				self.rV[ R.PC ] = 0x200
				self.rV[ R.SP ] = self.ramSize - 1
				self.rV[ R.I ] = 0
				self.interupt = false
				self.softInterupt = false
				self.interupted = false
				self.DT = 0;
				self.ST = 0;

				print( "CPU Reset." )
			end;

			interuptProgram = function( self, jump )
				if self.interupt == true then
					local sp = self.rV[ R.SP ]
					local bp = self.rV[ R.BP ]

					table.insert( self.interuptTable, {
						rV = self.rV;
						ST = self.ST;
						DT = self.DT;
					} )
					self.rV = {}
					for i=0, 0xF do
						self.rV[ i ] = 0x0
					end
					self.rV[ R.SP ] = sp
					self.rV[ R.PC ] = jump
					sinself.rV[ R.BP ] = bp
					self.DT = 0
					self.ST = 0
					self.interupted = true
				end
			end;

			softwareInterupt = function( self, device )
				if self.interupt == true then
					self.interupted = true
					self.running = false
					self.softInterupt = true
					self.deviceManager:setCurrentDevice( device )
				end
			end;

			returnFromInterupt = function( self )
				if self.softInterupt == true then
					self.interupted = false
					self.running = true
					self.softInterupt = false
				else
					local data = table.remove( self.interuptTable )
					self.rV = data.rV
					self.DT = data.DT
					self.ST = data.ST
					self.interupted = false
				end
			end;

			loadProgram = function( self, name )
				local contents, size = love.filesystem.read( "ROM/"..name )
				for i=1, #contents do
					self.memory[ 0x200 + (i - 1) ] = contents:sub( i, i ):byte()
				end

				print( "Program loaded: "..name, "Size: "..size )
				return size
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
				local byte = bor( blshift( self.memory[ pc ], 8 ), self.memory[ pc + 1 ] )
				self.rV[ R.PC ] = pc + 2
				return byte
			end;

			step = function( self, opcode )
				local inst = band( opcode, 0xF000 )
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