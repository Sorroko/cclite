-- _DEBUG = false
_FPS = 30
function love.conf(t)
    t.title = "ComputerCraft Emulator"
    t.author = "Sorroko"
    t.version = "0.9.0"
    t.modules.physics = false
    t.modules.audio = false
    t.modules.sound = false
    t.modules.joystick = false
    --t.modules.window = false
    -- TODO: This needs to be fixed, cannot currently disable due to love.graphics.* calls in love.load

    -- if _DEBUG then
   	--     t.console = true
    -- else
    --     t.console = false
    -- end
end
