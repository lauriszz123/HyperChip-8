io.stdout:setvbuf('no')

DEBUG = false

local screen = (require "api.screen").create( 160, 128, 5 )
local CPU = require "cpu"
local CPU_SPEED_MAX = math.floor( 7833600 / 60 )
--local CPU_SPEED_MAX = 0xFF
local CPU_SPEED_MIN = math.floor( 1000000 / 60 )

--local lang = require "api.lang"
--local keyboard = require "api.keyboard"
--local mouse = require "api.mouse"

local asm = require "api.asm"
local c8c = require "api.c8c"

local DIGIT = 4

local keys = {
	[ "1" ] = 0x1;
	[ "2" ] = 0x2;
	[ "3" ] = 0x3;
	[ "4" ] = 0xC;
	[ "q" ] = 0x4;
	[ "w" ] = 0x5;
	[ "e" ] = 0x6;
	[ "r" ] = 0xD;
	[ "a" ] = 0x7;
	[ "s" ] = 0x8;
	[ "d" ] = 0x9;
	[ "f" ] = 0xE;
	[ "z" ] = 0xA;
	[ "x" ] = 0x0;
	[ "c" ] = 0xB;
	[ "v" ] = 0xF;
}

local oldPrint = print

local function tablePrint( t, space )
	space = space or ""
	if space == "" then
		oldPrint( space .. "{" )
	end
	for k, v in pairs( t ) do
		if type( v ) == "table" then
			oldPrint( space, k, "=", "{" )
			tablePrint( v, space .. "\t" )
		else
			if type( v ) == "number" then
				oldPrint( space, k, "=", string.format( "%04x", v ) )
			elseif tonumber( v ) then
				oldPrint( space, k, "=", string.format( "%04x", tonumber( v ) ) )
			else
				oldPrint( space, k, "=", v )
			end
		end
	end
	oldPrint( space .. "}" )
end

function print( ... )
	if DEBUG then
		local args = ...
		if type( args ) == "table" then
			tablePrint( args )
		else
			local c = { ... }
			for i=1, #c do
				if tonumber( c[ i ] ) then
					c[ i ] = string.format( "%04x", tonumber( c[ i ] ) )
				elseif type( c[ i ] ) == "number" then
					c[ i ] = string.format( "%04x", c[ i ] )
				end
			end
			oldPrint( unpack( c ) )
		end
	end
end

