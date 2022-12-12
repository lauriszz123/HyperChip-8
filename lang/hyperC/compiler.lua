local environment = require "lang.hyperC.environment"
local codeStore = require "lang.hyperC.assemblyCodeStore"

local out, gVars, ifcount, usedReturn

local function setupAliases()
	out:push( "alias", "ra", "V0" )
	out:push( "alias", "rb", "V1" )
	out:push( "alias", "rc", "V2" )
	out:push( "alias", "il", "V8" )
	out:push( "alias", "ih", "V9" )
	out:push( "alias", "rI", "VC" )
	out:push( "alias", "rBP", "VB" )
	out:push( "alias", "rSP", "VD" )
	out:push( "alias", "rPC", "VE" )
	out:push( "HCE" )
end

local function setRegToLabelMem( label )
	out:push( "LD", "il", label..".low" )
	out:push( "LD", "ih", label..".high" )
	out:push( "LDI", "ih", "il" )
end

local function setupFunctionHeader( name )
	out:push( "func_"..name..":" )
	out:push( "PUSH", "rBP" )
	out:push( "LD", "rBP", "rSP" )
end

local function popStackN( n )
	if n > 0 then
		out:push( "LD", "rc", n )
		out:push( "FLUSH", "rc" )
	end
end

local function setupFunctionReturn( localCount )
	popStackN( localCount )
	out:push( "POP", "rBP" )
	out:push( "RET" )
end

local function generateOperator( op )
	if op == "+" then
		out:push( "ADD", "ra", "rb" )
	elseif op == "-" then
		out:push( "SUB", "ra", "rb" )
	elseif op == "*" then
		out:push( "MUL", "ra", "rb" )
	elseif op == "/" then
		out:push( "DIV", "ra", "rb" )
	elseif op == "%" then
		out:push( "MOD", "ra", "rb" )
	elseif op == "^" then
		out:push( "POW", "ra", "rb" )
	elseif op == ">" then
		out:push( "SUBN", "ra", "rb" )
		out:push( "SE", "VF", "0x1" )
	elseif op == "<" then
		out:push( "SUB", "ra", "rb" )
		out:push( "SE", "VF", "0x1" )
	elseif op == ">=" then
		out:push( "SUBN", "ra", "rb" )
		out:push( "SE", "ra", "0x0" )
		out:push( "SE", "VF", "0x1" )
	elseif op == "<=" then
		out:push( "SUB", "ra", "rb" )
		out:push( "SE", "ra", "0x0" )
		out:push( "SE", "VF", "0x1" )
	elseif op == "==" then
		out:push( "SNE", "ra", "rb" )
	elseif op == "!=" then
		out:push( "SE", "ra", "rb" )
	end
end

local function fetchLocalVariableFromStack( var, reg )
	if var.value < 0 then
		if reg == 0 then
			out:push( "LD", "ra", math.abs( var.value ) + 2 )
			out:push( "NGET", "ra" )
		else
			out:push( "LD", "rb", math.abs( var.value ) + 2 )
			out:push( "NGET", "rb" )
		end
	else
		if reg == 0 then
			out:push( "LD", "ra", math.abs( var.value ) )
			out:push( "GET", "ra" )
		else
			out:push( "LD", "rb", math.abs( var.value ) )
			out:push( "GET", "rb" )
		end
	end
end

