local function tokenize( name )
	local file, size = love.filesystem.read( name )
	local word = ""
	local tokens = {}
	local i = 1
	while i <= #file do
		local c = file:sub( i,i )
		if c == '[' then
			i = i + 1
			tokens[ #tokens + 1 ] = "*"..file:sub( i,i )
			i = i + 1
			if file:sub( i,i ) ~= ']' then
				error( "Assembly error!", 0 )
			end
		elseif c:find( "[ \t\r\n,]" ) ~= nil then
			if #word > 0 then
				tokens[ #tokens + 1 ] = word
				word = ""
			end
		elseif c == ":" then
			if #word > 0 then
				tokens[ #tokens + 1 ] = ":"..word
				word = ""
			end
		else
			word = word .. c
		end
		i = i + 1
	end
	if #word > 0 then
		tokens[ #tokens + 1 ] = word
		word = ""
	end
	return tokens
end

return {
	tokenize = function( fn )
		return tokenize( fn )
	end;
}