require('http.HttpRequest')

require('render')
require('api')

local keys = {
	["q"] = 16, ["w"] = 17, ["e"] = 18, ["r"] = 19,
	["t"] = 20, ["y"] = 21, ["u"] = 22, ["i"] = 23, 
	["o"] = 24, ["p"] = 25, ["a"] = 30, ["s"] = 31,
	["d"] = 32, ["f"] = 33, ["g"] = 34, ["h"] = 35, 
	["j"] = 36, ["k"] = 37, ["l"] = 38, ["z"] = 44, 
	["x"] = 45, ["c"] = 46, ["v"] = 47, ["b"] = 48,
	["n"] = 49, ["m"] = 50, 
	["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 5, ["5"] = 6,
	["6"] = 7, ["7"] = 8, ["8"] = 9, ["9"] = 10, ["0"] = 11,
	[" "] = 57,

	["'"] = 40, [","] = 51, ["-"] = 12, ["."] = 52, ["/"] = 53,
	[":"] = 146, [";"] = 39, ["="] = 13, ["@"] = 145, ["["] = 26,
	["\\"] = 43, ["]"] = 27, ["^"] = 144, ["_"] = 147, ["`"] = 41,

	["up"] = 200,
	["down"] = 208,
	["right"] = 205,
	["left"] = 203,
	["home"] = 199,
	["end"] = 207,
	["pageup"] = 201,
	["pagedown"] = 209,
	["insert"] = 210,
	["backspace"] = 14,
	["tab"] = 15,
	["return"] = 28,
	["delete"] = 211,

	["rshift"] = 54,
	["lshift"] = 42,
	["rctrl"] = 157,
	["lctrl"] = 29,
	["ralt"] = 184,
	["lalt"] = 56,
}

Emulator = {
	running = false, 
	reboot = false, -- Tells update loop to start Emulator automatically
	actions = { -- Keyboard commands i.e. ctrl + s and timers/alarms
		terminate = nil,
		shutdown = nil,
		reboot = nil,
		timers = {},
		alarms = {},
	},
	eventQueue = {},
}
function Emulator:start()
	self.reboot = false
	api.init()
	Screen:init()

	local fn, err = love.filesystem.load('lua/bios.lua') -- lua/bios.lua
	local tEnv = {}
	tEnv._G = tEnv
	if not fn then
		print(err)
		return
	end
	setmetatable(tEnv, { __index = api.env } )
	setfenv( fn, tEnv )

	self.proc = coroutine.create(fn)
	self.running = true
	self:resume({})
end

function Emulator:stop( reboot )
	self.proc = nil
	self.running = false
	self.reboot = reboot

	-- Reset events/key shortcuts
	self.actions.terminate = nil
	self.actions.shutdown = nil
	self.actions.reboot = nil
	self.actions.timers = {}
	self.actions.alarms = {}
	self.eventQueue = {}
end

function Emulator:resume( ... )
	if not self.running then return end
	local ok, err = coroutine.resume(self.proc, ...)
	if not self.proc then return end -- Emulator:stop could be called within the coroutine resulting in proc being nil
	if coroutine.status(self.proc) == "dead" then -- Which could cause an error here
		Emulator:stop()
	end
	if not ok then
    	print(err) -- Print to debug console, errors are handled in bios.
    end
    return ok, err
end

function love.load()
	font = love.graphics.newFont( 'res/minecraft.ttf', 16 )
	love.graphics.setFont(font)

	love.graphics.setMode( Screen.width * Screen.pixelWidth, Screen.height * Screen.pixelHeight, false, true, 0 )
	love.graphics.setCaption( "ComputerCraft Emulator" )

	love.filesystem.setIdentity( "ccemu" )
	if not love.filesystem.exists( "data/" ) then
		love.filesystem.mkdir( "data/" ) -- Make the user data folder
	end

	love.keyboard.setKeyRepeat( 0.5, 0.05 )

	Emulator:start()
end

function  love.mousepressed( x, y, _button )
	if _button == "r" or _button == "l" then

		if x > 0 and x < Screen.width * Screen.pixelWidth
			and y > 0 and y < Screen.height * Screen.pixelHeight then -- Within screen bounds.
			local button = 1
			if _button == "r" then button = 2 end
			table.insert(Emulator.eventQueue, {"mouse_click", button, math.floor(x / Screen.pixelWidth) - 1, math.floor(y / Screen.pixelHeight) - 1})
		end
	elseif _button == "wu" then -- Scroll up

	elseif _button == "wd" then -- Scroll down

	end
end

function love.keypressed(key, unicode)
	if not Emulator.running then
		Emulator:start()
		return
	end

	if love.keyboard.isDown("lctrl") and key == "t" then
		Emulator.actions.terminate = love.timer.getTime()
	elseif love.keyboard.isDown("lctrl") and key == "s" then
		Emulator.actions.shutdown = love.timer.getTime()
	elseif love.keyboard.isDown("lctrl") and key == "r" then
		Emulator.actions.reboot = love.timer.getTime()
	end

	if keys[key] then
   		table.insert(Emulator.eventQueue, {"key", keys[key]})
   	end

   	if unicode > 31 and unicode < 127 then
    	table.insert(Emulator.eventQueue, {"char", string.char(unicode)})
    end
end

--[[
	Events TODO:
	mouse_scroll
	mouse_drag
	alarm

	Not implementing:
	redstone
	disk
	disk_eject
	peripheral
	peripheral_detatch
	modem_message
	monitor_touch
	monitor_resize

	Emulator does not handle peripherals.
]]

function updateShortcut(name, key1, key2, cb)
	if Emulator.actions[name] ~= nil then
		if love.keyboard.isDown(key1)
			and love.keyboard.isDown(key2) then

			if love.timer.getTime() - Emulator.actions[name] > 1 then
				Emulator.actions[name] = nil
				if cb then cb() end
			end

		else
			Emulator.actions[name] = nil
		end
	end
end

function love.update()
	local now = love.timer.getTime()
	HttpRequest.checkRequests()
	if Emulator.reboot then Emulator:start() end

	updateShortcut("terminate", "lctrl", "t", function()
			table.insert(Emulator.eventQueue, {"terminate"})
		end)
	updateShortcut("shutdown", "lctrl", "s", function()
			Emulator:stop()
		end)
	updateShortcut("reboot", "lctrl", "r", function()
			Emulator:stop( true )
		end)

	if api.term.blink then
		if Screen.lastCursor == nil then
			Screen.lastCursor = now
		end
		if now - Screen.lastCursor > 0.5 then
			Screen.showCursor = not Screen.showCursor
			Screen.lastCursor = now
		end
	end

	if #Emulator.actions.timers > 0 then
		for k, v in pairs(Emulator.actions.timers) do
			if now > v.expires then
				table.insert(Emulator.eventQueue, {"timer", k})
				Emulator.actions.timers[k] = nil
			end
		end
	end

	if #Emulator.eventQueue > 0 then
		for k, v in pairs(Emulator.eventQueue) do
			Emulator:resume(unpack(v))
		end
		Emulator.eventQueue = {}
	end
end

function love.draw()
	Screen:draw()
	if debug then
		love.graphics.print("FPS: " .. tostring(love.timer.getFPS( )), (Screen.width * Screen.pixelWidth) - 85, 10)
	end
end