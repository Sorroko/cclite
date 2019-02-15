FileSystem = class('FileSystem')

function startsWith(str, testStr)
	return testStr == string.sub(str, 1, #testStr)
end

function FileSystem.static.deleteTree(sFolder)
	log("FileSystem -> deleteTree(): source - " .. tostring(sFolder))
	local tObjects = love.filesystem.getDirectoryItems(sFolder)

	if tObjects then
   		for nIndex, sObject in pairs(tObjects) do
	   		local pObject =  sFolder.."/"..sObject

			if love.filesystem.isFile(pObject) then
				love.filesystem.remove(pObject)
			elseif love.filesystem.getInfo(pObject).type == "directory" then
				FileSystem.deleteTree(pObject)
			end
		end
	end
	return love.filesystem.remove(sFolder)
end

function FileSystem.static.copyTree(sFolder, sToFolder)
	log("FileSystem -> deleteTree(): source - " .. tostring(sFolder) .. ", destination - " .. tostring(sToFolder))
	FileSystem.deleteTree(sToFolder) -- Overwrite existing file for both copy and move
	-- Is this vanilla behaviour or does it merge files?
	if not love.filesystem.getInfo(sFolder).type == "directory" then
		love.filesystem.write(sToFolder, love.filesystem.read( sFolder ))
	end
	local tObjects = love.filesystem.getDirectoryItems(sFolder)

	if tObjects then
   		for nIndex, sObject in pairs(tObjects) do
	   		local pObject =  sFolder.."/"..sObject

			if love.filesystem.isFile(pObject) then
				love.filesystem.write(sToFolder .. "/" .. sObject, love.filesystem.read( pObject ))
			elseif love.filesystem.getInfo(pObject).type == "directory" then
				FileSystem.copyTree(pObject)
			end
		end
	end
end

function FileSystem.static.cleanPath( sPath )
	sPath = "/" .. sPath
	local tPath = {}
	for part in sPath:gmatch("[^/]+") do
	   	if part ~= "" and part ~= "." then
	   		if part == ".." then
	   			if #tPath > 0 then table.remove(tPath) end
	   		else
	   			table.insert(tPath, part)
	   		end
	   	end
	end
	return "/" .. table.concat(tPath, "/")
end

function FileSystem:initialize( bCache )
	log("FileSystem -> initialize()")
	if bCache then log("FileSystem: Cache enabled, this may cause strange filesystem issues.", "WARNING") end
	self.mountMap = {}
	self.cache = {
		find = {},
		list = {}
	}

	-- EXPERIMENTAL: DO NOT ENABLE.
	self.enableCache = bCache or false -- TODO: Cache should be updated by file changes. (move, copy, delete, write)

	self:mount("/", "/data") -- Do not include trailing slash in paths!
	self:mount("/rom", "/lua/rom", {readOnly = true})
	self:mount("/treasure", "/lua/treasure", {readOnly = true})
	if _DEBUG then self:mount("/debug", "/lua/debug", {readOnly = true}) end
end

function FileSystem:mount(sMount, sPath, tFlags) -- Assume clean paths
	log("FileSystem -> mount(): Mounted '" .. tostring(sPath) .. "'' at '" .. tostring(sMount) .. "'")
	if (not sMount) or (not sPath) then return end
	tFlags = tFlags or {}
	self.mountMap[sMount] = { sMount, sPath, tFlags }
end

function FileSystem:unmount(sPath) -- Assume clean path
	log("FileSystem -> unmount(): Unmounted '" .. tostring(sPath) .. "'")
	self.mountMap[sMount] = nil
end

function FileSystem:find(sPath)
	if self.enableCache and self.cache.find[sPath] then
		return unpack(self.cache.find[sPath])
	end

	local _sMount, _sPath, _tFlags
	for k, v in pairs(self.mountMap) do
		_sMount = v[1]
		_sPath = v[2]
		_tFlags = v[3]
		if startsWith(sPath, _sMount) then
			local bPath = string.sub(sPath, #_sMount + 1, -1)
			if love.filesystem.getInfo(_sPath .. "/" .. bPath) then
				if self.enableCache then
					self.cache.find[sPath] = { _sPath .. "/" .. bPath, _sMount }
				end
				return _sPath .. "/" .. bPath, _sMount
			end
		end
	end
	return nil
end

function FileSystem:isReadOnly(sPath)
	local file, mount = self:find(sPath)
	if not file then return nil end

	local flags = self.mountMap[mount][3]
	return flags.readOnly or false
end

function FileSystem:isDirectory(sPath)
	local file, mount = self:find(sPath)
	if not file then return false end -- false or nil?

	return love.filesystem.getInfo(file).type == "directory"
end

function FileSystem:open( sPath, sMode )
	log("FileSystem -> open(): Path '" .. tostring(sPath) .. "' with mode " .. tostring(sMode))
	if sMode == "r" then
		local file, mount = self:find(sPath)
		if not file then return end
		local iterator = love.filesystem.lines(file)

		local handle = {}
		function handle.close()
			handle = nil
		end
		function handle.readLine()
			return iterator()
		end
		function handle.readAll()
			if lineIndex == 1 then
				lineIndex = #contents
				return table.concat(contents, '\n') .. '\n'
			else
				local data = ""
				for line in iterator do
  					data = data .. line .. "\n"
				end
				return data:sub(1, -2)
			end
		end
		return handle
	elseif sMode == "w" then
		if self:isReadOnly(sPath) then return nil end

		local sData = ""

		local handle = {}
		function handle.close()
			love.filesystem.write("/data" .. sPath, sData)
			handle = nil -- this does not properly destory the object
		end
		function handle.flush()
			if not love.filesystem.exists("/data" .. sPath) then
				love.filesystem.write("/data" .. sPath, sData)
				sData = ""
			else
				-- Append any new additions
				love.filesystem.append( "/data" .. sPath, sData )
			end
		end
		function handle.writeLine( data )
			data = tostring(data)
			sData = sData .. data .. "\n"
		end
		function handle.write( data )
			data = tostring(data)
			sData = sData .. data
		end
		return handle
	elseif sMode == "a" then
		if not self:find(sPath) then return end
		if self:isReadOnly(sPath) then return nil end

		local sData = ""

		local handle = {}
		function handle.close()
			love.filesystem.append( "/data" .. sPath, sData )
			handle = nil
		end
		function handle.flush()
			love.filesystem.append( "/data" .. sPath, sData )
			sData = ""
		end
		function handle.writeLine( data )
			data = tostring(data)
			sData = sData .. data .. "\n"
		end
		function handle.write( data )
			data = tostring(data)
			sData = sData .. data
		end
		return handle
	end
end

function FileSystem:makeDirectory(sPath)
	log("FileSystem -> makeDirectory(): " .. tostring(sPath))
	local file, mount = self:find(sPath)
	if file then return false end

	return love.filesystem.createDirectory("/data" .. sPath)
end

function FileSystem:copy( fromPath, toPath )
	local fFile, fMount = self:find(fromPath)
	local tFile, tMount = self:find(toPath)

	if not fFile then return nil end
	if tFile then
		if self.mountMap[tMount][3].readOnly then return nil end
		if not self:delete(tFile) then return nil end
	end

	return FileSystem.copyTree(fFile, "/data" .. toPath)
end

function FileSystem:delete( sPath )
	local file, mount = self:find(sPath)
	if not file then return nil end
	if self.mountMap[mount][3].readOnly then return nil end

	return FileSystem.deleteTree(file)
end

function FileSystem:list( sPath )
	if self.enableCache and self.cache.list[sPath] then
		return self.cache.list[sPath]
	end

	local res = {}

	for k, mount in pairs(self.mountMap) do
		local rootdir, file = string.match(mount[1], "(.-)([^\\/]-%.?([^%.\\/]*))$") -- Should not include the trailing slash! however it must have one at start
		if (rootdir == sPath or rootdir == sPath .. "/") and file ~= "" then -- Fix the trailing slash issue
			table.insert(res, file)
		end
	end

	local _sMount, _sPath, _tFlags
	for k, v in pairs(self.mountMap) do
		_sMount = v[1]
		_sPath = v[2]
		_tFlags = v[3]
		if startsWith(sPath, _sMount) then
			local bPath = string.sub(sPath, #_sMount + 1, -1)
			local fsPath = _sPath .. "/" .. bPath
			if love.filesystem.getInfo(fsPath) and love.filesystem.getInfo(fsPath).type == "directory" then
				local items = love.filesystem.getDirectoryItems(fsPath)
				for k,_v in pairs(items) do table.insert(res, _v) end
			end
		end
	end
	self.cache.list[sPath] = res
	return res
end
