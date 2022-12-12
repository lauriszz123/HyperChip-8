-- Author: Laurynas Suopys (lauriszz123)
--
-- Description: Instructions for HyperChip-8

-- Registers
local R = require "cpu.registers"

local bit = bit32 or bit

-- How many bytes are used for each character in memory.
local FONT_HEIGHT = 5

-- The most significant bit for an 8 bit number.
local MSB = 0x80

-- Number of pixels for the width of a sprite.      
local SPRITE_W = 8

-- Number of opcodes to skip to get to the next instruction.
local NEXT_INSTR = 2

-- The number of bits for one hex digit.
local DIGIT = 4

-- The dimensions of the screen.
local DISPLAY_W = 64
local DISPLAY_H = 32

-- Number of digits in base 10.
local DECIMAL = 10

local band = bit.band
local bor = bit.bor
local brshift = bit.rshift
local floor = math.floor
local bxor = bit.bxor


local instructions = {}

instructions[ 0x0000 ] = function( self, opcode )
    local address = band( opcode, 0x0FFF )

    -- HLT
    if address == 0x0000 then
        self.isRunning = false
    elseif address == 0x0001 then
        love.quit()
    -- HCE - Turn On HyperChip-8
    elseif address == 0x00E1 then
    	self.hyper = true
    -- LOW - Turn off HyperChip-8
    elseif address == 0x00E2 then
        self.hyper = false
    -- CLS
    elseif address == 0x00E0 then
        self.screen:clear()
    -- RET
    elseif address == 0x00EE then
        self.rV[ R.SP ] = self.rV[ R.SP ] + 1
        
        self.rV[ R.PC ] = self.memory[ self.rV[ R.SP ] ]
    -- RTI
    elseif address == 0x00EF then
        self:returnFromInterupt()
    elseif address >= 0x00F0 and address <= 0x0CA0 then
        -- SYSTEM CALLS PRE DEFINED
        
    elseif address == 0x0CA1 then
        local sp = self.rV[ R.SP ]
        self.memory[ sp ] = self.rV[ R.PC ]
        self.rV[ R.SP ] = sp - 1

        self.rV[ R.PC ] = self.rV[ R.I ]
    end
end

-- JP addr
instructions[ 0x1000 ] = function( self, opcode )
    self.rV[ R.PC ] = band( opcode, 0x0FFF )
end

-- CALL addr
instructions[ 0x2000 ] = function( self, opcode )
    local sp = self.rV[ R.SP ]
    self.memory[ sp ] = self.rV[ R.PC ]
    self.rV[ R.SP ] = sp - 1

    self.rV[ R.PC ] = band( opcode, 0x0FFF )
end

