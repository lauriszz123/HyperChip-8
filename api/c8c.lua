--[[

C like language

var varname = byte
var array[size] = {
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

--------------------------------------------------
-- Name: wrapper
--
-- Arguments:
--	file - whole file as a string, that
--			is already read.
--
-- Description: Wrap file contents into an object
-- for simpler tokenization.
--------------------------------------------------
local function wrapper( file )

	-- Add a new-line for bug fixing
	file = file .. "\n"
	local i = 1
	local line = 1
	return {
		peek = function()
			return file:sub( i, i )
		end;
		next = function()
			local v = file:sub( i, i )
			i = i + 1
			if v == "\n" then
				line = line + 1
			end
			return v
		end;
		eof = function()
			return i >= #file
		end;
		getLine = function()
			return line
		end;
	}
end

--------------------------------------------------
-- Name: tokenize
--
-- Arguments:
--	input - wrapper file input
--
-- Description: tokenize a file from a string
-- to token objects.
--------------------------------------------------
local function tokenize( input )

	-- Check if a charachter contains word charachters and underscore
	local function isWord( v )
		return v:find( "[a-zA-Z_]" ) ~= nil
	end

	-- A whole word which also has numbers
	local function word( v )
		return v:find( "[a-zA-Z_0-9]" ) ~= nil
	end

	-- Check if a a charachter is a number
	local function isNumber( v )
		return v:find( "[0-9]" ) ~= nil
	end

	-- Check if a charachter is a whitespace
	local function isWhitespace( v )
		return v:find( "[ \n\t\r]" ) ~= nil
	end

	-- Check if a charachter is a precedence?
	local function isPrec( v )
		return v:find( "[:%(%);,%{%}]" ) ~= nil
	end

	-- Check if a charachter is an operator
	local function isOp( v )
		return v:find( "[%+%-%*/%^%%<!=>]" ) ~= nil
	end

	-- do while loops until a certain charachter is met.
	local function doWhile( f )
		local str = ""
		while input.eof() == false and f( input.peek() ) do
			str = str .. input.next()
		end
		return str
	end

	-- Magic
	-- Create tokens from charachters
	local function n()
		doWhile( isWhitespace )
		local peek = input.peek()
		if peek == "" or peek == nil or input.eof() then
			return
		end
		if isWord( peek ) then
			return {
				type = "id";
				value = doWhile( word );
			}
		elseif isNumber( peek ) then
			return {
				type = "num";
				value = doWhile( isNumber );
			}
		elseif isPrec( peek ) then
			return {
				type = "prec";
				value = input.next();
			}
		elseif isOp( peek ) then
			return {
				type = "op";
				value = doWhile( isOp );
			}
		else
			error( "Line:"..input.getLine()..": Tokenizing error.", 0 )
		end
	end

	-- Object related stuff
	local ptr = nil
	local function _next()
		if ptr then
			local v = ptr
			ptr = nil
			return v
		else
			return n()
		end
	end

	local function p()
		if ptr == nil then
			ptr = n()
			return ptr
		else
			return ptr
		end
	end

	-- Return the object
	return {
		-- This is a hacky way to remove 'self' object.
		next = _next;
		peek = p;
		eof = function()
			return input.eof() and p() ~= nil
		end;
		error = function( msg )
			error( "Line:"..input.getLine()..": "..msg, 0 )
		end;
		getLine = input.getLine;
	}
end

--------------------------------------------------
-- Name: parse
--
-- Arguments:
--	tokens - tokenizer returned object
--
-- Description: parse the file that contains code.
--------------------------------------------------
local function parse( tokens )

	--------------------------------------------------
	-- Name: expect
	--
	-- Arguments:
	--	t - type of the expected token.
	--	v - value of the expected token (optional).
	--	e - error message on fail
	--
	-- Description: Expect a type, or value,
	-- if the type or value given is not equal
	-- throw an error.
	--------------------------------------------------
	local function expect( t, v, e )
		local peek = tokens.peek()
		if e then
			e = " "..e.."."
		end
		if peek.type == t then
			if v then
				if v == peek.value then
					tokens.next()
					return
				else
					tokens.error( "Expected: '" .. v .. "' (type: '" .. t .. "') got '" .. peek.type .. "' (value: '" .. v .. "')"..(e or ".") )
				end
			else
				return tokens.next()
			end
		else
			tokens.error( "Expected: '" .. t .. "' got '" .. peek.type .. "'"..(e or ".") )
		end
	end

	--------------------------------------------------
	-- Name: atom
	--
	-- Arguments: none
	--
	-- Description: Parse an atom.
	--------------------------------------------------
	local function atom()
		if tokens.peek() then
			if tokens.peek().type == "id" then
				local name = expect( "id", nil, "(Variable Fetch/Function call in Expression)" ).value
				if tokens.peek().value == '(' then
					return call( name )
				else
					return {
						type = "fetch",
						line = tokens.getLine(),
						name = name,
					}
				end
			elseif tokens.peek().type == "num" then
				return tokens.next()
			elseif tokens.peek().type == "prec" and tokens.peek().value == "(" then
				expect( "prec", "(", "(Binary Expression)" )
				local expr = expr()
				expect( "prec", ")", "(Binary Expression)" )
				return expr
			end
		end
	end

	local PRECEDENCE = {
		["||"] = 1,
		["&&"] = 2,
		["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["=="] = 3, ["!="] = 3,
		["+"] = 4, ["-"] = 4,
		["*"] = 5, ["/"] = 5, ["%"] = 5,
	}

	--------------------------------------------------
	-- Name: expr
	--
	-- Arguments:
	--	left - left atom (optional)
	--
	-- Description: Parse a mathematical expresion.
	--------------------------------------------------
	function expr( left, myPrec )
		local myPrec = myPrec or 0
		local left = left or atom()
		if tokens.peek() then
			if tokens.peek().type == "op" then
				local otherPrec = PRECEDENCE[ tokens.peek().value ]
				if otherPrec > myPrec then
					local op = tokens.next().value
					return expr( {
						type = "expr",
						line = tokens.getLine(),
						op = op,
						left = left,
						right = expr( atom(), otherPrec )
					}, myPrec )
				end
			end
		end
		return left
	end

	--------------------------------------------------
	-- Name: defargs
	--
	-- Arguments: none
	--
	-- Description: Parse definition arguments,
	-- for example to a function definition.
	--------------------------------------------------
	local function defargs()
		expect( "prec", "(", "(Argument Definition)" )
		local args = {}
		while tokens.eof() == false and not (tokens.peek().type == "prec" and tokens.peek().value == ")") do
			local id = expect( "id" )
			args[ #args + 1 ] = id
			if tokens.peek().type == "prec" then
				if tokens.peek().value == ")" then
					break
				elseif tokens.peek().value == "," then
					tokens.next()
				else
					tokens.error( "comma(,) expected in argument definition." )
				end
			end
		end
		expect( "prec", ")", "(Argument Definition)" )
		return args
	end

	--------------------------------------------------
	-- Name: vardef
	--
	-- Arguments: none
	--
	-- Description: Parse a variable definition
	-- statement.
	--------------------------------------------------
	local function vardef()
		expect( "id", "var", "(Expected keyword 'var')" )
		local name = expect( "id", nil, "(Variable Definition in 'var')" ).value
		expect( "op", "=", "(Expected keyword 'var')" )
		return {
			type = "vardef";
			line = tokens.getLine(),
			name = name;
			expr = expr();
		}
	end

	--------------------------------------------------
	-- Name: varset
	--
	-- Arguments: none
	--
	-- Description: Parse a variable definition
	-- statement.
	--------------------------------------------------
	local function varset( name )
		local name = name or expect( "id", nil, "(Variable Definition in 'var')" ).value
		expect( "op", "=", "(Expected keyword 'var')" )
		return {
			type = "vardef";
			line = tokens.getLine(),
			name = name;
			expr = expr();
		}
	end

	--------------------------------------------------
	-- Name: call
	--
	-- Arguments:
	--	name - name of the function (optional).
	--
	-- Description: Parse a function call with
	-- arguments as expressions.
	--------------------------------------------------
	function call( name )
		local name = name or expect( "id", nil, "(Function Call)" ).value
		local args = {}
		expect( "prec", '(' )
		while tokens.eof() == false do
			if tokens.peek() == nil then
				break
			end
			args[ #args + 1 ] = expr()
			if tokens.peek() then
				if tokens.peek().type == "prec" then
					if tokens.peek().value == "," then
						tokens.next()
					else
						break
					end
				else
					break
				end
			else
				break
			end
		end
		expect( "prec", ')' )

		return {
			type = "call",
			line = tokens.getLine(),
			name = name,
			args = args
		}
	end

	--------------------------------------------------
	-- Name: toasm
	--
	-- Arguments: none
	--
	-- Description: Parse a block that contains
	-- asm code.
	--------------------------------------------------
	local function toasm()
		expect( "id", "__asm__" )
		expect( "prec", '{' )
		local asmCode = ""
		while tokens.eof() == false do
			if tokens.peek().type == "id" or tokens.peek().type == "num" or (tokens.peek().type == "prec" and (tokens.peek().value == ":" or tokens.peek().value == ",")) then
				asmCode = asmCode .. tokens.next().value .. " "
			elseif tokens.peek().value == "}" then
				break
			else
				tokens.error( "Unexpected error compiling ASM code." )
			end
		end
		expect( "prec", '}' )
		return {
			type = "asmcode",
			line = tokens.getLine(),
			asmCode = asmCode;
		}
	end

	--------------------------------------------------
	-- Name: funifbction
	--
	-- Arguments: none
	--
	-- Description: Parse a if block statement.
	--------------------------------------------------
	local function ifb()
		expect( "id", "if" )
		local cond = expr()
		local tb = block()
		local el
		if tokens.peek() then
			if tokens.peek().value == "else" then
				expect( "id", "else" )
				if tokens.peek().value == "if" then
					el = ifb()
				else
					el = block()
				end
			end
		end
		return {
			type = "ifblock",
			line = tokens.getLine(),
			cond = cond,
			trueblock = tb,
			elseblock = el,
		}
	end

	--------------------------------------------------
	-- Name: whileb
	--
	-- Arguments: none
	--
	-- Description: Parse a while block statement.
	--------------------------------------------------
	local function whileb()
		expect( "id", "while" )
		return {
			type = "whileblock",
			line = tokens.getLine(),
			cond = expr(),
			body = block(),
		}
	end

	--------------------------------------------------
	-- Name: def
	--
	-- Arguments: none
	--
	-- Description: Parse a one line function definition.
	-- It only takes an expression which will be returned
	-- automatically.
	--------------------------------------------------
	local function def()
		expect( "id", "def" )
		local name = expect( "id" ).value
		local args = defargs()
		expect( "op", "=" )
		return {
			type = "defunc",
			line = tokens.getLine(),
			name = name,
			args = args,
			body = expr()
		}
	end

	--------------------------------------------------
	-- Name: ret
	--
	-- Arguments: none
	--
	-- Description: Parse a return statement.
	--------------------------------------------------
	local function ret()
		expect( "id", "return" )
		return {
			type = "return",
			line = tokens.getLine(),
			value = expr();
		}
	end

	--------------------------------------------------
	-- Name: function
	--
	-- Arguments: none
	--
	-- Description: Parse a function that takes arguments
	-- and a block of code.
	--------------------------------------------------
	local function func()
		expect( "id", "func" )
		return {
			type = "defunc",
			line = tokens.getLine(),
			name = expect( "id" ).value,
			args = defargs(),
			body = block()
		}
	end

	--------------------------------------------------
	-- Name: block
	--
	-- Arguments: none
	--
	-- Description: Parse a block of code.
	--------------------------------------------------
	function block()
		expect( "prec", '{' )
		local prog = {}
		while tokens.eof() == false do
			if tokens.peek() then
				if tokens.peek().value == "var" then
					prog[ #prog + 1 ] = vardef()
				elseif tokens.peek().value == "def" then
					prog[ #prog + 1 ] = def()
				elseif tokens.peek().value == "return" then
					prog[ #prog + 1 ] = ret()
				elseif tokens.peek().value == "if" then
					prog[ #prog + 1 ] = ifb()
				elseif tokens.peek().value == "while" then
					prog[ #prog + 1 ] = whileb()
				elseif tokens.peek().value == "__asm__" then
					prog[ #prog + 1 ] = toasm()
				elseif tokens.peek().value == "}" then
					break
				else
					local name = expect( "id" ).value
					if tokens.peek().type == "op" then
						prog[ #prog + 1 ] = varset( name )
					else
						prog[ #prog + 1 ] = call( name )
					end
				end
			else
				break
			end
		end
		expect( "prec", '}' )
		return {
			type = "block",
			line = tokens.getLine(),
			block = prog
		}
	end

	--------------------------------------------------
	-- Name: library
	--
	-- Arguments: none
	--
	-- Description: Parse a code file which
	-- can contain only functions and var definitions.
	--------------------------------------------------
	local function library()
		local globals = {}
		local functions = {}
		while tokens.eof() == false do

			if tokens.peek() then
				if tokens.peek().value == "var" then
					globals[ #globals + 1 ] = vardef()
				elseif tokens.peek().value == "def" then
					functions[ #functions + 1 ] = def()
				elseif tokens.peek().value == "func" then
					functions[ #functions + 1 ] = func()
				elseif tokens.peek().value == "__asm__" then
					prog[ #prog + 1 ] = toasm()
				else
					tokens.error( "Cannot parse the file in top-level. Unexpected expression encountered." )
				end
			else
				break
			end
		end
		return {
			type = "library",
			line = tokens.getLine(),
			globals = globals,
			functions = functions
		}
	end

	-- Return the library as an AST Tree.
	return library()
end

-- Output object that pushes asm code
local function output()
	return {

		-- Make ASM code pretty with concatination
		push = function( self, ... )
			local topush = { ... }
			local args = table.concat( topush, ", ", 2 )
			self[ #self + 1 ] = topush[ 1 ].." "..args
		end;
		pop = function( self )
			local v = self[ #self ]
			self[ #self ] = nil
			return v
		end;
	}
end

local out, gVars, ifcount, usedReturn

--------------------------------------------------
-- Name: environment
--
-- Arguments:
--	parent - a parent environment object.
--
-- Description: create a variable and function
-- environemnt which can have a parent
-- environment.
--------------------------------------------------
local function environment( parent )
	return {
		parent = parent;
		variables = {};
		localCount = 0;
		define = function( self, tree, varType, value )
			self.variables[ tree.name ] = {
				type = varType,
				value = value
			}
		end;
		lookup = function( self, tree )
			local current = self
			while current ~= nil do
				if current.variables[ tree.name ] then
					return current
				else
					current = current.parent
				end
			end
			error( "Line:"..tree.line..": Variable '"..tree.name.."' not found.", 0 )
		end;
		get = function( self, tree )
			local current = self:lookup( tree )
			return current.variables[ tree.name ]
		end;
	}
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
		out = output()
		gVars = environment()
		ifcount = 0
		usedReturn = false
		out:push( "alias", "ra", "V0" )
		out:push( "alias", "rb", "V1" )
		out:push( "alias", "rc", "V2" )
		out:push( "alias", "il", "V8" )
		out:push( "alias", "ih", "V9" )
		out:push( "alias", "rI", "VC" )
		out:push( "alias", "rBP", "VB" )
		out:push( "alias", "rSP", "VD" )
		out:push( "alias", "rPC", "VE" )
		for i=1, #tree.globals do
			compile( tree.globals[ i ] )
		end
		out:push( "LD", "il", "libEnd.low" )
		out:push( "LD", "ih", "libEnd.high" )
		out:push( "LDI", "ih", "il" )
		out:push( "LD", "rPC", "rI" )
		for i=1, #tree.functions do
			compile( tree.functions[ i ] )
		end
		out:push( "libEnd:" )
		if gVars:get( {name="main"} ).type == "function" then
			out:push( "LD", "il", "func_main.low" )
			out:push( "LD", "ih", "func_main.high" )
			out:push( "LDI", "ih", "il" )
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
			out:push( "LD", "il", "var_"..tree.name..".low" )
			out:push( "LD", "ih", "var_"..tree.name..".high" )
			out:push( "LDI", "ih", "il" )
			out:push( "LD", "[I]", "ra" )
		end
	elseif tree.type == "defunc" then
		out:push( "func_"..tree.name..":" )
		out:push( "PUSH", "rBP" )
		out:push( "LD", "rBP", "rSP" )
		gVars:define( tree, "function" )
		gVars = environment( gVars )
		for i=1, #tree.args do
			gVars:define( {name=tree.args[ i ].value}, "local_variable", -i )
		end
		compile( tree.body, "function" )
		for i=1, gVars.localCount do
			out:push( "POP", "V5" )
		end
		if usedReturn == false then
			out:push( "POP", "rBP" )
			out:push( "RET" )
		end
		gVars = gVars.parent
		usedReturn = false
	elseif tree.type == "return" then
		usedReturn = true
		compile( tree.value )
	elseif tree.type == "call" then
		if tree.name == "draw" then
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
				out:push( "LD", "il", "func_" .. tree.name .. ".low" )
				out:push( "LD", "ih", "func_" .. tree.name .. ".high" )
				out:push( "LDI", "ih", "il" )
				out:push( "CALL", "I" )
			end
		end
	elseif tree.type == "ifblock" then
		local currifcount = ifcount
		ifcount = ifcount + 1
		out:push( "LD", "il", "if_"..currifcount..".low" )
		out:push( "LD", "ih", "if_"..currifcount..".high" )
		out:push( "LDI", "ih", "il" )
		compile( tree.cond )
		out:push( "LD", "rPC", "rI" )

		local elseblock = false
		if tree.elseblock then
			out:push( "LD", "il", "ifelse_"..currifcount..".low" )
			out:push( "LD", "ih", "ifelse_"..currifcount..".high" )
			out:push( "LDI", "ih", "il" )
			out:push( "LD", "rPC", "rI" )
			elseblock = true
		else
			out:push( "LD", "il", "ifend_"..currifcount..".low" )
			out:push( "LD", "ih", "ifend_"..currifcount..".high" )
			out:push( "LDI", "ih", "il" )
			out:push( "LD", "rPC", "rI" )
		end

		out:push( "if_"..currifcount..":" )
		compile( tree.trueblock )

		out:push( "LD", "il", "ifend_"..currifcount..".low" )
		out:push( "LD", "ih", "ifend_"..currifcount..".high" )
		out:push( "LDI", "ih", "il" )
		out:push( "LD", "rPC", "rI" )

		if tree.elseblock then
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
		end
		if tree.right.type == "num" then
			out:push( "LD", "rb", compile( tree.right ) )
		else
			compile( tree.right, 0 )
			local v = compile( tree.left, 1 )
			if v then
				out:push( "LD", "rb", v )
			end
		end
		if tree.op == "+" then
			out:push( "ADD", "ra", "rb" )
		elseif tree.op == "-" then
			out:push( "SUB", "ra", "rb" )
		elseif tree.op == "*" then
			out:push( "MUL", "ra", "rb" )
		elseif tree.op == "/" then
			out:push( "DIV", "ra", "rb" )
		elseif tree.op == "%" then
			out:push( "MOD", "ra", "rb" )
		elseif tree.op == "^" then
			out:push( "POW", "ra", "rb" )
		elseif tree.op == ">" then
			out:push( "SUBN", "ra", "rb" )
			out:push( "SE", "VF", "0x1" )
		elseif tree.op == "<" then
			out:push( "SUB", "ra", "rb" )
			out:push( "SE", "VF", "0x1" )
		elseif tree.op == ">=" then
			out:push( "SUBN", "ra", "rb" )
			out:push( "SE", "ra", "0x0" )
			out:push( "SE", "VF", "0x1" )
		elseif tree.op == "<=" then
			out:push( "SUB", "ra", "rb" )
			out:push( "SE", "ra", "0x0" )
			out:push( "SE", "VF", "0x1" )
		elseif tree.op == "==" then
			out:push( "SNE", "ra", "rb" )
		elseif tree.op == "!=" then
			out:push( "SE", "ra", "rb" )
		end
	elseif tree.type == "fetch" then
		if gVars:get( tree ).type == "global_variable" then
			out:push( "LD", "il", "var_"..tree.name..".low" )
			out:push( "LD", "ih", "var_"..tree.name..".high" )
			out:push( "LDI", "ih", "il" )
			if reg == 0 then
				out:push( "LD", "ra", "[I]" )
			else
				out:push( "LD", "rb", "[I]" )
			end
		else
			local var = gVars:get( tree )
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
	elseif tree.type == "num" then
		return tree.value
	end
end

return {
	create = function( file, out )
		--local co, err = coroutine.create( function()
			local contents, size = love.filesystem.read( file )
			local parsed = parse( tokenize( wrapper( contents ) ) )
			print( parsed )
			local compiled = compile( parsed )
			print( compiled )
			love.filesystem.write( out, table.concat( compiled, "\n" ) )
		--end )
		--while coroutine.status( co ) == "suspended" do
		--	local ok, err = coroutine.resume( co )
		--	if not ok then return err end
		--end
	end
}