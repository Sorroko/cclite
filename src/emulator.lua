Emulator = class('Emulator')

Emulator.static.activeComputer = Computer:new()

function Emulator.static.draw()
	Emulator.activeComputer.screen:draw()
end

local function updateShortcut(name, key1, key2, cb)
	if Emulator.activeComputer.actions[name] ~= nil then
		if love.keyboard.isDown(key1) and love.keyboard.isDown(key2) then
			if love.timer.getTime() - Emulator.activeComputer.actions[name] > 1 then
				Emulator.activeComputer.actions[name] = nil
				if cb then cb() end
			end
		else
			Emulator.activeComputer.actions[name] = nil
		end
	end
end

function Emulator.static.update(dt)
	local now = love.timer.getTime()
	HttpRequest.checkRequests()
	if Emulator.activeComputer.reboot then Emulator.activeComputer:start() end

	-- TODO: See below todo about pasive/active checking
	updateShortcut("terminate", "lctrl", "t", function()
			table.insert(Emulator.activeComputer.eventQueue, {"terminate"})
		end)
	updateShortcut("shutdown", "lctrl", "s", function()
			Emulator.activeComputer:stop()
		end)
	updateShortcut("reboot", "lctrl", "r", function()
			Emulator.activeComputer:stop( true )
		end)

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

	--MOUSE
	if Emulator.activeComputer.mouse.isPressed then
    	local mouseX     = love.mouse.getX()
    	local mouseY     = love.mouse.getY()
    	local termMouseX = math.floor( mouseX / Screen.pixelWidth ) + 1
    	local termMouseY = math.floor( mouseY / Screen.pixelHeight ) + 1
    	if (termMouseX ~= Emulator.activeComputer.mouse.lastTermX or termMouseY ~= Emulator.activeComputer.mouse.lastTermY)
			and (mouseX > 0 and mouseX < Screen.width * Screen.pixelWidth and
				mouseY > 0 and mouseY < Screen.height * Screen.pixelHeight) then

        	Emulator.activeComputer.mouse.lastTermX = termMouseX
       		Emulator.activeComputer.mouse.lastTermY = termMouseY

        	table.insert (Emulator.activeComputer.eventQueue, { "mouse_drag", love.mouse.isDown( "r" ) and 2 or 1, termMouseX, termMouseY})
    	end
    end

    local currentClock = os.clock()

    -- Check if a second has passed since the last update.
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
		for k, v in pairs(Emulator.activeComputer.eventQueue) do -- TODO: Limit amount of resumes on one tick
			Emulator.activeComputer:resume(unpack(v))
		end
		Emulator.activeComputer.eventQueue = {}
	end
end

function Emulator.static.keypressed( key, isrepeat )
	-- TODO: love.system.getClipboardText( ) on ctrl + v shortcut. & queue as char events & normalize line breaks (possibly?)
	if not isrepeat then
		if Emulator.activeComputer.actions.terminate == nil and love.keyboard.isDown("lctrl") and key == "t" then
			Emulator.activeComputer.actions.terminate = love.timer.getTime()
		elseif Emulator.activeComputer.actions.shutdown == nil and love.keyboard.isDown("lctrl") and key == "s" then
			Emulator.activeComputer.actions.shutdown = love.timer.getTime()
		elseif Emulator.activeComputer.actions.reboot == nil and love.keyboard.isDown("lctrl") and key == "r" then
			Emulator.activeComputer.actions.reboot = love.timer.getTime()
		else -- Ignore key shortcuts before "press any key" action. TODO: This might be slightly buggy!
			if not Emulator.activeComputer.running then
				Emulator.activeComputer:start()
				return
			end
		end
	end

	if Util.KEYS[key] then
   		table.insert(Emulator.activeComputer.eventQueue, {"key", Util.KEYS[key]})
   	end
end

function Emulator.static.keyreleased( key, unicode )
	-- TODO: Better key combo/shortcut system
	-- Watch keys passively rather than actively checking.
end

function Emulator.static.textinput( text )
	-- Can this be multiple characters?
	-- Just in case
	if string.len(text) > 1 then -- Speedy check
		for char in string.gmatch(text, "(.-)") do
			table.insert(Emulator.activeComputer.eventQueue, {"char", char})
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

		if not Emulator.activeComputer.mousePressed and _button == "r" or _button == "l" then
			Emulator.activeComputer.mouse.isPressed = true
			local button = _button == "r" and 2 or 1
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_click", button, termMouseX, termMouseY})

		elseif _button == "wu" then -- Scroll up
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_scroll", -1, termMouseX, termMouseX})

		elseif _button == "wd" then -- Scroll down
			table.insert(Emulator.activeComputer.eventQueue, {"mouse_scroll", 1, termMouseX, termMouseY})

		end
	end
end

function Emulator.static.mousereleased( x, y, _button )
	if x > 0 and x < Screen.width * Screen.pixelWidth
		and y > 0 and y < Screen.height * Screen.pixelHeight then -- Within screen bounds.

		Emulator.activeComputer.mouse.isPressed = false
	end
end
