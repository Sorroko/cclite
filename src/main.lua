--[[ TODO
 Run emulator in a thread to avoid stalling main thread, "too long without yielding"
 There should be spaces on the borders of the screen, where the cells are slightly larger than they are near the middle.
 Term api draws directly to a love2d canvas
 Config with custom colours
 UI for peripherals etc.
 Add bit api
 Image fonts (gamax92)
 Implement:
	redstone
	disk
	disk_eject
	modem_message
	monitor_touch
	monitor_resize
]]

-- Simple logger
function log(msg, level)
    if not _DEBUG then return end
    if level ~= "ERROR" and level ~= "WARNING" then level = "INFO" end
    local str = "[" .. os.date("%X") .. "][" .. level .. "]: " .. tostring(msg)
    print(str)
end

require 'lib.middleclass'
require 'lib.http.HttpRequest'

require 'util'
require 'emulator.emulator'
require 'ui.window'
require 'ui.panel'

local emulator, panel
function love.load(args)
    if type(args) == "table" then
        for k, v in pairs(args) do
            if v == "--console" then
                _DEBUG = true
            end
        end
    end
    log("Application starting...")

    PeripheralManager.parse()

	love.filesystem.setIdentity( "cclite" )
	if not love.filesystem.exists( "data/" ) then
        log("Creating save directory")
		love.filesystem.createDirectory( "data/" )
	end

	love.keyboard.setKeyRepeat( 0.5, 0.05 )

    Window.main = Window( "ComputerCraft Emulator" )

    emulator = Emulator(0, 0)
    --panel = Panel(emulator:getWidth(), 0, emulator)

    Window.main:create()

    -- TODO: Some nice icons? love.window.setIcon

    local font = love.graphics.newFont( 'res/minecraft.ttf', 16 )
    -- local glyphs = ""
    -- for i = 32,126 do
    --     glyphs = glyphs .. string.char(i)
    -- end
    -- local font = love.graphics.newImageFont("res/minecraft.png", glyphs)
    -- font:setFilter("nearest","nearest")
    Screen.setFont(font)

    local computer = emulator:registerComputer({advanced = true})
    computer:start()
end

function love.update(dt)
    HttpRequest.checkRequests()
    emulator:update(dt)
end
function love.draw()
    Window.main:draw()
end

local _events = {}
function love.on(event, callback)
    if type(callback) ~= "function" then return end
    if not _events[event] then _events[event] = {} end
    table.insert(_events[event], callback)
end

function love.emit(event, ...)
    if not _events[event] then return end
    for k, v in pairs(_events[event]) do
        pcall(v, ...)
    end
end

function love.run()
    if love.math then
        love.math.setRandomSeed(os.time())
    end

    if love.event then
        love.event.pump()
    end

    if love.load then love.load(arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0
    local fps = 1 / _FPS
    local showFPS = false

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if love.audio then
                        love.audio.stop()
                    end
                    return
                end
                --love.handlers[e](a,b,c,d)
                love.emit(e, a, b, c, d)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.window and love.graphics and love.window.isCreated() then
            love.graphics.clear()
            love.graphics.origin()
            if love.draw then love.draw() end
            --if _DEBUG then
			--	love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
			--end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(fps) end
    end

end
