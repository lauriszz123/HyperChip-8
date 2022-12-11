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
	-- statement. Can be an array.
	--------------------------------------------------
	local function vardef()
		expect( "id", "var", "(Expected keyword 'var')" )
		local name = expect( "id", nil, "(Variable Definition in 'var')" ).value
		if tokens.peek().value == "[" then
			expect( "prec", '[' )
			local size = expect( "num" ).value
			expect( "prec", ']' )
			expect( "op", "=", "(Expected keyword 'var')" )
			return {
				type = "arraydef";
				line = tokens.getLine(),
				name = name;
				size = size;
				expr = expr();
			}
		else
			expect( "op", "=", "(Expected keyword 'var')" )
			return {
				type = "vardef";
				line = tokens.getLine(),
				name = name;
				expr = expr();
			}
		end
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
			type = "varset";
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
			block = block(),
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
				elseif tokens.peek().value == "return" then
					prog[ #prog + 1 ] = ret()
				elseif tokens.peek().value == "if" then
					prog[ #prog + 1 ] = ifb()
				elseif tokens.peek().value == "while" then
					prog[ #prog + 1 ] = whileb()
				elseif tokens.peek().value == "__asm__" then
					prog[ #prog + 1 ] = toasm()
				elseif tokens.peek().value == "break" then
					prog[ #prog + 1 ] = {
						type = "break",
					}
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

return {
	parse = function( tokens )
		return parse( tokens )
	end;
}