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
		oldPrint( ... )
	end
end

function love.load()
	screen:init()

	cpu = CPU.create( screen, CPU_SPEED, 0x20000 )
	cpu:reset()

	local toks = c8c.create( "main.c8c", "bootloader.asm" )
	local toks = asm.compile( "bootloader.asm", "ROM/main.ch8" )

	cpu:loadProgram( "main.ch8" )
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
	print( "Released:", key, scancode )
end

function love.update()
	cpu:cycle()
end

function love.draw()
	screen:draw()
	love.graphics.print( "PC: 0x"..string.format( "%04x", cpu.rV[ 0xE ] ), 400, 2 )
end