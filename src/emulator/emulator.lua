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
		action = function(activeComp)
			activeComp:stop()
		end
	},
	["reboot"] = {
		keys = {"ctrl", "r"},
		delay = 1,
		nSince = nil,
		action = function(activeComp)
			activeComp:stop( true )
		end
	},
	["terminate"] = {
		keys = {"ctrl", "t"},
		delay = 1,
		nSince = nil,
		action = function(activeComp)
			activeComp:pushEvent({"terminate"})
		end
	},
	["paste_text"] = {
		keys = {"ctrl", "v"},
		action = function(activeComp)
			local clipboard = love.system.getClipboardText():sub(1,128):gsub("\r\n","\n")
			activeComp:pushEvent({"paste", clipboard})
		end
	},
	["paste_text_improved"] = { -- Fakes input, and makes newlines work.
		keys = {"ctrl", "shift", "v"},
		action = function(activeComp)
			local clipboard = love.system.getClipboardText():sub(1,128):gsub("\r\n","\n")
			activeComp:textinput(clipboard)
		end
	}
}

function Emulator:resize(width, height)

	if PLATFORM == "Android" then
		log("RESIZE: " .. width .. " " .. height)

		local windowAspect = width / height
		local screenAspect = (Screen.width * Screen.pixelWidth) / (Screen.height * Screen.pixelHeight)
		local clippingWidth, clippingHeight
		if windowAspect <= screenAspect then -- Make one side match the aspect ratio depends on which side fits
			clippingWidth = width
			clippingHeight = width / screenAspect
		else
			clippingWidth = height  * screenAspect
			clippingHeight = height
		end

		self.width = math.ceil(clippingWidth)
		self.height = math.ceil(clippingHeight)

		self.scaleW = self.width / (Screen.width * Screen.pixelWidth)
		self.scaleH = self.height / (Screen.height * Screen.pixelHeight)

		self.x = (width / 2) - (self.width / 2) -- center emulator
	else
		self.width = Screen.width * Screen.pixelWidth
		self.height = Screen.height * Screen.pixelHeight
	end
end

function Emulator:initialize(window, x, y, mwidth, mheight)
	self:resize(mwidth, mheight)

	Component.initialize(self, window, x, y)

	self.UUID = 1
	self.computers = {}
	self.activeId = nil

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
	love.on("resize", function ( ... )
		self:resize(...)
	end)
end

function Emulator:registerComputer(tData)
	local computer = Computer(self, self.UUID, tData.advanced)
	self.computers[self.UUID] = computer

	self.UUID = self.UUID + 1
	self:setActiveComputer(computer.id)
	return self.computers[computer.id]
end

function Emulator:setActiveComputer(id) -- TODO: Accept a computer object as param
	if id ~= nil and self.computers[id] ~= nil then
		self.activeId = id
		return
	end

	-- Find a computer to set as active
	for i = 1, #self.computers do
		if self.computer[i] ~= nil then
			self.activeId = i
			return
		end
	end
	self.activeId = nil
end

function Emulator:getActiveComputer() -- Active does not mean it must be on, it is the computer which has focus
	return self.activeId ~= nil and self.computers[self.activeId] or nil
end

function Emulator:getWidth()
	return self.width
end

function Emulator:getHeight()
	return self.height
end

function Emulator:draw()
	if PLATFORM == "Android" then
		love.graphics.push()
		love.graphics.scale(self.scaleW, self.scaleH)
	end

	if self.activeId ~= nil then
		self.computers[self.activeId]:draw()
	end

	if PLATFORM == "Android" then
		love.graphics.pop()
	end
end

local mouse = {
	isPressed = false,
	lastTermX = nil,
	lastTermY = nil,
}

function Emulator:update(dt)

	if self.activeId ~= nil then -- Only send keyboard and mouse events/actions to active computer
		local now = love.timer.getTime()
		-- KEYBOARD SHORTCUTS
		local allDown
		for _k, shortcut in pairs(tShortcuts) do
			if shortcut.delay ~= nil then
				allDown = true
				for __k, key in pairs(shortcut.keys) do
					if not Util.isKeyDown(key) then allDown = false end
				end

				if allDown and shortcut.nSince and now - shortcut.nSince > shortcut.delay then
					shortcut.nSince = nil
					shortcut.action(self:getActiveComputer())
				end
			end
		end

		--MOUSE
		if self:getActiveComputer().isAdvanced and mouse.isPressed then
	    	local mouseX     = love.mouse.getX() - self.x
	    	local mouseY     = love.mouse.getY() - self.y
	    	local termMouseX = math.floor( mouseX / Screen.pixelWidth ) + 1
	    	local termMouseY = math.floor( mouseY / Screen.pixelHeight ) + 1
	    	if (termMouseX ~= mouse.lastTermX or termMouseY ~= mouse.lastTermY)
				and (mouseX > 0 and mouseX < Screen.width * Screen.pixelWidth and
					mouseY > 0 and mouseY < Screen.height * Screen.pixelHeight) then

	        	mouse.lastTermX = termMouseX
	       		mouse.lastTermY = termMouseY

	        	self:getActiveComputer():pushEvent({ "mouse_drag", love.mouse.isDown( "r" ) and 2 or 1, termMouseX, termMouseY})
	    	end
	    end
	end

    -- UPDATE
    for i = 0, #self.computers do -- Update all computers, not just active
    	if self.computers[i] ~= nil then
    		self.computers[i]:update(dt)
    	end
    end

end

function Emulator:keypressed( key, isrepeat )
	if not self.activeId then return end

	if not self:getActiveComputer().running then
		if not isrepeat then
			self:getActiveComputer():start()
		end
		return -- Don't check shortcuts or key events if emulator isn't running
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
					shortcut.action(self:getActiveComputer())
				end
			end
			return -- No need to check the rest, and don't send event to queue
		end
	end

	if Util.KEYS[key] then
   		self:getActiveComputer():pushEvent({"key", Util.KEYS[key]})
   	end
end

function Emulator:textinput( text )
	if not self.activeId then return end

	self:getActiveComputer():textinput(text)
end

function Emulator:mousepressed( x, y, _button )
	if not self.activeId or not self:getActiveComputer().isAdvanced then return end

	if x > 0 and x < Screen.width * Screen.pixelWidth
		and y > 0 and y < Screen.height * Screen.pixelHeight then -- Within screen bounds.

		local termMouseX = math.floor( x / Screen.pixelWidth ) + 1
    	local termMouseY = math.floor( y / Screen.pixelHeight ) + 1

		if _button == "r" or _button == "l" then
			mouse.isPressed = true
			mouse.lastTermX = termMouseX
			mouse.lastTermY = termMouseY
			self:getActiveComputer():pushEvent({"mouse_click", _button == "r" and 2 or 1, termMouseX, termMouseY})
		elseif _button == "wu" then -- Scroll up
			self:getActiveComputer():pushEvent({"mouse_scroll", -1, termMouseX, termMouseX})
		elseif _button == "wd" then -- Scroll down
			self:getActiveComputer():pushEvent({"mouse_scroll", 1, termMouseX, termMouseY})
		end
	end
end

function Emulator:mousereleased( x, y, _button )
	if not self.activeId or not self:getActiveComputer().isAdvanced then return end
	mouse.isPressed = false
end
