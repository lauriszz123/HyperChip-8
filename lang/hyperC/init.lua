--[[

C like language

var varname = byte

var array[size] = {		-- TO BE IMPLEMENTED
	byte, byte, byte
}

func name( a,b,c ) {
	return 0
}

def name( a, b, c ) = a * b + c

if x == 1 {
	
} else if( x == 2 ) {
	
} else {
	
}

while( varname < 10 ) {
	
}

--]]

local wrapper = require "lang.hyperC.wrapper"
local tokenizer = require "lang.hyperC.tokenizer"
local parser = require "lang.hyperC.parser"
local compiler = require "lang.hyperC.compiler"

return {
	create = function( file, out )
		local co, err = coroutine.create( function()
			local contents, size = love.filesystem.read( file )
			local parsed = parser.parse( tokenizer.tokenize( wrapper.eatFile( contents ) ) )
			print( parsed )
			local compiled = compiler.compile( parsed )
			print( compiled )
			love.filesystem.write( out, table.concat( compiled, "\n" ) )
		end )
		while coroutine.status( co ) == "suspended" do
			local ok, err = coroutine.resume( co )
			if not ok then return err end
		end
	end
}