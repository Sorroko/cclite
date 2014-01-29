Computer = class('Computer')

function Computer:initialize(emulator)
	log("Computer -> initialize()")
	self.emulator = emulator
	self.screen = Screen(self)
	self.fileSystem = FileSystem()
	self.peripheralManager = PeripheralManager(self)

	--self.peripheralManager:setSide("top", "test")

	self.id = 1 -- Temporary
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

	self.textB = {}
	self.backgroundColourB = {}
	self.textColourB = {}

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
end

function Computer:resume( ... )
	if not self.running then return end

	local tEvent = { ... }
	if self.waitForEvent ~= nil and #tEvent > 0 then
		if tEvent[1] ~= self.waitForEvent then return end
	end
	local ok, param = coroutine.resume(self.proc, ...)
	if self.proc and coroutine.status(self.proc) == "dead" then -- Which could cause an error here
		self:stop()
	end
	if ok then
		self.waitForEvent = param
	end
end
