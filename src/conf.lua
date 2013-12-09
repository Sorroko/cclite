function love.conf(t)
    local _debug = true
    t.title = "ComputerCraft Emulator"
    t.author = "Sorroko"
    --t.url = nil
    t.version = "0.8.0"

    t.modules.physics = false

    if _debug then
   	    t.console = true
        t.release = false
	else
        t.screen = false -- Disable screen, wait for resize in main.lua
        t.console = false
        t.release = true
    end
end
