-- Author: Laurynas Suopys (lauriszz123)
--
-- Description:
-- A simple assembler built for HyperChip-8

local tokenizer = require "lang.assembler.tokenizer"
local simpleInterpreter = require "lang.assembler.simpleInterpreter"
local compiler = require "lang.assembler.compiler"

return {
	compile = function( inp, out )
		local tokens = tokenizer.tokenize( inp )
		local bytecode = compiler.compile( tokens, simpleInterpreter.runThrough( tokens ) )

		local file, errorstr = love.filesystem.newFile( out )
		if errorstr then print( errorstr ) end
		file:open( "w" )
		for i=1, #bytecode do
			file:write( string.char( bytecode[ i ] ), 1 )
		end
		file:close()
		file:release()

		return bytecode
	end;
}