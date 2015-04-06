-- Simple logger
function log(msg, level)
	if not _DEBUG then return end
	if level ~= "ERROR" and level ~= "WARNING" then level = "INFO" end
	local str = "[" .. os.date("%X") .. "][" .. level .. "]: " .. tostring(msg)
	print(str)
end

-- Import third party libraries
require 'lib.middleclass'
require 'lib.http.HttpRequest'
require 'lib.bit'

-- Imports
require 'util'
require 'config'
require 'emulator.emulator'
require 'ui.window'
require 'ui.panel'
require 'ui.android'

-- Global variables
_FPS = 30
_DEBUG = false
PLATFORM = love.system.getOS()

function love.load(args)

	-- Check for command line arguments
	if type(args) == "table" then
		for k, v in pairs(args) do
			if v == "--console" or v == "--debug" then
				_DEBUG = true
			end
		end
	end

	log("Application starting...")

	love.filesystem.setIdentity( "cclite" )
	if not love.filesystem.exists( "data/" ) then
		log("Creating save directory")
		love.filesystem.createDirectory( "data/" )
	end

	-- Load peripheral types
	PeripheralManager.parse()

	-- Load config
	config = Config("config.conf")
	config:setDefault("strict-colors", false)
	config:setDefault("advanced-computer", true)
	config:setDefault("http-enabled", true)
	config:setDefault("terminal-width", 51)
	config:setDefault("terminal-height", 19)
	config:setDefault("terminal-scale", 2)
	config:load()

	love.keyboard.setKeyRepeat( 0.5, 0.05 )

	main_window = Window( "ComputerCraft Emulator" )

	local _, _, flags = love.window.getMode()
	width, height = love.window.getDesktopDimensions( flags.display )

	if PLATFORM == "Android" then
		android = Android(main_window, 0, 0, width, height) -- blue background and UI
		androidMenu = AndroidMenu(main_window, 0, 0, width)
		emulator = Emulator(main_window, 0, androidMenu:getHeight(), width, height) -- scale to largest size possible

		androidMenu.onPower = function(self)
			emulator:getActiveComputer():stop()
		end
	else
		emulator = Emulator(main_window, 0, 0)
	end
	--panel = Panel(emulator:getWidth(), 0, emulator)

	main_window:create()

	local font
	if PLATFORM == "Android" then
		font = love.graphics.newFont( 'res/minecraft.ttf', 16 )-- * love.window.getPixelScale() )
		androidMenu:postInitialize()
	else
		font = love.graphics.newFont( 'res/minecraft.ttf', 16 )
	end
	-- local glyphs = ""
	-- for i = 32,126 do
	--     glyphs = glyphs .. string.char(i)
	-- end
	-- local font = love.graphics.newImageFont("res/minecraft.png", glyphs)
	-- font:setFilter("nearest","nearest")
	Screen.setFont(font)

	if PLATFORM == "Android" then
		love.keyboard.setTextInput(true)

		love.on("touchreleased", function ( id, x, y, pressure )
			love.keyboard.setTextInput(true)
		end)

		-- Spoof key events
		love.on("textinput", function ( ... )
			love.emit("keypressed", ...) -- TODO: Check if multiple chars in text and set isRepeat to false
		end)
	end

	log(love.filesystem.getSaveDirectory())

	local computer = emulator:registerComputer({advanced = config:getBoolean("advanced-computer", true)})
	computer:start()
end

function love.update(dt)
	HttpRequest.checkRequests()
	emulator:update(dt)
end
function love.draw()
	main_window:draw()
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
