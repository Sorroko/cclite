Emulator = class('Emulator')

Emulator.activeComputer = Computer:new()

function Emulator.static.draw()
	Emulator.activeComputer.screen:draw()
end

local tShortcuts = {
	["shutdown"] = {
		keys = {"ctrl", "s"},
		delay = 1,
		nSince = nil,
		action = function()
			Emulator.activeComputer:stop()
		end
	},
	["reboot"] = {
		keys = {"ctrl", "r"},
		delay = 1,
		nSince = nil,
		action = function()
			Emulator.activeComputer:stop( true )
		end
	},
	["terminate"] = {
		keys = {"ctrl", "t"},
		delay = 1,
		nSince = nil,
		action = function()
			table.insert(Emulator.activeComputer.eventQueue, {"terminate"})
		end
	},
	["paste_text"] = {
		keys = {"ctrl", "v"},
		action = function()
			local clipboard = love.system.getClipboardText():sub(1,128):gsub("\r\n","\n")
			Emulator.textinput(clipboard)
		end
	}
}

local mouse = {
	isPressed = false,
	lastTermX = nil,
	lastTermY = nil,
}

function Emulator.static.update(dt)
	local now = love.timer.getTime()
	HttpRequest.checkRequests()

	if Emulator.activeComputer.reboot and not Emulator.activeComputer.running then
		log("Restarting computer.")
		Emulator.activeComputer:start()
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
				shortcut.action()
			end
		end
	end

	if not Emulator.activeComputer.running then return end -- Don't update computer specific things

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
        	table.insert (Emulator.activeComputer.eventQueue, { "mouse_drag", love.mouse.isDown( "r" ) and 2 or 1, termMouseX, termMouseY})
    	end
    end

	if #Emulator.activeComputer.timers > 0 then
		for k, v in pairs(Emulator.activeComputer.timers) do
			if Emulator.activeComputer.clock >= v.expires then
				table.insert(Emulator.activeComputer.eventQueue, {"timer", k})
				Emulator.activeComputer.timers[k] = nil
			end
		end
	end

	if #Emulator.activeComputer.alarms > 0 then
		for k, v in pairs(Emulator.activeComputer.alarms) do
        	if v.day >= Emulator.activeComputer.day and v.time >= Emulator.activeComputer.time then
            	table.insert(Emulator.activeComputer.eventQueue, {"alarm", k})
           		Emulator.activeComputer.alarms[k] = nil
        	end
    	end
	end

	-- Minecraft runs at 20 ticks per seconds
	local time = (dt * 20) / 1000
	Emulator.activeComputer.time = Emulator.activeComputer.time + time
	if Emulator.activeComputer.time >= 24 then
		Emulator.activeComputer.day = Emulator.activeComputer.day + 1
		Emulator.activeComputer.time = 24 - Emulator.activeComputer.time
	end
	Emulator.activeComputer.clock = Emulator.activeComputer.clock + dt

	-- if not test then test = 0 end
	-- if test == 20 then print(Emulator.time) else test = test + 1 end

    if #Emulator.activeComputer.eventQueue > 0 then
		for k, v in pairs(Emulator.activeComputer.eventQueue) do
			Emulator.activeComputer:resume(unpack(v))
		end
		Emulator.activeComputer.eventQueue = {}
	end
end

function Emulator.static.keypressed( key, isrepeat )
	if not isrepeat and not Emulator.activeComputer.running then
		Emulator.activeComputer:start()
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
   		table.insert(Emulator.activeComputer.eventQueue, {"key", Util.KEYS[key]})
   	end
end

function Emulator.static.keyreleased( key )

end

function Emulator.static.textinput( text )
	if string.len(text) > 1 then -- Speedy check
		for char in string.gmatch(text, ".") do
			if char == "\n" then
				table.insert(Emulator.activeComputer.eventQueue, {"key", Util.KEYS["return"]})
			else
				table.insert(Emulator.activeComputer.eventQueue, {"char", char})
			end
		end
	else
		table.insert(Emulator.activeComputer.eventQueue, {"char", text})
	end
end

function Emulator.static.mousepressed( x, y, _button )
	if x > 0 and x < Screen.width * Screen.pixelWidth
		and y > 0 and y < Screen.height * Screen.pixelHeight then -- Within screen bounds.

		local termMouseX = math.floor( x / Screen.pixelWidth ) + 1
    	local termMouseY = math.floor( y / Screen.pixelHeight ) + 1

		if _button == "r" or _button == "l" then
			mouse.isPressed = true
			mouse.lastTermX = termMouseX
			mouse.lastTermY = termMouseY
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_click", _button == "r" and 2 or 1, termMouseX, termMouseY})
		elseif _button == "wu" then -- Scroll up
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_scroll", -1, termMouseX, termMouseX})
		elseif _button == "wd" then -- Scroll down
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_scroll", 1, termMouseX, termMouseY})
		end
	end
end

function Emulator.static.mousereleased( x, y, _button )
	mouse.isPressed = false
end
