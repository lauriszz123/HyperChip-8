local opcodeToText = require "opcodeToText"

local strf = string.format

return function( cpu, screen, lang, oldPrint )
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
		        object:SetText("V["..strf( "%x", object.register ).."] = "..strf( "%04x", num ) )
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
    	errMessage = lang.compile( "main.c8c", "bootloader.asm" )
		if errMessage == nil then
			oldPrint( "Size:", cpu:loadProgram( "main.ch8" ).." bytes" )
		else
			screen:set()
			love.graphics.setColor( 1,0,0 )
			love.graphics.printf( errMessage, 1, 1, 159 )
			love.graphics.printf( "Click 'Reset' to restart.", 160 / 2 - (25 * 4 / 2), 128 - 6, 159 )
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
    	screen:set()
    	cpu:step( cpu:fetch() )
    	screen.reset()
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
			        local instruction = opcodeToText.convert( num, num2 ):upper()
			        if i==0 then
			        	object:SetDefaultColor( 0, 0.4, 0, 1 )
			        end
			        object:SetText("["..strf( "%04x", loc ).."] - "..strf( "%02x", num ).." "..strf( "%02x", num2 ).."      "..instruction )
			    end
			end
	    end
	end

	return loveframes
end