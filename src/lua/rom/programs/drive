local tArgs = { ... }

-- Get where a directory is mounted
local sPath = shell.dir()
if tArgs[1] ~= nil then
	sPath = shell.resolve( tArgs[1] )
end

if fs.exists( sPath ) then
	write( fs.getDrive( sPath ) .. " (" )
	local nSpace = fs.getFreeSpace( sPath )
	if nSpace > 1024 * 1024 then
		print( (math.floor( nSpace / (100 * 1000) ) / 10) .. "MB remaining)" )
	elseif nSpace > 1024 then
		print( math.floor( nSpace / 1000 ) .. "KB remaining)" )
	else
		print ( nSpace .. "B remaining)" )
	end
else
	print( "No such path" )
end
