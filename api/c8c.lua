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
		return v:find( "[%+%-%*/=]" ) ~= nil
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
						value = name,
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

	--------------------------------------------------
	-- Name: expr
	--
	-- Arguments:
	--	left - left atom (optional)
	--
	-- Description: Parse a mathematical expresion.
	--------------------------------------------------
	function expr( left )
		local left = left or atom()
		if tokens.peek() then
			if tokens.peek().type == "op" then
				local op = tokens.next().value
				return {
					type = "expr",
					op = op,
					left = left,
					right = expr()
				}
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
		while tokens.eof() == false do
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
	-- Name: var
	--
	-- Arguments: none
	--
	-- Description: Parse a variable definition
	-- statement.
	--------------------------------------------------
	local function var()
		expect( "id", "var", "(Expected keyword 'var')" )
		local name = expect( "id", nil, "(Variable Definition in 'var')" ).value
		expect( "op", "=", "(Expected keyword 'var')" )
		local value = expr()
		return {
			type = "vardef";
			name = name;
			expr = value;
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
		if tokens.peek().value == "else" then
			expect( "id", "else" )
			if tokens.peek().value == "if" then
				el = ifb()
			else
				el = block()
			end
		end
		return {
			type = "ifblock",
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
		local cond = expr()
		local b = block()
		return {
			type = "whileblock",
			cond = cond,
			body = b,
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
		local value = expr()
		return {
			type = "defunc",
			name = name,
			args = args,
			body = value
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
		local v = expr()
		return {
			type = "return",
			value = v;
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
		local name = expect( "id" ).value
		local args = defargs()
		local block = block()
		return {
			type = "defunc",
			name = name,
			args = args,
			body = block
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
					prog[ #prog + 1 ] = var()
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
					prog[ #prog + 1 ] = call()
				end
			else
				break
			end
		end
		expect( "prec", '}' )
		return {
			type = "block",
			block = prog
		}
	end

	--------------------------------------------------
	-- Name: program
	--
	-- Arguments: none
	--
	-- Description: Parse a program which
	-- can contain any
	-- block of code ( functions included ).
	--------------------------------------------------
	local function program()
		local prog = {}
		while tokens.eof() == false do

			if tokens.peek() then
				if tokens.peek().value == "var" then
					prog[ #prog + 1 ] = var()
				elseif tokens.peek().value == "def" then
					prog[ #prog + 1 ] = def()
				elseif tokens.peek().value == "if" then
					prog[ #prog + 1 ] = ifb()
				elseif tokens.peek().value == "while" then
					prog[ #prog + 1 ] = whileb()
				elseif tokens.peek().value == "func" then
					prog[ #prog + 1 ] = func()
				elseif tokens.peek().value == "__asm__" then
					prog[ #prog + 1 ] = toasm()
				else
					prog[ #prog + 1 ] = call()
				end
			else
				break
			end
		end
		return {
			type = "program",
			program = prog
		}
	end

	-- Return the program as an AST Tree.
	return program()
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

local out

--------------------------------------------------
-- Name: compile
--
-- Arguments:
--	tree - a tree that the parser returned.
--
-- Description: compiles to assembly code
-- the parsed ast tree.
--------------------------------------------------
local function compile( tree )
	if tree.type == "program" then
		out = output()
		for i=1, #tree.program do
			compile( tree.program[ i ] )
		end
		return cprog
	elseif tree.type == "vardef" then
		compile( tree.expr )
		--out:push()
	elseif tree.type == "expr" then
		if tree.left.type == "num" and tree.right.type == "num" then
			-- cprog:push( INS.LDR, 0 )
			-- compile( tree.left )
		else
			compile( tree.left )
		end
		if tree.right.type == "num" then
			-- cprog:push(  )
			-- compile( tree.right )
		else
			-- compile( tree.right )
			-- cprog:push( INS.LDR, 1 )
			-- compile( tree.left )
		end
		if tree.op == "+" then
			--cprog:push( INS.ADD )
		end
	elseif tree.type == "num" then
		--cprog:push( tree.value )
	end
end

return {
	create = function( file )
		local contents, size = love.filesystem.read( file )
		return compile( parse( tokenize( wrapper( contents ) ) ) )
	end
}