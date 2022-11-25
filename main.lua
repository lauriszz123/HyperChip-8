io.stdout:setvbuf('no')

local screen = (require "api.screen").create( 160, 128, 5 )
local CPU = require "cpu"
--local CPU_SPEED = 0xF4240
local CPU_SPEED = 1

--local lang = require "api.lang"
--local keyboard = require "api.keyboard"
--local mouse = require "api.mouse"

local asm = require "api.asm"
local c8c = require "api.c8c"

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

local errMessages

function love.load()
	screen:init()

	cpu = CPU.create( screen, CPU_SPEED, 0x10000 )
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

function love.keypressed( key, scancode )
	if keys[ key ] then
		cpu.keypad[ keys[ key ] ] = true
	end
	print( "Pressed:", key, scancode )
end
function love.keyreleased( key, scancode )
	if keys[ key ] then
		cpu.keypad[ keys[ key ] ] = false
	end
	if errMessage ~= nil and key == 'r' then
		screen:set()
		love.graphics.clear()
		screen:reset()
		errMessage = c8c.create( "main.c8c", "bootloader.asm" )
		if errMessage == nil then
			cpu:reset()
			asm.compile( "bootloader.asm", "ROM/main.ch8" )

			cpu:loadProgram( "main.ch8" )
			errMessage = nil
		else
			screen:set()
			love.graphics.setColor( 1,0,0 )
			love.graphics.printf( errMessage, 1, 1, 159 )
			love.graphics.printf( "Press R to Restart!", 160 / 2 - (19 * 4 / 2), 128 - 6, 159 )
			screen:reset()
		end
	end
	print( "Released:", key, scancode )
end

function love.update()
	cpu:cycle()
end

function love.draw()
	love.graphics.setColor( 1,1,1 )
	screen:draw()
	love.graphics.print( "PC: 0x"..string.format( "%04x", cpu.rV[ 0xE ] ), 400, 2 )
end