-- SE Vx, byte
instructions[ 0x3000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = band( opcode, 0x00FF )
    
    if self.rV[ x ] == value then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- SNE Vx, byte
instructions[ 0x4000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = band( opcode, 0x00FF )
    
    if self.rV[ x ] ~= value then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- SE Vx, Vy
instructions[ 0x5000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2)
    local y = brshift( band( opcode, 0x00F0 ), DIGIT )
    
    if self.rV[ x ] == self.rV[ y ] then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- LD Vx, byte
instructions[ 0x6000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = band( opcode, 0x00FF )
    
    self.rV[ x ] = value
end

-- ADD Vx, byte
instructions[ 0x7000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = band( opcode, 0x00FF )

    local v = (self.rV[ x ] + value)
    if v > 0xFF then
    	self.rV[ R.FLAG ] = 1
    end
    
    self.rV[ x ] = v % 0x100
end

instructions[ 0x8000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local y = brshift( band( opcode, 0x00F0 ), DIGIT )
    local op = band( opcode, 0x000F )
    
    -- LD Vx, Vy
    if op == 0x0 then
        self.rV[ x ] = self.rV[ y ]
    -- OR Vx, Vy
    elseif op == 0x1 then
        self.rV[ x ] = bor( self.rV[ x ], self.rV[ y ] )
    -- AND Vx, Vy
    elseif op == 0x2 then
        self.rV[ x ] = band( self.rV[ x ], self.rV[ y ] )
    -- XOR Vx, Vy
    elseif op == 0x3 then
        self.rV[ x ] = bxor( self.rV[ x ], self.rV[ y ] )
    -- ADD Vx, Vy
    elseif op == 0x4 then
        local sum = self.rV[ x ] + self.rV[ y ]
        
        self.rV[ R.FLAG ] = ( sum > 0xFF ) and 1 or 0
        self.rV[ x ] = sum % 0x100
    -- SUB Vx, Vy
    elseif op == 0x5 then
        self.rV[ R.FLAG ] = ( self.rV[ x ] > self.rV[ y ] ) and 1 or 0
        self.rV[ x ] = ( self.rV[ x ] - self.rV[ y ] ) % 0x100
    -- SHR Vx
    elseif op == 0x6 then
        self.rV[ R.FLAG ] = band( self.rV[ x ], 0x1 )
        self.rV[ x ] = floor( self.rV[ x ] / 2 ) % 0x100
    -- SUBN Vx, Vy
    elseif op == 0x7 then
        self.rV[ R.FLAG ] = ( self.rV[ y ] > self.rV[ x ] ) and 1 or 0
        self.rV[ x ] = ( self.rV[ y ] - self.rV[ x ] ) % 0x100
    -- MUL Vx, Vy
    elseif op == 0x8 then
        local sum = self.rV[ x ] * self.rV[ y ]
        
        self.rV[ R.FLAG ] = ( sum > 0xFF ) and 1 or 0
        self.rV[ x ] = sum % 0x100
    -- DIV Vx, Vy
    elseif op == 0x9 then
        self.rV[ x ] = floor( self.rV[ x ] / self.rV[ y ] )
    -- POW Vx, Vy
    elseif op == 0xA then
        local sum = self.rV[ x ] ^ self.rV[ y ]
        
        self.rV[ R.FLAG ] = ( sum > 0xFF ) and 1 or 0
        self.rV[ x ] = sum % 0x100
    -- MOD Vx, Vy
    elseif op == 0xB then
        self.rV[ x ] = self.rV[ x ] % self.rV[ y ]
    -- NSET Vx, Vy
    elseif op == 0xC then
        self.memory[ self.rV[ R.BP ] + self.rV[ x ] ] = self.rV[ y ]
    -- SET Vx, Vy
    elseif op == 0xD then
        self.memory[ self.rV[ R.BP ] - self.rV[ x ] ] = self.rV[ y ]
    -- SHL Vx
    elseif op == 0xE then
        self.rV[ R.FLAG ] = ( band( self.rV[ x ], 0x80 ) == 0x80 ) and 1 or 0
        self.rV[ x ] = floor( self.rV[ x ] * 2 ) % 0x100
    -- LDI Vx, Vy
    elseif op == 0xF then
    	local z = bit.lshift( self.rV[ x ], DIGIT * 2 )
    	self.rV[ R.I ] = bor( z, self.rV[ y ] )
    end
end

-- SNE Vx, Vy
instructions[ 0x9000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local y = brshift( band( opcode, 0x00F0 ), DIGIT )
    
    if self.rV[ x ] ~= self.rV[ y ] then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- LD I, addr
instructions[ 0xA000 ] = function( self, opcode )
    self.rV[ R.I ] = band( opcode, 0x0FFF )
end

-- JP V0, addr
instructions[ 0xB000 ] = function( self, opcode )
    local address = band( opcode, 0x0FFF )

    self.rV[ R.PC ] = self.rV[ R.PC ] + (address + self.rV[ 0 ])
end

-- RND Vx, byte
instructions[ 0xC000 ] = function( self, opcode )
    local index = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local constant = band( opcode, 0x00FF )
    
    self.rV[ index ] = band( math.random( 0, 255 ), constant )
end

-- DRW Vx, Vy, nibble( Vz[command] )
instructions[ 0xD000 ] = function(self, opcode)
    local originX = brshift(band(opcode, 0x0F00), DIGIT * 2)
    local originY = brshift(band(opcode, 0x00F0), DIGIT)
    local height = band( opcode, 0x000F )

    if self.hyper == true then
        self.deviceManager:addEvent( self.rV[ originX ], self.rV[ originY ], self.rV[ height ] )
    else
        local data = 0x0000
        local value = 0
        local position = 0
        
        self.rV[ R.FLAG ] = 0

        for y = 0, height - 1 do
            data = self.memory[ self.rV[ R.I ] + y ]

            for x = 0, SPRITE_W - 1 do
                if band( data, brshift( MSB, x ) ) > 0 then
                    
    				local xx, yy = ((self.rV[ originX ] + x) % DISPLAY_W), ((self.rV[ originY ] + y) % DISPLAY_H)

    				local value = self.screen.getPixel( xx, yy + 1 )

                    if value == 1 then
                        self.rV[ R.FLAG ] = 1
                    end
                    
                    self.screen.putPixel( xx, yy + 1, bxor( value, 1 ) == 1 )
                end
            end
        end
    end
end


instructions[ 0xE000 ] = function( self, opcode )
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local op = band( opcode, 0x00FF )
    
    -- SKP Vx
    if op == 0x9E then
    	if self.keypad[ self.rV[ x ] ] == true then
        	self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    	end
    -- SKPN Vx
    elseif op == 0xA1 then
    	if self.keypad[ self.rV[ x ] ] ~= true then
        	self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    	end
    end
end

instructions[0xF000] = function(self, opcode)
    local x = brshift( band( opcode, 0x0F00 ), DIGIT * 2 )
    local op = band( opcode, 0x00FF )

    -- PUSH Vx
    if op == 0x00 then
    	local sp = self.rV[ R.SP ]
    	self.memory[ sp ] = self.rV[ x ]
    	self.rV[ R.SP ] = sp - 1
    -- POP Vx
    elseif op == 0x01 then
    	local sp = self.rV[ R.SP ] + 1
    	self.rV[ x ] = self.memory[ sp ]
    	self.rV[ R.SP ] = sp
    -- NGET Vx
    elseif op == 0x02 then
        local v = self.memory[ self.rV[ R.BP ] + self.rV[ x ] ]
        self.rV[ x ] = v
    -- GET Vx
    elseif op == 0x03 then
        self.rV[ x ] = self.memory[ self.rV[ R.BP ] - self.rV[ x ] ]
    -- FLUSH Vx
    elseif op == 0x04 then
        self.rV[ R.SP ] = self.rV[ R.SP ] + self.rV[ x ]
    -- LD Vx, DT
    elseif op == 0x07 then
        self.rV[ x ] = self.DT
    -- LD Vx, K
    elseif op == 0x0A then
    	local keyPressed = false
        for i=0, 0xF do
        	if self.keypad[ i ] == true then
        		keyPressed = true
        		self.rV[ x ] = i
        		break
        	end
        end
        if keyPressed == false then
        	self.rV[ R.PC ] = self.rV[ R.PC ] - NEXT_INSTR
        end
    -- LD DT, Vx
    elseif op == 0x15 then
        self.DT = self.rV[ x ]
    -- LD ST, Vx
    elseif op == 0x18 then
        self.ST = self.rV[ x ]
    -- ADD I, Vx
    elseif op == 0x1E then
        self.rV[ R.I ] = self.rV[ R.I ] + self.rV[ x ]
    -- LD F, Vx
    elseif op == 0x29 then
        self.rV[ R.I ] = self.rV[ x ] * FONT_HEIGHT
    -- LD B, Vx
    elseif op == 0x33 then
        local value = self.rV[ x ]
        
        local ones = value % DECIMAL
        value = floor( value / DECIMAL )
        
        local tens = value % DECIMAL
        value = floor( value / DECIMAL )
        
        local hundreds = value % DECIMAL
        
        self.memory[self.rV[ R.I ] ] = hundreds
        self.memory[self.rV[ R.I ] + 1 ] = tens
        self.memory[self.rV[ R.I ] + 2 ] = ones
    -- LD [I], Vx
    elseif op == 0x55 then
        for i = 0, x do
            self.memory[ self.rV[ R.I ] + i ] = self.rV[ i ]
        end
    -- LD Vx, [I]
    elseif op == 0x65 then
        for i = 0, x do
            self.rV[ i ] = self.memory[ self.rV[ R.I ] + i ]
        end
    end
end

return instructions