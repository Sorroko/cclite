NativeAPI = class('NativeAPI')

--[[
	TODO
	term.write with correct formatting of lua types. https://github.com/Sorroko/cclite/issues/12
	Make errors returned accurate
]]

-- Wrapper that adds error level to assert.
function assert(test, msg, level, ...)
  if test then return test, msg, level, ... end
  error(msg, (level or 1) + 1) -- +1 is for this wrapper
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
		if self.data.term.cursorY > Screen.height
			or self.data.term.cursorY < 1 then return end
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
			or self.data.term.cursorY < 1 then
			self.data.term.cursorX = self.data.term.cursorX + #text
			return
		end

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
		return self.computer.fileSystem:open(sPath, sMode)
	end
	self.env.fs.list = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:list(sPath)
	end
	self.env.fs.exists = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:find(sPath) ~= nil
	end
	self.env.fs.isDir = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:isDirectory(sPath)
	end
	self.env.fs.isReadOnly = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:isReadOnly(sPath)
	end
	self.env.fs.getName = function(sPath)
		assert(type(sPath) == "string")
		local fpath, name, ext = string.match(sPath, "(.-)([^\\/]-%.?([^%.\\/]*))$")
		return name
	end
	self.env.fs.makeDir = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:makeDirectory(sPath)
	end
	self.env.fs.move = function(fromPath, toPath)
		assert(type(fromPath) == "string")
		assert(type(toPath) == "string")
		fromPath = FileSystem.cleanPath(fromPath)
		toPath = FileSystem.cleanPath(toPath)

		return self.computer.fileSystem:copy(fromPath, toPath) and self.computer.fileSystem:delete(fromPath)
	end
	self.env.fs.copy = function(fromPath, toPath)
		assert(type(fromPath) == "string")
		assert(type(toPath) == "string")
		fromPath = FileSystem.cleanPath(fromPath)
		toPath = FileSystem.cleanPath(toPath)

		return self.computer.fileSystem:copy(fromPath, toPath)
	end
	self.env.fs.delete = function(sPath)
		assert(type(sPath) == "string")
		sPath = FileSystem.cleanPath(sPath)
		return self.computer.fileSystem:delete(sPath)
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
	self.env.os.clock = function()
		return math.floor(self.computer.clock * 100) / 100 -- Round to 2 d.p.
	end
	self.env.os.getComputerID = function() return self.computer.id end
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
			expires = self.computer.clock + nTimeout,
		}
		table.insert(self.computer.timers, timer)
		for k, v in pairs(self.computer.timers) do
			if v == timer then return k end
		end
		log("Could not find timer!", "ERROR")
	end
	self.env.os.setAlarm = function(nTime)
		assert(type(nTime) == "number")
		if nTime < 0 or nTime > 24 then
			error( "Number out of range: " .. tostring( nTime ) )
		end
		local alarm = {
			time = nTime,
			day = nTime >= self.computer.time and self.computer.day + 1 or self.computer.day
		}
		table.insert(self.computer.alarms, alarm)
		for k, v in pairs(self.computer.alarms) do
			if v == alarm then return k end
		end
		log("Could not find alarm!", "ERROR")
	end
	self.env.os.time = function()
		return math.floor(self.computer.time * 1000) / 1000 -- Round to 3d.p.
	end
	self.env.os.day = function()
		return self.computer.day
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
		isPresent = function(side)
			return self.computer.peripheralManager:isPresent(side)
		end,
		getType = function(side)
			return self.computer.peripheralManager:getType(side)
		end,
		getMethods = function(side)
			return self.computer.peripheralManager:getMethods(side)
		end,
		call = function(side, method, ...)
			return self.computer.peripheralManager:call(side, method, ...)
		end,
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
			if http.responseText then
		        local handle = HTTPHandle(Util.lines(http.responseText), http.status)
		        table.insert(self.computer.eventQueue, { "http_success", sUrl, handle })
		    else
		    	table.insert(self.computer.eventQueue, { "http_failure", sUrl })
		    end
		end

		http.send(sParams)
	end
	self.env.rs = self.env.redstone
	self.env._G = self.env

	if _DEBUG then
		log("NativeAPI: Debug api available. _G.emu", "WARNING")
		self.env.emu = {
			log = log,
			env = _G,
		}
	end
end
