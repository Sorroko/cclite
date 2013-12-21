--[[ TODO
 Run emulator in a thread to avoid stalling main thread (user code protection)
 There should be spaces on the borders of the screen, where the cells are slightly larger than they are near the middle.
 Better shortcuts/key combos
 Fix font initializing
 Term api draws directly to a love2d canvas, passive screen api.
 Look up table of font widths (gamax92s fix)
 See native_api.lua for more TODOs
 Implement:
	redstone
	disk
	disk_eject
	peripheral
	peripheral_detatch
	modem_message
	monitor_touch
	monitor_resize
]]

require 'lib.middleclass'
require 'lib.http.HttpRequest'

require 'util'
require 'native_api'
require 'screen'
require 'computer'
require 'emulator'

function love.load()
	love.window.setMode( Screen.width * Screen.pixelWidth, Screen.height * Screen.pixelHeight, {
		fullscreen = false,
		vsync = true,
		fsaa = 0,
		resizable = false,
		borderless = false
	} )
	love.window.setTitle( "ComputerCraft Emulator" )
	--love.window.setIcon

	font = love.graphics.newFont( 'res/minecraft.ttf', 16 )
	love.graphics.setFont(font)

	love.filesystem.setIdentity( "cclite" ) -- WARN: CHANGED SAVE DIRECTORY
	if not love.filesystem.exists( "data/" ) then
		love.filesystem.createDirectory( "data/" ) -- Make the user data folder
	end

	love.keyboard.setKeyRepeat( 0.5, 0.05 )

	Emulator.activeComputer:start()
end

function love.mousereleased( x, y, _button ) Emulator.mousereleased( x, y, _button ) end
function love.mousepressed( x, y, _button ) Emulator.mousepressed(x, y, _button) end
function love.keypressed(key, isrepeat) Emulator.keypressed(key, isrepeat) end
function love.textinput(text) Emulator.textinput(text) end
function love.update(dt) Emulator.update(dt) end
function love.draw() Emulator.draw() end

local FPS = 30
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
    local fps = 1 / FPS
    local showFPS = false

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then
                            love.audio.stop()
                        end
                        return
                    end
                end
                love.handlers[e](a,b,c,d)
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
            if showFPS then
				love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
			end
            love.graphics.present()
        end

        if love.timer then love.timer.sleep(fps) end
    end

end
