Computer = class('Computer')

function Computer:initialize()
	log("Computer -> initialize()")
	self.screen = Screen(self)

	self.id = 1 -- Temporary
	self.running = false
	self.reboot = false
	self.timers = {}
	self.alarms = {}
	self.eventQueue = {}
	self.time = 0
	self.day = 0
	self.clock = 0 -- In seconds since emulator start
	self.textB = {}
	self.backgroundColourB = {}
	self.textColourB = {}
	self.api = nil
	self.waitForEvent = nil
end

function Computer:start()
	log("Computer -> start()")
	self.reboot = false

	-- Reset buffers
	local x,y
	for y = 1, Screen.height do
		self.textB[y] = {}
		self.backgroundColourB[y] = {}
		self.textColourB[y] = {}
		for x = 1, Screen.width do
			self.textB[y][x] = " "
			self.backgroundColourB[y][x] = 32768
			self.textColourB[y][x] = 1
		end
	end

	local fn, err = love.filesystem.load('lua/bios.lua') -- lua/bios.lua
	local tEnv = {}
	if not fn then
		print(err)
		return
	end

	self.api = NativeAPI(self)
	setfenv( fn,  self.api.env )

	self.proc = coroutine.create(fn)
	self.running = true
	self:resume({})
end

function Computer:stop( _reboot )
	log("Computer -> stop(): reboot - " .. tostring(_reboot or false))
	self.proc = nil
	self.running = false
	self.reboot = _reboot

	-- Reset events/key shortcuts
	self.timers = {}
	self.alarms = {}
	self.clock = 0
	self.eventQueue = {}
	self.api = nil
	self.waitForEvent = nil
end

function Computer:resume( ... )
	if not self.running then return end
	local tEvent = { ... }
	if self.waitForEvent ~= nil and #tEvent > 0 then
		if tEvent[1] ~= self.waitForEvent then return end
	end
	local ok, param = coroutine.resume(self.proc, ...)
	if not self.proc then return end -- Instance:stop could be called within the coroutine resulting in proc being nil
	if coroutine.status(self.proc) == "dead" then -- Which could cause an error here
		self:stop()
	end
	if ok then
		self.waitForEvent = param -- TODO: This may not be necessary, parallel api already handles filters
	else
		print(param) -- Print to debug console, errors are handled in bios.
	end
end
