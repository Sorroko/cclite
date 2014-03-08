Computer = class('Computer')

function Computer:initialize(emulator, id, isAdvanced)
	log("Computer -> initialize()")
	self.emulator = emulator
	self.screen = Screen(isAdvanced)
	self.fileSystem = FileSystem()
	self.peripheralManager = PeripheralManager(self)

	self.isAdvanced = isAdvanced or false

	self.id = id
	self.running = false
	self.reboot = false
	self.timers = {}
	self.alarms = {}
	self.eventQueue = {}
	self.time = 0
	self.day = 0
end

function Computer:start()
	log("Computer -> start()")
	self.timers = {}
	self.alarms = {}
	self.eventQueue = {}
	self.clock = 0 -- In seconds since emulator start

	self.reboot = false
	self.running = true
	self.waitForEvent = nil

	--local fn, err = love.filesystem.load('lua/bios.lua') -- lua/bios.lua
	local fn, err = loadstring(love.filesystem.read("/lua/bios.lua"),"bios")
	if not fn then print(err) return end

	self.api = NativeAPI(self)
	setfenv( fn,  self.api.env )

	self.proc = coroutine.create(fn)
	self:resume()
end

function Computer:stop( _reboot )
	log("Computer -> stop(): reboot - " .. tostring(_reboot or false))
	self.proc = nil
	self.api = nil
	self.running = false
	self.reboot = _reboot
	self.screen:reset()
end

function Computer:resume( ... )
	if not self.running then return end

	local tEvent = { ... }
	if self.waitForEvent ~= nil and #tEvent > 0 then
		if tEvent[1] ~= self.waitForEvent then return end
	end
	debug.sethook(function() error("Too long without yielding.", 3) end, "", 500000) -- Doesn't work in all cases
	local ok, param = coroutine.resume(self.proc, ...)
	debug.sethook()
	if self.proc and coroutine.status(self.proc) == "dead" then -- Which could cause an error here
		self:stop()
	end
	if ok then
		self.waitForEvent = param
	else
		print(param)
	end
end

function Computer:pushEvent(event)
	table.insert(self.eventQueue, event)
end

function Computer:draw( ... )
	if self.running then
		self.screen:draw()
	else
		local text = "Press any key..."
		love.graphics.print(text, ((Screen.width * Screen.pixelWidth) / 2) - (Screen.font:getWidth(text) / 2), (Screen.height * Screen.pixelHeight) / 2)
	end
end

function Computer:update(dt)
	if self.reboot and not self.running then
		log("Restarting computer.")
		self:start()
	end

	-- Only update below if running
	if not self.running then return end

    -- TIMERS
	if #self.timers > 0 then
		for k, v in pairs(self.timers) do
			if self.clock >= v.expires then
				self:pushEvent({"timer", k})
				self.timers[k] = nil
			end
		end
	end

	-- ALARMS
	if #self.alarms > 0 then
		for k, v in pairs(self.alarms) do
        	if v.day >= self.day and v.time >= self.time then
            	self:pushEvent({"alarm", k})
           		self.alarms[k] = nil
        	end
    	end
	end

	-- MINECRAFT TIME
	-- TODO: Move this into emulator, global for all computers
	-- Minecraft runs at 20 ticks per seconds
	local time = (dt * 20) / 1000
	self.time = self.time + time
	if self.time >= 24 then
		self.day = self.day + 1
		self.time = 24 - self.time
	end

	-- CLOCK
	self.clock = self.clock + dt

	-- EVENTS
	if #self.eventQueue > 0 then
		for k, v in pairs(self.eventQueue) do
			self:resume(unpack(v))
		end
		self.eventQueue = {}
	end
end

function Computer:textinput( text )
	if string.len(text) > 1 then -- Speedy check
		for char in string.gmatch(text, ".") do
			if char == "\n" then
				self:pushEvent({"key", Util.KEYS["return"]})
			else
				self:pushEvent({"char", char})
			end
		end
	else
		self:pushEvent({"char", text})
	end
end
