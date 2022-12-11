local hyperC = require "lang.hyperC"
local assembler = require "lang.assembler"

return {
	compile = function( file, out )
		local err = hyperC.create( file, out )
		if err then
			return err
		end
		assembler.compile( out, "ROM/main.ch8" )
	end;
}