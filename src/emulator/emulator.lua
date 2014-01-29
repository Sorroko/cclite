require 'emulator.computer'
require 'emulator.peripheral_manager'
require 'emulator.screen'
require 'emulator.filesystem'
require 'emulator.native_api'
require 'ui.component'

Emulator = class('Emulator', Component)

local tShortcuts = {
	["shutdown"] = {
		keys = {"ctrl", "s"},
		delay = 1,
		nSince = nil,
		action = function(self)
			self.computer:stop()
		end
	},
	["reboot"] = {
		keys = {"ctrl", "r"},
		delay = 1,
		nSince = nil,
		action = function(self)
			self.computer:stop( true )
		end
	},
	["terminate"] = {
		keys = {"ctrl", "t"},
		delay = 1,
		nSince = nil,
		action = function(self)
			table.insert(self.computer.eventQueue, {"terminate"})
		end
	},
	["paste_text"] = {
		keys = {"ctrl", "v"},
		action = function(self)
			local clipboard = love.system.getClipboardText():sub(1,128):gsub("\r\n","\n")
			self.textinput(clipboard)
		end
	}
}

function Emulator:initialize(x, y)
	Component.initialize(self, x, y)
	self.computer = Computer(self)

	-- register callbacks with pub/sub
	love.on("mousereleased", function ( ... )
		self:mousereleased(...)
	end)
	love.on("mousepressed", function ( ... )
		self:mousepressed(...)
	end)
	love.on("keypressed", function ( ... )
		self:keypressed(...)
	end)
	love.on("textinput", function ( ... )
		self:textinput(...)
	end)
end

function Emulator:getWidth()
	return Screen.width * Screen.pixelWidth
end

function Emulator:getHeight()
	return Screen.height * Screen.pixelHeight
end

function Emulator:draw()
	self.computer.screen:draw()
end

local mouse = {
	isPressed = false,
	lastTermX = nil,
	lastTermY = nil,
}

function Emulator:update(dt)
	local now = love.timer.getTime()

	if self.computer.reboot and not self.computer.running then
		log("Restarting computer.")
		self.computer:start()
	end

	local allDown
	for _k, shortcut in pairs(tShortcuts) do
		if shortcut.delay ~= nil then
			allDown = true
			for __k, key in pairs(shortcut.keys) do
				if not Util.isKeyDown(key) then allDown = false end
			end

			if allDown and shortcut.nSince and now - shortcut.nSince > shortcut.delay then
				shortcut.nSince = nil
				shortcut.action(self)
			end
		end
	end

	if not self.computer.running then return end -- Don't update computer specific things

	--MOUSE
	if mouse.isPressed then
    	local mouseX     = love.mouse.getX()
    	local mouseY     = love.mouse.getY()
    	local termMouseX = math.floor( mouseX / Screen.pixelWidth ) + 1
    	local termMouseY = math.floor( mouseY / Screen.pixelHeight ) + 1
    	if (termMouseX ~= mouse.lastTermX or termMouseY ~= mouse.lastTermY)
			and (mouseX > 0 and mouseX < Screen.width * Screen.pixelWidth and
				mouseY > 0 and mouseY < Screen.height * Screen.pixelHeight) then

        	mouse.lastTermX = termMouseX
       		mouse.lastTermY = termMouseY
        	table.insert (self.computer.eventQueue, { "mouse_drag", love.mouse.isDown( "r" ) and 2 or 1, termMouseX, termMouseY})
    	end
    end

	if #self.computer.timers > 0 then
		for k, v in pairs(self.computer.timers) do
			if self.computer.clock >= v.expires then
				table.insert(self.computer.eventQueue, {"timer", k})
				self.computer.timers[k] = nil
			end
		end
	end

	if #self.computer.alarms > 0 then
		for k, v in pairs(self.computer.alarms) do
        	if v.day >= self.computer.day and v.time >= self.computer.time then
            	table.insert(self.computer.eventQueue, {"alarm", k})
           		self.computer.alarms[k] = nil
        	end
    	end
	end

	-- Minecraft runs at 20 ticks per seconds
	local time = (dt * 20) / 1000
	self.computer.time = self.computer.time + time
	if self.computer.time >= 24 then
		self.computer.day = self.computer.day + 1
		self.computer.time = 24 - self.computer.time
	end
	self.computer.clock = self.computer.clock + dt

	-- if not test then test = 0 end
	-- if test == 20 then print(self.time) else test = test + 1 end

    if #self.computer.eventQueue > 0 then
		for k, v in pairs(self.computer.eventQueue) do
			self.computer:resume(unpack(v))
		end
		self.computer.eventQueue = {}
	end
end

function Emulator:keypressed( key, isrepeat )
	if not isrepeat and not self.computer.running then
		self.computer:start()
		return
	end

	local now, allDown = love.timer.getTime(), nil
	for _k, shortcut in pairs(tShortcuts) do
		allDown = true
		for __k, key in pairs(shortcut.keys) do
			if not Util.isKeyDown(key) then allDown = false end
		end
		if allDown then
			if not isrepeat then
				if shortcut.delay ~= nil then
					-- Delayed action
					shortcut.nSince = now
				else
					-- Instant action
					shortcut.action()
				end
			end
			return -- No need to check the rest, and don't send event to queue
		end
	end

	if Util.KEYS[key] then
   		table.insert(self.computer.eventQueue, {"key", Util.KEYS[key]})
   	end
end

function Emulator:textinput( text )
	if string.len(text) > 1 then -- Speedy check
		for char in string.gmatch(text, ".") do
			if char == "\n" then
				table.insert(self.computer.eventQueue, {"key", Util.KEYS["return"]})
			else
				table.insert(self.computer.eventQueue, {"char", char})
			end
		end
	else
		table.insert(self.computer.eventQueue, {"char", text})
	end
end

function Emulator:mousepressed( x, y, _button )
	if x > 0 and x < Screen.width * Screen.pixelWidth
		and y > 0 and y < Screen.height * Screen.pixelHeight then -- Within screen bounds.

		local termMouseX = math.floor( x / Screen.pixelWidth ) + 1
    	local termMouseY = math.floor( y / Screen.pixelHeight ) + 1

		if _button == "r" or _button == "l" then
			mouse.isPressed = true
			mouse.lastTermX = termMouseX
			mouse.lastTermY = termMouseY
			table.insert(self.computer.eventQueue, {"mouse_click", _button == "r" and 2 or 1, termMouseX, termMouseY})
		elseif _button == "wu" then -- Scroll up
			table.insert(self.computer.eventQueue, {"mouse_scroll", -1, termMouseX, termMouseX})
		elseif _button == "wd" then -- Scroll down
			table.insert(self.computer.eventQueue, {"mouse_scroll", 1, termMouseX, termMouseY})
		end
	end
end

function Emulator:mousereleased( x, y, _button )
	mouse.isPressed = false
end
