-- Author: Laurynas Suopys (lauriszz123)
--
-- Description:
-- Instructions for HyperChip-8

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

-- Registers
local R = {
    ST = 0xA;
    DT = 0xB;
    I  = 0xC;
    SP = 0xD;
    PC = 0xE;
    FLAG = 0xF;
}

local instructions = {}

instructions[ 0x0000 ] = function( self, opcode )
    local address = bit.band( opcode, 0x0FFF )

    -- HLT
    if address == 0x0000 then
    	self.isRunning = false
    -- THC - Toggle HyperChip8
    elseif address == 0x00D0 then
    	self.hyper = not self.hyper
    -- CLS
    elseif address == 0x00E0 then
    	self.screen:set()
        self.screen:clear()
        self.screen:reset()
    -- RET
    elseif address == 0x00EE then
        self.rV[ R.SP ] = self.rV[ R.SP ] + 1
        
        self.rV[ R.PC ] = self.memory[ self.rV[ R.SP ] ]
    end
end

-- JP addr
instructions[ 0x1000 ] = function( self, opcode )
    self.rV[ R.PC ] = bit.band( opcode, 0x0FFF )
end

-- CALL addr
instructions[ 0x2000 ] = function( self, opcode )
	local sp = self.rV[ R.SP ]
    self.memory[ sp ] = self.rV[ R.PC ]
    self.rV[ R.SP ] = sp - 1
    
    self.rV[ R.PC ] = bit.band( opcode, 0x0FFF )
end

-- SE Vx, byte
instructions[ 0x3000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = bit.band( opcode, 0x00FF )
    
    if self.rV[ x ] == value then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- SNE Vx, byte
instructions[ 0x4000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = bit.band( opcode, 0x00FF )
    
    if self.rV[ x ] ~= value then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- SE Vx, Vy
instructions[ 0x5000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2)
    local y = bit.rshift( bit.band( opcode, 0x00F0 ), DIGIT )
    
    if self.rV[ x ] == self.rV[ y ] then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- LD Vx, byte
instructions[ 0x6000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = bit.band( opcode, 0x00FF )
    
    self.rV[ x ] = value
end

-- ADD Vx, byte
instructions[ 0x7000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local value = bit.band( opcode, 0x00FF )

    local v = (self.rV[ x ] + value)
    if v > 0xFF then
    	self.rV[ R.FLAG ] = 1
    end
    
    self.rV[ x ] = v % 0x100
end

instructions[ 0x8000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local y = bit.rshift( bit.band( opcode, 0x00F0 ), DIGIT )
    local op = bit.band( opcode, 0x000F )
    
    -- LD Vx, Vy
    if op == 0x0 then
        self.rV[ x ] = self.rV[ y ]
    -- OR Vx, Vy
    elseif op == 0x1 then
        self.rV[ x ] = bit.bor( self.rV[ x ], self.rV[ y ] )
    -- AND Vx, Vy
    elseif op == 0x2 then
        self.rV[ x ] = bit.band( self.rV[ x ], self.rV[ y ] )
    -- XOR Vx, Vy
    elseif op == 0x3 then
        self.rV[ x ] = bit.bxor( self.rV[ x ], self.rV[ y ] )
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
        self.rV[ R.FLAG ] = bit.band( self.rV[ x ], 0x1 )
        self.rV[ x ] = math.floor( self.rV[ x ] / 2 ) % 0x100
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
        self.rV[ x ] = math.floor( self.rV[ x ] / self.rV[ y ] )
    -- POW Vx, Vy
    elseif op == 0xA then
        local sum = self.rV[ x ] ^ self.rV[ y ]
        
        self.rV[ R.FLAG ] = ( sum > 0xFF ) and 1 or 0
        self.rV[ x ] = sum % 0x100
    -- MOD Vx, Vy
    elseif op == 0xB then
        self.rV[ x ] = self.rV[ x ] % self.rV[ y ]
    -- SHL Vx
    elseif op == 0xE then
        self.rV[ R.FLAG ] = ( bit.band( self.rV[ x ], 0x80 ) == 0x80 ) and 1 or 0
        self.rV[ x ] = math.floor( self.rV[ x ] * 2 ) % 0x100
    -- LDI Vx, Vy
    elseif op == 0xF then
    	local z = bit.lshift( self.rV[ x ], DIGIT * 2 )
    	self.rV[ R.I ] = bit.bor( z, self.rV[ y ] )
        print( self.rV[ R.PC ], self.rV[ R.I ] )
    end
end

-- SNE Vx, Vy
instructions[ 0x9000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local y = bit.rshift( bit.band( opcode, 0x00F0 ), DIGIT )
    
    if self.rV[ x ] ~= self.rV[ y ] then
        self.rV[ R.PC ] = self.rV[ R.PC ] + NEXT_INSTR
    end
end

-- LD I, addr
instructions[ 0xA000 ] = function( self, opcode )
    self.rV[ R.I ] = bit.band( opcode, 0x0FFF )
end

-- JP V0, addr
instructions[ 0xB000 ] = function( self, opcode )
    local address = bit.band( opcode, 0x0FFF )

    self.rV[ R.PC ] = self.rV[ R.PC ] + (address + self.rV[ 0 ])
end

-- RND Vx, byte
instructions[ 0xC000 ] = function( self, opcode )
    local index = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local constant = bit.band( opcode, 0x00FF )
    
    self.rV[ index ] = bit.band( math.random( 0, 255 ), constant )
end

-- DRW Vx, Vy, nibble( Vz[command] )
instructions[ 0xD000 ] = function(self, opcode)
    local originX = bit.rshift(bit.band(opcode, 0x0F00), DIGIT * 2)
    local originY = bit.rshift(bit.band(opcode, 0x00F0), DIGIT)
    local height = bit.band( opcode, 0x000F )
    local data = 0x0000
    local value = 0
    local position = 0
    
    self.rV[ R.FLAG ] = 0

    self.screen:set()

    for y = 0, height - 1 do
        data = self.memory[ self.rV[ R.I ] + y ]

        for x = 0, SPRITE_W - 1 do
            if bit.band( data, bit.rshift( MSB, x ) ) > 0 then
                
				local xx, yy = ((self.rV[ originX ] + x) % DISPLAY_W), ((self.rV[ originY ] + y) % DISPLAY_H)

				local value = self.screen.getPixel( xx, yy + 1 )

                if value == 1 then
                    self.rV[ R.FLAG ] = 1
                end
                
                self.screen.putPixel( xx, yy + 1, bit.bxor( value, 1 ) == 1 )
            end
        end
    end

    self.screen:reset()
end


instructions[ 0xE000 ] = function( self, opcode )
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local op = bit.band( opcode, 0x00FF )
    
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
    local x = bit.rshift( bit.band( opcode, 0x0F00 ), DIGIT * 2 )
    local op = bit.band( opcode, 0x00FF )

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
    -- LD Vx, DT
    elseif op == 0x07 then
        self.rV[ x ] = self.rV[ R.DT ]
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
        self.rV[ R.DT ] = self.rV[ x ]
    -- LD ST, Vx
    elseif op == 0x18 then
        self.rV[ R.ST ] = self.rV[ x ]
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
        value = math.floor( value / DECIMAL )
        
        local tens = value % DECIMAL
        value = math.floor( value / DECIMAL )
        
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