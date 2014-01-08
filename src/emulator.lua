Emulator = class('Emulator')

Emulator.static.activeComputer = Computer:new()

function Emulator.static.draw()
	Emulator.activeComputer.screen:draw()
end

local tShortcuts = {
	["shutdown"] = {
		keys = {"lctrl", "s"},
		delay = 1,
		nSince = nil,
		action = function()
			Emulator.activeComputer:stop()
		end
	},
	["reboot"] = {
		keys = {"lctrl", "r"},
		delay = 1,
		nSince = nil,
		action = function()
			Emulator.activeComputer:stop( true )
		end
	},
	["terminate"] = {
		keys = {"lctrl", "t"},
		delay = 1,
		nSince = nil,
		action = function()
			table.insert(Emulator.activeComputer.eventQueue, {"terminate"})
		end
	},
	["paste_text"] = {
		keys = {"lctrl", "v"},
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
				if not love.keyboard.isDown(key) then allDown = false end
			end

			if allDown and shortcut.nSince and now - shortcut.nSince > shortcut.delay then
				shortcut.nSince = nil
				shortcut.action()
			end
		end
	end

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

	if #Emulator.activeComputer.actions.timers > 0 then
		for k, v in pairs(Emulator.activeComputer.actions.timers) do
			if now > v.expires then
				table.insert(Emulator.activeComputer.eventQueue, {"timer", k})
				Emulator.activeComputer.actions.timers[k] = nil
			end
		end
	end

	if #Emulator.activeComputer.actions.alarms > 0 then
		local currentTime = api.env.os.time()
		local currentDay = api.env.os.day()

		for k, v in pairs(Emulator.activeComputer.actions.alarms) do
        	if v.day == currentDay and v.time >= currentTime then
            	table.insert(Emulator.activeComputer.eventQueue, {"alarm", k})
           		Emulator.activeComputer.actions.alarms[k] = nil
        	end
    	end
	end

    -- Check if a second has passed since the last update.
    local currentClock = os.clock()
    if currentClock - Emulator.activeComputer.lastUpdateClock >= 1 then
        Emulator.activeComputer.lastUpdateClock = currentClock
        Emulator.activeComputer.minecraft.time  = Emulator.activeComputer.minecraft.time + 1

        -- Roll over the time and add another day if the time goes over the max day time.
        if Emulator.activeComputer.minecraft.time > Emulator.activeComputer.minecraft.MAX_TIME_IN_DAY then
            Emulator.activeComputer.minecraft.time = 0
            Emulator.activeComputer.minecraft.day  = Emulator.activeComputer.minecraft.day + 1
        end
    end

    if #Emulator.activeComputer.eventQueue > 0 then
		for k, v in pairs(Emulator.activeComputer.eventQueue) do
			Emulator.activeComputer:resume(unpack(v))
		end
		Emulator.activeComputer.eventQueue = {}
	end
end

function Emulator.static.keypressed( key, isrepeat )
	if not isrepeat then
		if not Emulator.activeComputer.running then
			Emulator.activeComputer:start()
			return
		end

		local now, allDown = love.timer.getTime(), nil
		for _k, shortcut in pairs(tShortcuts) do
			allDown = true
			for __k, key in pairs(shortcut.keys) do
				if not love.keyboard.isDown(key) then allDown = false end
			end
			if allDown then
				if shortcut.delay ~= nil then
					-- Delayed action
					shortcut.nSince = now
				else
					-- Instant action
					shortcut.action()
				end

				return -- No need to check the rest, and don't send event to queue
			end
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
