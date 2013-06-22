--[[
	TODO
	HTTP api?
	the rest of fs api!
	including file handles.
	os.day
	os.time
	writeLine!
]]
-- HELPER FUNCTIONS
local function lines(str)
	local t = {}
	local function helper(line) table.insert(t, line) return "" end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
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

api = {}
function api.init() -- Called after this file is loaded! Important. Else api.x is not defined
	api.term = {
		cursorX = 1,
		cursorY = 1,
		bg = 32768,
		fg = 1,
		blink = false,
	}
	api.os = {
		label = nil
	}
end

api.http = {}
function api.http.request( sUrl, sParams )
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
	        table.insert(Emulator.eventQueue, { "http_success", sUrl, handle })
	    else
	    	 table.insert(Emulator.eventQueue, { "http_failure", sUrl })
	    end
    end

    http.send(sParams)
end

api.term = {}
function api.term.clear()
	for y = 1, Screen.height do
		for x = 1, Screen.width do
			Screen.textB[y][x] = " "
			Screen.backgroundColourB[y][x] = api.term.bg
			Screen.textColourB[y][x] = 1 -- Don't need to bother setting text color
		end
	end
end
function api.term.clearLine()
	for x = 1, Screen.width do
		Screen.textB[api.term.cursorY][x] = " "
		Screen.backgroundColourB[api.term.cursorY][x] = api.term.bg
		Screen.textColourB[api.term.cursorY][x] = 1 -- Don't need to bother setting text color
	end
end
function api.term.getSize()
	return Screen.width, Screen.height
end
function api.term.getCursorPos()
	return api.term.cursorX, api.term.cursorY
end
function api.term.setCursorPos(x, y)
	api.term.cursorX = math.floor(x)
	api.term.cursorY = math.floor(y)
end
function api.term.write( text )
	if api.term.cursorY > Screen.height
		or api.term.cursorY < 1 then return end

	for i = 1, #text do
		local char = string.sub( text, i, i )
		if api.term.cursorX + i - 1 <= Screen.width
			and api.term.cursorX + i - 1 >= 1 then
			Screen.textB[api.term.cursorY][api.term.cursorX + i - 1] = char
			Screen.textColourB[api.term.cursorY][api.term.cursorX + i - 1] = api.term.fg
			Screen.backgroundColourB[api.term.cursorY][api.term.cursorX + i - 1] = api.term.bg
		end
	end
	api.term.cursorX = api.term.cursorX + #text
end
function api.term.setTextColor( num )
	api.term.fg = num
end
function api.term.setBackgroundColor( num )
	api.term.bg = num
end
function api.term.isColor()
	return true
end
function api.term.setCursorBlink( bool )
	api.term.blink = bool
end
function  api.term.scroll( n )
	local textBuffer = {}
	local backgroundColourBuffer = {}
	local textColourBuffer = {}
	for y = 1, Screen.height do
		if y - n > 0 and y - n <= Screen.height then
			textBuffer[y - n] = {}
			backgroundColourBuffer[y - n] = {}
			textColourBuffer[y - n] = {}
			for x = 1, Screen.width do
				textBuffer[y - n][x] = Screen.textB[y][x]
				backgroundColourBuffer[y - n][x] = Screen.backgroundColourB[y][x]
				textColourBuffer[y - n][x] = Screen.textColourB[y][x]
			end
		end
	end
	for y = 1, Screen.height do
		if textBuffer[y] ~= nil then
			for x = 1, Screen.width do
				Screen.textB[y][x] = textBuffer[y][x]
				Screen.backgroundColourB[y][x] = backgroundColourBuffer[y][x]
				Screen.textColourB[y][x] = textColourBuffer[y][x]
			end
		else
			for x = 1, Screen.width do
				Screen.textB[y][x] = " "
				Screen.backgroundColourB[y][x] = api.term.bg
				Screen.textColourB[y][x] = 1 -- Don't need to bother setting text color
			end
		end
	end
end

api.os = {}
function api.os.setComputerLabel(label)
	api.os.label = label
end
function api.os.getComputerLabel()
	return api.os.label
end
function api.os.queueEvent( sEvent, ... )
	table.insert(Emulator.eventQueue, { sEvent, unpack(...) })
end
function api.os.startTimer( nTimeout )
	local timer = {
		expires = love.timer.getTime() + nTimeout,
	}
	table.insert(Emulator.actions.timers, timer)
	for k, v in pairs(Emulator.actions.timers) do
		if v == timer then return k end
	end
	return nil -- Erroor
end
function api.os.setAlarm( nTime )
	local timer = {
		time = nTime,
	}
	table.insert(Emulator.actions.alarms, timer)
	for k, v in pairs(Emulator.actions.alarms) do
		if v == timer then return k end
	end
	return nil -- Erroor
end
function api.os.shutdown()
	Emulator:stop()
end
function api.os.reboot()
	Emulator:stop( true ) -- Reboots on next update/tick
end

api.fs = {}

function api.fs.open(path, mode)
	path = api.fs.combine("", path)
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
		if api.fs.exists( path ) then -- Write mode overwrites! FIXME: Wait until handle.close() is called
			api.fs.delete( path )
		end

		return FileWriteHandle("data/" .. path)
	end
	return nil
