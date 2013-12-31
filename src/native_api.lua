NativeAPI = class('NativeAPI')

--[[
	TODO
	FS api needs a rewrite! Better file handles!
	use new love 0.9.0 functions such as love.filesystem.append().
	Make os.clock accurate, (and not use love executions os.clock)
]]

-- HELPER FUNCTIONS
local function lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

local function deltree(sFolder)
	local tObjects = love.filesystem.getDirectoryItems(sFolder)

	if tObjects then
   		for nIndex, sObject in pairs(tObjects) do
	   		local pObject =  sFolder.."/"..sObject

			if love.filesystem.isFile(pObject) then
				love.filesystem.remove(pObject)
			elseif love.filesystem.isDirectory(pObject) then
				deltree(pObject)
			end
		end
	end
	return love.filesystem.remove(sFolder)
end

local function copytree(sFolder, sToFolder)
	deltree(sToFolder) -- Overwrite existing file for both copy and move
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
				copytree(pObject)
			end
		end
	end
end

-- HELPER CLASSES/HANDLES
-- TODO Make more efficient, use love.filesystem.lines
local function HTTPHandle(contents, status)
	local lineIndex = 1
	local handle -- INFO: Hack to access itself
	handle = {
		close = function()
			handle = nil
		end,
		readLine = function()
			local str = contents[lineIndex]
			lineIndex = lineIndex + 1
			return str
		end,
		readAll = function()
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
		end,
		getResponseCode = function()
			return status
		end
	}
	return handle
end

local function FileReadHandle(contents)
	local lineIndex = 1
	local handle
	handle = {
		close = function()
			handle = nil
		end,
		readLine = function()
			local str = contents[lineIndex]
			lineIndex = lineIndex + 1
			return str
		end,
		readAll = function()
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
	}
	return handle
end

local function FileWriteHandle(path)
	local sData = ""
	local handle = {
		close = function(data)
			love.filesystem.write(path, sData)
		end,
		writeLine = function( data )
			sData = sData .. data
		end,
		write = function ( data )
			sData = sData .. data
		end
	}
	return handle
end

function NativeAPI:initialize(_computer)
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
		}
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
		assert(text)
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
	self.env.fs.open = function(path, mode)
		assert(type(path) == "string")
		assert(type(mode) == "string")
		path = self.env.fs.combine("", path)
		if mode == "r" then
			local sPath = nil
			if love.filesystem.exists("data/" .. path) then
				sPath = "data/" .. path
			elseif love.filesystem.exists("lua/" .. path) then
				sPath = "lua/" .. path
			end
			if sPath == nil or sPath == "lua/bios.lua" then return nil end

			local contents, size = love.filesystem.read( sPath )

			return FileReadHandle(lines(contents))
		elseif mode == "w" then
			if self.env.fs.exists( path ) then -- Write mode overwrites! FIXME: Wait until handle.close() is called
				self.env.fs.delete( path )
			end

			return FileWriteHandle("data/" .. path)
		end
		return nil
	end
	self.env.fs.list = function(path)
		assert(type(path) == "string")
		path = self.env.fs.combine("", path)
		local res = {}
		if love.filesystem.exists("data/" .. path) then -- This path takes precedence
			res = love.filesystem.getDirectoryItems("data/" .. path)
		end
		if love.filesystem.exists("lua/" .. path) then
			for k, v in pairs(love.filesystem.getDirectoryItems("lua/" .. path)) do
				if v ~= "bios.lua" then table.insert(res, v) end
			end
		end
		return res
	end
	self.env.fs.exists = function(path)
		assert(type(path) == "string")
		if path == "/bios.lua" then return false end
		path = self.env.fs.combine("", path)
		return love.filesystem.exists("data/" .. path) or love.filesystem.exists("lua/" .. path)
	end
	self.env.fs.isDir = function(path)
		assert(type(path) == "string")
		path = self.env.fs.combine("", path)
		return love.filesystem.isDirectory("data/" .. path) or love.filesystem.isDirectory("lua/" .. path)
	end
	self.env.fs.isReadOnly = function(path)
		assert(type(path) == "string")
		path = self.env.fs.combine("", path)
		return string.sub(path, 1, 4) == "rom/"
	end
	self.env.fs.getName = function(path)
		assert(type(path) == "string")
		local fpath, name, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
		return name
	end
	self.env.fs.getDrive = function(path) return nil end
	self.env.fs.getSize = function(path) return nil end
	self.env.fs.getFreeSpace = function(path) return nil end
	self.env.fs.makeDir = function(path) -- All write functions are within data/
		assert(type(path) == "string")
		path = self.env.fs.combine("", path)
		if string.sub(path, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
			return love.filesystem.createDirectory( "data/" .. path )
		else return nil end
	end
	self.env.fs.move = function(fromPath, toPath)
		-- Not implemented
	end
	self.env.fs.copy = function(fromPath, toPath)
		assert(type(fromPath) == "string")
		assert(type(toPath) == "string")
		fromPath = self.env.fs.combine("", fromPath)
		toPath = self.env.fs.combine("", toPath)
		if string.sub(toPath, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
			return copytree("data/" .. fromPath, "data/" .. toPath)
		else return nil end
	end
	self.env.fs.delete = function(path)
		assert(type(path) == "string")
		path = self.env.fs.combine("", path)
		if string.sub(path, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
			return deltree( "data/" .. path )
		else return nil end
	end
	self.env.fs.combine = function(basePath, localPath)
		assert(type(basePath) == "string")
		assert(type(localPath) == "string")
		local path = "/" .. basePath .. "/" .. localPath
		local tPath = {}
		for part in path:gmatch("[^/]+") do
	   		if part ~= "" and part ~= "." then
	   			if part == ".." and #tPath > 0 then
	   				table.remove(tPath)
	   			else
	   				table.insert(tPath, part)
	   			end
	   		end
		end
		return table.concat(tPath, "/")
	end
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
		        local handle = HTTPHandle(lines(http.responseText), http.status)
		        table.insert(self.computer.eventQueue, { "http_success", sUrl, handle })
		    else
		    	table.insert(self.computer.eventQueue, { "http_failure", sUrl })
		    end
		end

		http.send(sParams)
	end
	self.env.rs = self.env.redstone -- Not sure why this isn't in bios?!?! what was dan thinking
	self.env._G = self.env
end
