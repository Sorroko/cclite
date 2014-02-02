_DEBUG = false
_FPS = 30
function love.conf(t)
    t.title = "ComputerCraft Emulator"
    t.author = "Sorroko"
    t.version = "0.9.0"
    t.screen = false -- Disable screen, wait for resize in main.lua
    t.modules.physics = false

    if _DEBUG then
   	t.console = true
        t.release = false
    else
        t.console = false
        t.release = true
    end
end
