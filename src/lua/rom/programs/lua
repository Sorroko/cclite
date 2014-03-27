
local tArgs = { ... }
if #tArgs > 0 then
	print( "This is an interactive Lua prompt." )
	print( "To run a lua program, just type its name." )
	return
end

local bRunning = true
local tCommandHistory = {}
local tEnv = {
	["exit"] = function()
		bRunning = false
	end,
	["_echo"] = function( ... )
	    return ...
	end,
}
setmetatable( tEnv, { __index = getfenv() } )

if term.isColour() then
	term.setTextColour( colours.yellow )
end
print( "Interactive Lua prompt." )
print( "Call exit() to exit." )
term.setTextColour( colours.white )

while bRunning do
	--if term.isColour() then
	--	term.setTextColour( colours.yellow )
	--end
	write( "lua> " )
	--term.setTextColour( colours.white )
	
	local s = read( nil, tCommandHistory )
	table.insert( tCommandHistory, s )
	
	local nForcePrint = 0
	local func, e = loadstring( s, "lua" )
	local func2, e2 = loadstring( "return _echo("..s..");", "lua" )
	if not func then
		if func2 then
			func = func2
			e = nil
			nForcePrint = 1
		end
	else
		if func2 then
			func = func2
		end
	end
	
	if func then
        setfenv( func, tEnv )
        local tResults = { pcall( func ) }
        if tResults[1] then
        	local n = 1
        	while (tResults[n + 1] ~= nil) or (n <= nForcePrint) do
        	    local value = tResults[ n + 1 ]
        	    if type( value ) == "table" then
            	    local ok, serialised = pcall( textutils.serialise, value )
            	    if ok then
            	        print( serialised )
            	    else
            	        print( tostring( value ) )
            	    end
            	else
            	    print( tostring( value ) )
            	end
        		n = n + 1
        	end
        else
        	printError( tResults[2] )
        end
    else
    	printError( e )
    end
    
end