local errMessages

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
		return "JP "..string.format( "%03x", address )
	elseif inst == 0x2000 then
		return "CALL "..string.format( "%03x", address )
	elseif inst == 0x3000 then
		return "SE V" .. string.format( "%01x", x ) .. ", "..string.format( "%02x", byte )
	elseif inst == 0x4000 then
		return "SNE V" .. string.format( "%01x", x ) .. ", "..string.format( "%02x", byte )
	elseif inst == 0x5000 then
		return "SE V" .. string.format( "%01x", x ) .. ", V"..string.format( "%02x", y )
	elseif inst == 0x6000 then
		return "LD V" .. string.format( "%01x", x ) .. ", "..string.format( "%02x", byte )
	elseif inst == 0x7000 then
		return "ADD V" .. string.format( "%01x", x ) .. ", "..string.format( "%02x", byte )
	elseif inst == 0x8000 then
		-- LD Vx, Vy
	    if op == 0x0 then
	        return "LD V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- OR Vx, Vy
	    elseif op == 0x1 then
	        return "OR V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- AND Vx, Vy
	    elseif op == 0x2 then
	        return "AND V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- XOR Vx, Vy
	    elseif op == 0x3 then
	        return "XOR V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- ADD Vx, Vy
	    elseif op == 0x4 then
	        return "ADD V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- SUB Vx, Vy
	    elseif op == 0x5 then
	        return "SUB V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- SHR Vx
	    elseif op == 0x6 then
	        return "SHR V"..string.format( "%01x", x )
	    -- SUBN Vx, Vy
	    elseif op == 0x7 then
	        return "SUBN V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- MUL Vx, Vy
	    elseif op == 0x8 then
	        return "MUL V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- DIV Vx, Vy
	    elseif op == 0x9 then
	        return "DIV V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- POW Vx, Vy
	    elseif op == 0xA then
	        return "POW V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- MOD Vx, Vy
	    elseif op == 0xB then
	        return "MOD V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- NSET Vx, Vy
	    elseif op == 0xC then
	        return "NSET V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- SET Vx, Vy
	    elseif op == 0xD then
	        return "SET V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    -- SHL Vx
	    elseif op == 0xE then
	        return "SHL V"..string.format( "%01x", x )
	    -- LDI Vx, Vy
	    elseif op == 0xF then
	    	return "LDI V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	    end
	elseif inst == 0x9000 then
		return "SNE V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )
	elseif inst == 0xA000 then
		return "LD I, "..string.format( "%03x", addr )
	elseif inst == 0xB000 then
		return "JP V0, "..string.format( "%03x", addr )
	elseif inst == 0xC000 then
		return "RND V"..string.format( "%01x", x )..", "..string.format( "%02x", byte )
	elseif inst == 0xD000 then
		-- DRW Vx, Vy, nibble( Vz[command] )
		return "DRW V"..string.format( "%01x", x )..", V"..string.format( "%01x", y )..", "..string.format( "%01x", nibble )
	elseif inst == 0xE000 then
		-- SKP Vx
	    if byte == 0x9E then
	    	return "SKP V"..string.format( "%01x", x )
	    -- SKPN Vx
	    elseif byte == 0xA1 then
	    	return "SKPN V"..string.format( "%01x", x )
	    end
	elseif inst == 0xF000 then
		if byte == 0x00 then
	    	return "PUSH V"..string.format( "%01x", x )
	    -- POP Vx
	    elseif byte == 0x01 then
	    	return "POP V"..string.format( "%01x", x )
	    -- NGET Vx
	    elseif byte == 0x02 then
	        return "NGET V"..string.format( "%01x", x )
	    -- GET Vx
	    elseif byte == 0x03 then
	        return "GET V"..string.format( "%01x", x )
	    -- FLUSH Vx
	    elseif byte == 0x04 then
	        return "FLUSH V"..string.format( "%01x", x )
	    -- LD Vx, DT
	    elseif byte == 0x07 then
	        return "LD V"..string.format( "%01x", x )..", DT"
	    -- LD Vx, K
	    elseif byte == 0x0A then
	    	return "LD V"..string.format( "%01x", x )..", K"
	    -- LD DT, Vx
	    elseif byte == 0x15 then
	        return "LD DT, V"..string.format( "%01x", x )
	    -- LD ST, Vx
	    elseif byte == 0x18 then
	        return "LD ST, V"..string.format( "%01x", x )
	    -- ADD I, Vx
	    elseif byte == 0x1E then
	        return "ADD I, V"..string.format( "%01x", x )
	    -- LD F, Vx
	    elseif byte == 0x29 then
	        return "LD F, V"..string.format( "%01x", x )
	    -- LD B, Vx
	    elseif byte == 0x33 then
	        return "LD B, V"..string.format( "%01x", x )
	    -- LD [I], Vx
	    elseif byte == 0x55 then
	        return "LD [I], V"..string.format( "%01x", x )
	    -- LD Vx, [I]
	    elseif byte == 0x65 then
	        return "LD V"..string.format( "%01x", x )..", [I]"
	    end
	end

	return "UNKN"
end

