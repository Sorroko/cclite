NativeAPI = class('NativeAPI')

--[[
	TODO
	Make os.clock accurate, (and not use love executions os.clock)
	term.write with correct formatting of lua types. https://github.com/Sorroko/cclite/issues/12
	Make errors returned accurate
]]

-- Wrapper that adds error level to assert.
function assert(test, msg, level, ...)
  if test then return test, msg, level, ... end
  error(msg, (level or 1) + 1) -- +1 is for this wrapper
end

function string.startsWith(_self, testStr)
	return testStr == string.sub(_self, 1, #testStr)
end

FileSystem = class('FileSystem')

function FileSystem.static.deleteTree(sFolder)
	log("FileSystem -> deleteTree(): source - " .. tostring(sFolder))
	local tObjects = love.filesystem.getDirectoryItems(sFolder)

	if tObjects then
   		for nIndex, sObject in pairs(tObjects) do
	   		local pObject =  sFolder.."/"..sObject

			if love.filesystem.isFile(pObject) then
				love.filesystem.remove(pObject)
			elseif love.filesystem.isDirectory(pObject) then
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
	if not love.filesystem.isDirectory(sFolder) then
		love.filesystem.write(sToFolder, love.filesystem.read( sFolder ))
	end
	local tObjects = love.filesystem.getDirectoryItems(sFolder)

	if tObjects then
   		for nIndex, sObject in pairs(tObjects) do
	   		local pObject =  sFolder.."/"..sObject

			if love.filesystem.isFile(pObject) then
				love.filesystem.write(sToFolder .. "/" .. sObject, love.filesystem.read( pObject ))
			elseif love.filesystem.isDirectory(pObject) then
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
	   		if part == ".." and #tPath > 0 then
	   			table.remove(tPath)
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
		if sPath:startsWith(_sMount) then
			local bPath = string.sub(sPath, #_sMount + 1, -1)
			if love.filesystem.exists(_sPath .. "/" .. bPath) then
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

	return love.filesystem.isDirectory(file)
end

function FileSystem:open( sPath, sMode ) -- TODO: Compact this code
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
  					data = data .. "\n" .. line
				end
				data = data .. "\n"
				return data
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
			sData = sData .. data .. "\n"
		end
		function handle.write( data )
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
			sData = sData .. data .. "\n"
		end
		function handle.write( data )
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

function FileSystem:list( sPath ) -- TODO: IMPORTANT: Make sure mount paths are added to items
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
		if sPath:startsWith(_sMount) then
			local bPath = string.sub(sPath, #_sMount + 1, -1)
			local fsPath = _sPath .. "/" .. bPath
			if love.filesystem.exists(fsPath) and love.filesystem.isDirectory(fsPath) then
				local items = love.filesystem.getDirectoryItems(fsPath)
				for k,_v in pairs(items) do table.insert(res, _v) end
			end
		end
	end
	self.cache.list[sPath] = res
	return res
end

local function HTTPHandle(contents, status)
	local lineIndex = 1
	local handle = {}
	function handle.close()
		handle = nil
	end
	function handle.readLine()
		local str = contents[lineIndex]
		lineIndex = lineIndex + 1
		return str
	end
	function handle.readAll()
		if lineIndex == 1 then
			lineIndex = #contents
			return table.concat(contents, '\n') .. '\n'
		else
			local tData = {}
			local data = handle.readLine()
			while data ~= nil do
				table.insert(tData, data)
				data = handle.readLine()
			end
			return table.concat(tData, '\n') .. '\n'
		end
	end
	function handle.getResponseCode()
		return status
	end
	return handle
end

function NativeAPI:initialize(_computer)
	log("NativeAPI -> initialize()")
	self.computer = _computer
	self.data = {
		term = {
			cursorX = 1,
			cursorY = 1,
			bg = 32768,
			fg = 1,
			blink = false,
		},
		os = {
			label = nil
		},
		fileSystem = FileSystem:new()
	}
	self.env = { -- TODO: Better way of copying? Include metatables too?
		_VERSION = "Lua 5.1",
		tostring = tostring,
		tonumber = tonumber,
		unpack = unpack,
		getfenv = getfenv,
		setfenv = setfenv,
		rawset = rawset,
		rawget = rawget,
		rawequal = rawequal,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		next = next,
		type = type,
		select = select,
		assert = assert,
		error = error,

		math = Util.deep_copy(math),
		string = Util.deep_copy(string),
		table = Util.deep_copy(table),
		coroutine = Util.deep_copy(coroutine),

		loadstring = function(str, source)
			local f, err = loadstring(str, source)
			if f then
				setfenv(f, self.env)
			end
			return f, err
		end,
	}
	-- CC apis (BIOS completes api.)
	self.env.term = {}
	self.env.term.native = {}
	self.env.term.native.clear = function()
		for y = 1, Screen.height do
			for x = 1, Screen.width do
				self.computer.textB[y][x] = " "
				self.computer.backgroundColourB[y][x] = self.data.term.bg
				self.computer.textColourB[y][x] = 1 -- Don't need to bother setting text color
			end
		end
	end
	self.env.term.native.clearLine = function()
		for x = 1, Screen.width do
			self.computer.textB[self.data.term.cursorY][x] = " "
			self.computer.backgroundColourB[self.data.term.cursorY][x] = self.data.term.bg
			self.computer.textColourB[self.data.term.cursorY][x] = 1 -- Don't need to bother setting text color
		end
	end
	self.env.term.native.getSize = function()
		return Screen.width, Screen.height
	end
	self.env.term.native.getCursorPos = function()
		return self.data.term.cursorX, self.data.term.cursorY
	end
	self.env.term.native.setCursorPos = function(x, y)
		assert(type(x) == "number")
		assert(type(y) == "number")
		self.data.term.cursorX = math.floor(x)
		self.data.term.cursorY = math.floor(y)
	end
	self.env.term.native.write = function( text )
		text = tostring(text)
		if self.data.term.cursorY > Screen.height
			or self.data.term.cursorY < 1 then return end

		for i = 1, #text do
			local char = string.sub( text, i, i )
			if self.data.term.cursorX + i - 1 <= Screen.width
				and self.data.term.cursorX + i - 1 >= 1 then
				self.computer.textB[self.data.term.cursorY][self.data.term.cursorX + i - 1] = char
				self.computer.textColourB[self.data.term.cursorY][self.data.term.cursorX + i - 1] = self.data.term.fg
				self.computer.backgroundColourB[self.data.term.cursorY][self.data.term.cursorX + i - 1] = self.data.term.bg
			end
		end
		self.data.term.cursorX = self.data.term.cursorX + #text
	end
	self.env.term.native.setTextColor = function( num )
		assert(type(num) == "number")
		assert(Util.COLOUR_CODE[num] ~= nil)
		self.data.term.fg = num
	end
	self.env.term.native.setTextColour = self.env.term.native.setTextColor
	self.env.term.native.setBackgroundColor = function( num )
		assert(type(num) == "number")
		assert(Util.COLOUR_CODE[num] ~= nil)
		self.data.term.bg = num
	end
	self.env.term.native.setBackgroundColour = self.env.term.native.setBackgroundColor
	self.env.term.native.isColor = function()
		return true
	end
	self.env.term.native.isColour = self.env.term.native.isColor
	self.env.term.native.setCursorBlink = function( bool )
		assert(type(bool) == "boolean")
		self.data.term.blink = bool
	end
	self.env.term.native.scroll = function( n )
		assert(type(n) == "number")
		local textBuffer = {}
		local backgroundColourBuffer = {}
		local textColourBuffer = {}
		for y = 1, Screen.height do
			if y - n > 0 and y - n <= Screen.height then
				textBuffer[y - n] = {}
				backgroundColourBuffer[y - n] = {}
				textColourBuffer[y - n] = {}
				for x = 1, Screen.width do
					textBuffer[y - n][x] = self.computer.textB[y][x]
					backgroundColourBuffer[y - n][x] = self.computer.backgroundColourB[y][x]
					textColourBuffer[y - n][x] = self.computer.textColourB[y][x]
				end
			end
		end
		for y = 1, Screen.height do
			if textBuffer[y] ~= nil then
				for x = 1, Screen.width do
					self.computer.textB[y][x] = textBuffer[y][x]
					self.computer.backgroundColourB[y][x] = backgroundColourBuffer[y][x]
					self.computer.textColourB[y][x] = textColourBuffer[y][x]
				end
			else
				for x = 1, Screen.width do
					self.computer.textB[y][x] = " "
					self.computer.backgroundColourB[y][x] = self.data.term.bg
					self.computer.textColourB[y][x] = 1 -- Don't need to bother setting text color
				end
			end
		end
	end
	self.env.fs = {}
	self.env.fs.open = function(sPath, sMode)
		assert(type(sPath) == "string")
		assert(type(sMode) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:open(sPath, sMode)
	end
	self.env.fs.list = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:list(sPath)
	end
	self.env.fs.exists = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:find(sPath) ~= nil
	end
	self.env.fs.isDir = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:isDirectory(sPath)
	end
	self.env.fs.isReadOnly = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:isReadOnly(sPath)
	end
	self.env.fs.getName = function(sPath)
		assert(type(sPath) == "string")
		local fpath, name, ext = string.match(sPath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
		return name
	end
	self.env.fs.makeDir = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:makeDirectory(sPath)
	end
	self.env.fs.move = function(fromPath, toPath)
		assert(type(fromPath) == "string")
		assert(type(toPath) == "string")
		fromPath = FileSystem.cleanPath(fromPath)
		toPath = FileSystem.cleanPath(toPath)

		return self.data.fileSystem:copy(fromPath, toPath) and self.data.fileSystem:delete(fromPath)
	end
	self.env.fs.copy = function(fromPath, toPath)
		assert(type(fromPath) == "string")
		assert(type(toPath) == "string")
		fromPath = FileSystem.cleanPath(fromPath)
		toPath = FileSystem.cleanPath(toPath)

		return self.data.fileSystem:copy(fromPath, toPath)
	end
	self.env.fs.delete = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.data.fileSystem:delete(sPath)
	end
	self.env.fs.combine = function(basePath, localPath)
		assert(type(basePath) == "string")
		assert(type(localPath) == "string")
		local res = FileSystem.cleanPath(basePath .. "/" .. localPath)
		return string.sub(res, 2, #res)
	end
	self.env.fs.getDrive = function(sPath) return nil end -- TODO: A long with peripheral api
	self.env.fs.getSize = function(sPath) return nil end
	self.env.fs.getFreeSpace = function(sPath) return nil end
	self.env.os = {}
	self.env.os.clock = os.clock
	self.env.os.getComputerID = function() return 1 end
	self.env.os.setComputerLabel = function( label )
		assert(type(label) == "string")
		self.data.os.label = label
	end
	self.env.os.getComputerLabel = function()
		return self.data.label
	end
	self.env.os.computerLabel = self.env.os.getComputerLabel
	self.env.os.queueEvent = function( sEvent, ... )
		if sEvent ~= "string" then
			-- TODO: queueEvent() without an sEvent is possible in cc (I think) however it breaks our emulator.
			sEvent = "none"
		end
		table.insert(self.computer.eventQueue, { sEvent, ... })
	end
	self.env.os.startTimer = function(nTimeout)
		assert(type(nTimeout) == "number")
		local timer = {
			expires = love.timer.getTime() + nTimeout,
		}
		table.insert(self.computer.actions.timers, timer)
		for k, v in pairs(self.computer.actions.timers) do
			if v == timer then return k end
		end
		return nil -- Error
	end
	self.env.os.setAlarm = function(nTime)
		assert(type(nTime) == "number")
		if nTime < 0 or nTime > 24 then
			error( "Number out of range: " .. tostring( nTime ) )
		end
		local currentDay = self.computer.minecraft.day
		-- TODO: Revise this. Look into merging gamax92s changes.
		local alarm = {
			time = nTime,
			day = nTime <= self.computer.minecraft.time / 60 and currentDay + 1 or currentDay
		}
		table.insert(self.computer.actions.alarms, alarm)
		for k, v in pairs(self.computer.actions.alarms) do
			if v == alarm then return k end
		end
		return nil -- Error
	end
	self.env.os.time = function()
		return self.computer.minecraft.time / 60
	end
	self.env.os.day = function()
		return self.computer.minecraft.day
	end
	self.env.os.shutdown = function()
		self.computer:stop()
	end
	self.env.os.reboot = function()
		self.computer:stop(true)
	end
	self.env.redstone = {
		getSides = function() return { "top", "bottom", "left", "right", "front", "back" } end,
		getInput = function(side) return false end,
		setOutput = function(side, value) return end,
		getOutput = function(side) return false end,
		getAnalogInput = function(side) return 0 end,
		setAnalogOutput = function(side, value) return end,
		getAnalogOutput = function(side) return 0 end,
		getBundledInput = function(side) return 0 end,
		getBundledOutput = function(side) return 0 end,
		setBundledOutput = function(side, value) return end,
		testBundledInput = function(side, value) return false end,
	}
	self.env.peripheral = {
		isPresent = function(side) return false end,
		getNames = function() return {} end,
		getType = function(side) return nil end,
		getMethods = function(side) return nil end,
		call = function(side, method, ...) return nil end,
		wrap = function (side) return nil end,
	}
	self.env.http = {}
	self.env.http.request = function( sUrl, sParams )
		assert(type(sUrl) == "string")
		-- TODO: Is sParams a requirement?
		local http = HttpRequest.new()
		local method = sParams and "POST" or "GET"

		http.open(method, sUrl, true)

		if method == "POST" then
			http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
			http.setRequestHeader("Content-Length", string.len(sParams))
		end

		http.onReadyStateChange = function()
			if http.responseText then -- TODO: check if timed out instead
		        local handle = HTTPHandle(Util.lines(http.responseText), http.status)
		        table.insert(self.computer.eventQueue, { "http_success", sUrl, handle })
		    else
		    	table.insert(self.computer.eventQueue, { "http_failure", sUrl })
		    end
		end

		http.send(sParams)
	end
	self.env.rs = self.env.redstone -- Not sure why this isn't in bios?!?! what was dan thinking
	self.env._G = self.env

	if _DEBUG then
		log("NativeAPI: Debug api available. _G.emu", "WARNING")
		self.env.emu = {
			log = log,
			env = _G,
		}
	end
end