end
function api.fs.list(path)
	path = api.fs.combine("", path)
	local res = {}
	if love.filesystem.exists("data/" .. path) then -- This path takes precedence
		res = love.filesystem.enumerate("data/" .. path)
	end
	if love.filesystem.exists("lua/" .. path) then
		for k, v in pairs(love.filesystem.enumerate("lua/" .. path)) do
			if v ~= "bios.lua" then table.insert(res, v) end
		end
	end
	return res
end
function api.fs.exists(path)
	if path == "/bios.lua" then return false end
	path = api.fs.combine("", path)
	return love.filesystem.exists("data/" .. path) or love.filesystem.exists("lua/" .. path)
end
function api.fs.isDir(path)
	path = api.fs.combine("", path)
	return love.filesystem.isDirectory("data/" .. path) or love.filesystem.isDirectory("lua/" .. path)
end
function api.fs.isReadOnly(path)
	path = api.fs.combine("", path)
	return string.sub(path, 1, 4) == "rom/"
end
function api.fs.getName(path)
	local fpath, name, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	return name
end
function api.fs.getSize(path)
	return nil
end
function api.fs.getFreeSpace(path)
	return nil
end
function api.fs.makeDir(path) -- All write functions are within data/
	path = api.fs.combine("", path)
	if string.sub(path, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
		return love.filesystem.mkdir( "data/" .. path )
	else return nil end
end
function api.fs.move(fromPath, toPath)
	-- Not implemented
end

local function deltree(sFolder)
	local tObjects = love.filesystem.enumerate(sFolder)

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
	local tObjects = love.filesystem.enumerate(sFolder)

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
function api.fs.copy(fromPath, toPath)
	fromPath = api.fs.combine("", fromPath)
	toPath = api.fs.combine("", toPath)
	if string.sub(toPath, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
		return copytree("data/" .. fromPath, "data/" .. toPath)
	else return nil end
end

function api.fs.delete(path)
	path = api.fs.combine("", path)
	if string.sub(path, 1, 4) ~= "rom/" then -- Stop user overwriting lua/rom/ with data/rom/
		return deltree( "data/" .. path )
	else return nil end
end
function api.fs.combine(basePath, localPath)
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

api.env = {
	tostring = tostring,
	tonumber = tonumber,
	unpack = unpack,
	getfenv = getfenv,
	setfenv = setfenv,
	rawset = rawset,
	rawget = rawget,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	next = next,
	type = type,
	select = select,
	assert = assert,
	error = error,

	loadstring = loadstring,

	math = math,
	string = string,
	table = table,
	coroutine = coroutine,

	-- CC apis (BIOS completes api.)
	term = {
		native = {
			clear = api.term.clear,
			clearLine = api.term.clearLine,
			getSize = api.term.getSize,
			getCursorPos = api.term.getCursorPos,
			setCursorPos = api.term.setCursorPos,
			setTextColor = api.term.setTextColor,
			setTextColour = api.term.setTextColor,
			setBackgroundColor = api.term.setBackgroundColor,
			setBackgroundColour = api.term.setBackgroundColor,
			setCursorBlink = api.term.setCursorBlink,
			scroll = api.term.scroll,
			write = api.term.write,
			isColor = api.term.isColor,
			isColour = api.term.isColor,
		},
		clear = api.term.clear,
		clearLine = api.term.clearLine,
		getSize = api.term.getSize,
		getCursorPos = api.term.getCursorPos,
		setCursorPos = api.term.setCursorPos,
		setTextColor = api.term.setTextColor,
		setTextColour = api.term.setTextColor,
		setBackgroundColor = api.term.setBackgroundColor,
		setBackgroundColour = api.term.setBackgroundColor,
		setCursorBlink = api.term.setCursorBlink,
		scroll = api.term.scroll,
		write = api.term.write,
		isColor = api.term.isColor,
		isColour = api.term.isColor,
	},
	fs = {
		open = api.fs.open,
		list = api.fs.list,
		exists = api.fs.exists,
		isDir = api.fs.isDir,
		isReadOnly = api.fs.isReadOnly,
		getName = api.fs.getName,
		getDrive = function(path) return nil end, -- Dummy function
		getSize = api.fs.getSize,
		getFreeSpace = api.fs.getFreeSpace,
		makeDir = api.fs.makeDir,
		move = api.fs.move,
		copy = api.fs.copy,
		delete = api.fs.delete,
		combine = api.fs.combine,
	},
	os = {
		clock = os.clock,
		getComputerID = function() return 1 end,
		setComputerLabel = api.os.setComputerLabel,
		getComputerLabel = api.os.getComputerLabel,
		computerLabel = api.os.getComputerLabel,
		queueEvent = api.os.queueEvent,
		startTimer = api.os.startTimer,
		setAlarm = api.os.setAlarm,
		shutdown = api.os.shutdown,
		reboot = api.os.reboot,
	},
	peripheral = {
		isPresent = function(side) return false end,
		getNames = function() return {} end,
		getType = function(side) return nil end,
		getMethods = function(side) return nil end,
		call = function(side, method, ...) return nil end,
		wrap = function (side) return nil end,
	},
	http = {
		request = api.http.request,
	}
}