local function loadFrames()
	loveframes = require("loveframes")

	local chipScreen = loveframes.Create( "frame" )
	chipScreen:SetName( "HyperChip Screen" )
	chipScreen:SetWidth( 160 * 3 + 2 )
	chipScreen:SetHeight( 128 * 3 + 27 )
	chipScreen:CenterWithinArea( 460, -240, love.graphics.getDimensions() )
    chipScreen:SetDockable( false )

	local chipScreenPanel = loveframes.Create( "panel", chipScreen )

    chipScreenPanel.Draw = function( self )
    	screen:draw( self:GetX() + 1, self:GetY() + 26 )
	end;

	local chipInfo = loveframes.Create( "frame" )
	chipInfo:SetName( "HyperChip Registers" )
	chipInfo:SetWidth( 160 )
	chipInfo:SetHeight( 86 * 4 )
	chipInfo:CenterWithinArea( -640, -240, love.graphics.getDimensions() )
    chipInfo:SetDockable( false )

    for i=0, 0xF do
	    local reg = loveframes.Create("text", chipInfo )
	    reg.register = i
	    reg.Update = function(object, dt)
	    	local num = cpu.rV[ object.register ]
	    	if num then
		        object:CenterX()
		        object:SetY((20 * i) + 26)
		        object:SetText("V["..string.format( "%x", object.register ).."] = "..string.format( "%04x", num ) )
		    end
	    end
	end

	local chipController = loveframes.Create( "frame" )
	chipController:SetName( "HyperChip Controller" )
	chipController:SetWidth( 320 )
	chipController:SetHeight( 240 )
	chipController:CenterWithinArea( -360, -240, love.graphics.getDimensions() )
    chipController:SetDockable( false )

    local slider2text = loveframes.Create("text", chipController )
    slider2text:CenterX()
    slider2text:SetY( 60 )
    slider2text:SetText( "CPU SPEED: "..((cpu.speed * 60) / 1000000) .. "MHz" )
    slider2text:CenterX()

    local slider2 = loveframes.Create( "slider", chipController )
	slider2:SetPos( 6, 80 )
	slider2:SetWidth( 308 )
	slider2:SetMinMax( CPU_SPEED_MIN, CPU_SPEED_MAX )
	slider2.OnValueChanged = function(object)
	    cpu.speed = math.floor( object:GetValue() )

	    slider2text:CenterX()
	    slider2text:SetText( "CPU SPEED: "..((cpu.speed * 60) / 1000000) .. "MHz" )
	end

    local resetButton = loveframes.Create( "button", chipController )
    resetButton:SetText( "Reset" )
    resetButton:SetX( 1 )
    resetButton:SetY( 28 )
    resetButton.OnClick = function(object, x, y)
		cpu.isRunning = false
    	screen:set()
    	screen:clear()
		screen:reset()
    	cpu:reset()
    	errMessage = c8c.create( "main.c8c", "bootloader.asm" )
		if errMessage == nil then
			asm.compile( "bootloader.asm", "ROM/main.ch8" )

			cpu:loadProgram( "main.ch8" )
		else
			screen:set()
			love.graphics.setColor( 1,0,0 )
			love.graphics.printf( errMessage, 1, 1, 159 )
			love.graphics.printf( "Press R to Restart!", 160 / 2 - (19 * 4 / 2), 128 - 6, 159 )
			screen:reset()
		end
    end

	runButton = loveframes.Create( "button", chipController )
    runButton:SetText( "Run" )
    runButton:SetX( 167 )
    runButton:SetY( 28 )
    runButton.OnClick = function( object, x, y )
    	cpu.isRunning = not cpu.isRunning
    end

    stepButton = loveframes.Create( "button", chipController )
    stepButton:SetText( "Step" )
    stepButton:SetX( 84 )
    stepButton:SetY( 28 )
    stepButton.OnClick = function( object, x, y )
    	cpu:step( cpu:fetch() )
    end

    local chipRam = loveframes.Create( "frame" )
	chipRam:SetName( "HyperChip RAM" )
	chipRam:SetWidth( 320 )
	chipRam:SetHeight( 346 )
	chipRam:CenterWithinArea( -360, 64, love.graphics.getDimensions() )
    chipRam:SetDockable( false )

    for i=0, 0xF do
	    local reg = loveframes.Create("text", chipRam )
	    reg:SetX( 2 )
	    reg.Update = function(object, dt)
	    	if cpu.rV[ 0xE ] then
		    	local loc = cpu.rV[ 0xE ] + (i * 2)
		    	local num = cpu.memory[ loc ]
		    	local num2 = cpu.memory[ loc + 1 ]
		    	if num and num2 then
			        object:SetY((20 * i) + 26)
			        local instruction = opToText( num, num2 ):upper()
			        if i==0 then
			        	object:SetDefaultColor( 0, 0.4, 0, 1 )
			        end
			        object:SetText("["..string.format( "%04x", loc ).."] - "..string.format( "%02x", num ).." "..string.format( "%02x", num2 ).."      "..instruction )
			    end
			end
	    end
	end
end

function love.load()
	local ok = love.window.setMode( 800, 600, {
		fullscreen = true;
	} )
	if not ok then error( "Unable to set up the screen.", 0 ) end

	screen:init()

	cpu = CPU.create( screen, 2, 0x10000 )

	loadFrames()
end

function love.keypressed( key, scancode )
	if keys[ key ] then
		cpu.keypad[ keys[ key ] ] = true
	end
end
function love.keyreleased( key, scancode )
	if keys[ key ] then
		cpu.keypad[ keys[ key ] ] = false
	end
end
function love.update( dt )
	if runButton then
		if cpu.isRunning == true then
			runButton:SetText( "Stop" )
		else
			runButton:SetText( "Run" )
		end
	end
	cpu:cycle()
	screen:handle()
	loveframes.update( dt )
end

function love.draw()
	love.graphics.setColor( 1,1,1 )
	loveframes.draw()
end

function love.mousepressed(x, y, button)
    loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    loveframes.mousereleased(x, y, button)
end