--------------------------------------------------
-- Name: compile
--
-- Arguments:
--	tree - a tree that the parser returned.
--
-- Description: compiles to assembly code
-- the parsed ast tree.
--------------------------------------------------
local function compile( tree, reg )
	if tree.type == "library" then
		out = codeStore.create()
		gVars = environment.new()
		ifcount = 0
		usedReturn = false
		setupAliases()
		out:push( "LD", "rBP", "rSP" )
		for i=1, #tree.globals do
			compile( tree.globals[ i ] )
		end
		setRegToLabelMem( "libEnd" )
		out:push( "LD", "rPC", "rI" )
		for i=1, #tree.functions do
			compile( tree.functions[ i ] )
		end
		out:push( "libEnd:" )
		if gVars:get( {name="main"} ).type == "function" then
			setRegToLabelMem( "func_main" )
			out:push( "CALL", "I" )
		else
			error( "No entry function found. (function main)", 0 )
		end
		out:push( "HLT" )
		out:push( "data:" )
		for k, v in pairs( gVars.variables ) do
			if v.type == "global_variable" then
				out:push( "var_"..k..": db", "0x1", "0x0" )
			end
		end
		return out
	elseif tree.type == "block" then
		for i=1, #tree.block do
			compile( tree.block[ i ], reg )
		end
	elseif tree.type == "whileblock" then
		local currifcount = ifcount
		ifcount = ifcount + 1
		setRegToLabelMem( "whileend_"..currifcount )
		out:push( "LD", "rPC", "rI" )

		out:push( "while_"..currifcount..":" )
		compile( tree.block )

		out:push( "whileend_"..currifcount..":" )
		setRegToLabelMem( "while_"..currifcount )
		compile( tree.cond )
		out:push( "LD", "rPC", "rI" )
	elseif tree.type == "vardef" then
		local v = compile( tree.expr )
		if v then
			out:push( "LD", "ra", v )
		end
		if reg == "function" then
			gVars:define( tree, "local_variable", gVars.localCount )
			out:push( "PUSH", "ra" )
			gVars.localCount = gVars.localCount + 1
		else
			gVars:define( tree, "global_variable" )
			setRegToLabelMem( "var_"..tree.name )
			out:push( "LD", "[I]", "ra" )
		end
	elseif tree.type == "varset" then
		local v = compile( tree.expr )
		if v then
			out:push( "LD", "ra", v )
		end
		if gVars:get( tree ).type == "local_variable" then
			if gVars:get( tree ).value < 0 then
				out:push( "LD", "rb", math.abs( var.value ) + 2 )
				out:push( "NSET", "rb", "ra" )
			else
				out:push( "LD", "rb", gVars:get( tree ).value )
				out:push( "SET", "rb", "ra" )
			end
		else
			setRegToLabelMem( "var_"..tree.name )
			out:push( "LD", "[I]", "ra" )
		end
	elseif tree.type == "defunc" then
		setupFunctionHeader( tree.name )
		gVars:define( tree, "function" )
		gVars = environment.new( gVars )
		for i=1, #tree.args do
			gVars:define( {name=tree.args[ i ].value}, "local_variable", -i )
		end
		compile( tree.body, "function" )
		if usedReturn == false then
			setupFunctionReturn( gVars.localCount )
		end
		gVars = gVars.parent
		usedReturn = false
	elseif tree.type == "return" then
		usedReturn = true
		compile( tree.value )
		setupFunctionReturn( gVars.localCount )
	elseif tree.type == "call" then
		if tree.name == "clearScreen" then
			out:push( "CLS" )
		elseif tree.name == "draw" then
			local y = compile( tree.args[ 2 ], 0 )
			if y then
				out:push( "LD", "ra", y )
				out:push( "PUSH", "ra" )
			else
				out:push( "PUSH", "ra" )
			end

			local x = compile( tree.args[ 1 ], 0 )
			if x then
				out:push( "LD", "ra", x )
				out:push( "PUSH", "ra" )
			else
				out:push( "PUSH", "ra" )
			end

			local f = compile( tree.args[ 3 ], 0 )
			if f then
				out:push( "LD", "V3", f )
				out:push( "LD", "F", "V3" )
			else
				out:push( "LD", "F", "ra" )
			end

			out:push( "POP", "ra" )
			out:push( "POP", "rb" )
			out:push( "DRW", "ra", "rb", 5 )
		elseif tree.name == "output" then
			local y = compile( tree.args[ 3 ], 0 )
			if y then
				out:push( "LD", "ra", y )
				out:push( "PUSH", "ra" )
			else
				out:push( "PUSH", "ra" )
			end

			local x = compile( tree.args[ 2 ], 0 )
			if x then
				out:push( "LD", "ra", x )
				out:push( "PUSH", "ra" )
			else
				out:push( "PUSH", "ra" )
			end

			local f = compile( tree.args[ 1 ], 0 )
			if f then
				out:push( "LD", "ra", f )
			end

			out:push( "POP", "rb" )
			out:push( "POP", "rc" )
			out:push( "OUT", "ra", "rb", "rc" )
		else
			if gVars:get( tree ).type == "function" then
				for i=#tree.args, 1, -1 do
					local v = compile( tree.args[ i ], 0 )
					if v then
						out:push( "LD", "ra", v )
						out:push( "PUSH", "ra" )
					else
						out:push( "PUSH", "ra" )
					end
				end
				setRegToLabelMem( "func_" .. tree.name )
				out:push( "CALL", "I" )
				popStackN( #tree.args )
			end
		end
	elseif tree.type == "ifblock" then
		local currifcount = ifcount
		ifcount = ifcount + 1
		setRegToLabelMem( "if_"..currifcount )
		compile( tree.cond )
		out:push( "LD", "rPC", "rI" )

		local elseblock = false
		if tree.elseblock then
			setRegToLabelMem( "ifelse_"..currifcount )
			out:push( "LD", "rPC", "rI" )
			elseblock = true
		else
			setRegToLabelMem( "ifend_"..currifcount )
			out:push( "LD", "rPC", "rI" )
		end

		out:push( "if_"..currifcount..":" )
		compile( tree.trueblock )

		if tree.elseblock then
			setRegToLabelMem( "ifend_"..currifcount )
			out:push( "LD", "rPC", "rI" )

			out:push( "ifelse_"..currifcount..":" )
			compile( tree.elseblock )
		end
		out:push( "ifend_"..currifcount..":" )
	elseif tree.type == "expr" then
		if tree.left.type == "num" and tree.right.type == "num" then
			out:push( "LD", "ra", compile( tree.left ) )
		elseif tree.right.type == "num" and tree.left.type == "expr" then
			compile( tree.left, 0 )
		elseif not tree.left.type == "fetch" then
			local x = compile( tree.left, 0 )
			if x then
				out:push( "LD", "ra", x )
			end
		elseif tree.left.type == "call" then
			compile( tree.left, 0 )
		elseif tree.left.type == "fetch" then
			compile( tree.left, 0 )
		end
		if tree.right.type == "num" then
			out:push( "LD", "rb", compile( tree.right ) )
		elseif tree.right.type == "call" then
			local v = compile( tree.left )
			if v then
				out:push( "LD", "ra", v )
			end
			out:push( "PUSH", "ra" )
			compile( tree.right, 0 )
			out:push( "LD", "rb", "ra" )
			out:push( "POP", "ra" )
		else
			compile( tree.right, 0 )
			local v = compile( tree.left, 1 )
			if v then
				out:push( "LD", "rb", v )
			end
		end
		generateOperator( tree.op )
	elseif tree.type == "fetch" then
		if gVars:get( tree ).type == "global_variable" then
			setRegToLabelMem( "var_"..tree.name )
			if reg == 0 then
				out:push( "LD", "ra", "[I]" )
			else
				out:push( "PUSH", "ra" )
				out:push( "LD", "ra", "[I]" )
				out:push( "LD", "rb", "ra" )
				out:push( "POP", "ra" )
			end
		else
			local var = gVars:get( tree )
			fetchLocalVariableFromStack( var, reg )
		end
	elseif tree.type == "num" then
		return tree.value
	end
end

return {
	compile = function( ast )
		return compile( ast )
	end;
}