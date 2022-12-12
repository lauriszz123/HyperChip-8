io.stdout:setvbuf('no')

DEBUG = false

local screen = require "screen"
local CPU = require "cpu"
CPU_SPEED_MAX = math.floor( 6670000 / 60 )
--local CPU_SPEED_MAX = 0xFF
CPU_SPEED_MIN = math.floor( 1000000 / 60 )

local lang = require "lang"
local deviceManager = require "deviceManager"
local keys = require "cpu.keys"
local loadFrames = require "loveFramesLoader"

local strf = string.format
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
				oldPrint( space, k, "=", strf( "%04x", v ) )
			elseif tonumber( v ) then
				oldPrint( space, k, "=", strf( "%04x", tonumber( v ) ) )
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
					c[ i ] = strf( "%04x", tonumber( c[ i ] ) )
				elseif type( c[ i ] ) == "number" then
					c[ i ] = strf( "%04x", c[ i ] )
				end
			end
			oldPrint( unpack( c ) )
		end
	end
end

function love.load()
	local ok = love.window.setMode( 800, 600, {
		fullscreen = true;
	} )
	if not ok then error( "Unable to set up the screen.", 0 ) end

	screen = screen.create( 160, 128, 5 )
	screen:init()

	deviceManager:registerDevice( "Built-in Screen", screen )

	cpu = CPU.create( screen, deviceManager, 2, 0x10000 )
	deviceManager:setCPU( cpu )

	loveframes = loadFrames( cpu, screen, lang, oldPrint )
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
	if dt <= 0.025125 then
		loveframes.update( dt )
	end
	screen:set()
	cpu:cycle()
	deviceManager:handle()
	screen.reset()
end

function love.draw()
	love.graphics.setColor( 1, 1, 1 )
	loveframes.draw()
	love.graphics.setColor( 1, 1, 1 )
	love.graphics.print( "FPS: " .. love.timer.getFPS() )
end

function love.mousepressed( x, y, button )
	loveframes.mousepressed( x, y, button )
end

function love.mousereleased( x, y, button )
	loveframes.mousereleased( x, y, button )
end