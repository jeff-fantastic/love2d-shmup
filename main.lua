-- REQUIRES
Object = require("mod.classic")
Terebi = require("mod.terebi")
require("mod.pool")
require("mod.player")
require("mod.wave_manager")

local screen
local intermission_timer = 0
local intermission_target = 10
local dead_timer = 0
local dead_target = 3

-- CONSTANTS
GS_ACTIVE       = 0
GS_DEAD         = 1
GS_INTERMISSION = 2
GS_PAUSED       = 3

SCREEN_X   = 320
SCREEN_Y   = 240
HUD_HEIGHT = 48

-- MAIN FUNCTIONS
function love.load()
    -- Create a window using Terebi, so we have cleaner
    -- pixel perfect rendering
    Terebi.initializeLoveDefaults()
    screen = Terebi.newScreen(320, 240, 2)
        :setBackgroundColor(0,0,0)

    -- Initialize graphics and center window
    debug = love.graphics.newFont("asset/fnt/debug.ttf", 8)
    font = love.graphics.setNewFont("asset/fnt/retro.ttf", 16)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    recenter()

    -- Load images
    imgHudZ = love.graphics.newImage("asset/sprite/hud_z.png")
    imgHudX = love.graphics.newImage("asset/sprite/hud_x.png")
    imgPlayer = love.graphics.newImage("asset/sprite/player.png")
    imgWeapon = {
        love.graphics.newImage("asset/sprite/weapon_bullet.png"),
        love.graphics.newImage("asset/sprite/weapon_triple.png")
    }
    imgSpecial = {
        love.graphics.newImage("asset/sprite/special_bomb.png")
    }

    -- Set up game variables
    gLives = 3
    gPoints = 0
    gState = 0
    gDebug = true

    -- Set up objects/pools
    gEnemies = Pool(10)
    gPlayerBullets = Pool(3)
    gWaveManager = WaveManager()
    gPlayer = Player()

    -- Load sound effects into memory
    musDub = love.audio.newSource("asset/snd/jam2.xm", "static")
    sfxShoot = love.audio.newSource("asset/snd/shoot.wav", "static")
    sfxComplete = love.audio.newSource("asset/snd/wave_complete.wav", "static")
    sfxBoom = love.audio.newSource("asset/snd/explode.wav", "static")

    musDub:setVolume(0.25)
    musDub:setLooping(true)
    musDub:play()

    -- Seed randomizer
    math.randomseed(os.clock())
end



-- Called each frame.
function love.update(delta)
    switch(gState) {
        [GS_ACTIVE] = function()
            update_main(delta)
            gWaveManager:update(delta)
        end,
        [GS_INTERMISSION] = function()
            update_main(delta)

            -- Update timer
            intermission_timer = intermission_timer + delta
            if intermission_timer >= intermission_target then
                intermission_timer = 0
                gWaveManager:incrementWave()
                gState = GS_ACTIVE
            end
        end,
        [GS_DEAD] = function()
            gPlayer.update(gPlayer, delta)
        end,
        [GS_PAUSED] = function()
            -- Update pause processing
        end
    }
end

-- Handles rendering each frame.
function drawFunction()
    -- Render entities first
    for i, v in ipairs(gPlayerBullets.pool) do v.draw(v) end
    gPlayer.draw(gPlayer)
    for i, v in ipairs(gEnemies.pool) do v.draw(v) end

    -- Then render hud elements
    switch(gState) {
        [GS_ACTIVE] = function()
            render_hud()
        end,
        [GS_INTERMISSION] = function()
            render_hud()
            render_wave_complete()
        end,
        [GS_PAUSED] = function()
            render_hud()
            render_pause()
        end,
        [GS_DEAD] = function()
            render_hud()
        end
    }
    render_debug()
end

function love.draw()
    screen:draw(drawFunction)
end

-- Main set of updates
function update_main(delta)
    -- Update player
    gPlayer.update(gPlayer, delta)

    -- Iterate and update bullets
    for i, v in ipairs(gPlayerBullets.pool) do
        v.update(v, delta)
    end
    for i, v in ipairs(gEnemies.pool) do
        v.update(v, delta)
    end
end

-- Called when key is pressed.
function love.keypressed(key, scancode, isrepeat)
    switch(gState) {
        [GS_ACTIVE] = function()
            -- Update player input
            gPlayer.input(gPlayer, scancode)

            -- Handle option input
            input_option(scancode)
        end,
        [GS_INTERMISSION] = function()
            -- Update player input
            gPlayer.input(gPlayer, scancode)
        end,
        [GS_PAUSED] = function()
            -- Handle option input
            input_option(scancode)
        end,
        __index = function()

        end
    }
end

-- Called when key is released.
function love.keyreleased(key, scancode)
    switch(gState) {
        [GS_ACTIVE] = function()
            -- Update player input
            gPlayer.input(gPlayer)
        end,
        [GS_INTERMISSION] = function()
            -- Update player input
            gPlayer.input(gPlayer, scancode)
        end,
        __index = function()

        end
    }
end

-- END PROCESS

-- Sets game gState
function set_game_state(state)
    -- Determine entering behavior
    switch(state) {
        [GS_DEAD] = function()
            -- Decrement lives
            gLives = gLives - 1
        end
    }

    -- Set state
    gState = state
end

-- Manages option input
function input_option(scancode)
    -- Debug
    if scancode == "f12" then
        gDebug = not gDebug
    end

    -- Fullscreen
    if scancode == "f11" then
        screen:toggleFullscreen()
        recenter()
    end

    -- Pause
    if scancode == "escape" then
        gState = gState ~= GS_PAUSED and GS_PAUSED or GS_ACTIVE
    end
end

-- Renders HUD to screen
function render_hud()
    -- Draw HUD box
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", 0, 0, SCREEN_X, HUD_HEIGHT)

    -- Draw HUD graphics
    love.graphics.setColor(1,1,1)
    love.graphics.draw(imgHudZ, love.math.newTransform(SCREEN_X - 86, 8))
    love.graphics.draw(gPlayer:getWeaponGraphic(), love.math.newTransform(SCREEN_X - 82, 12))
    love.graphics.draw(imgHudX, love.math.newTransform(SCREEN_X - 48, 8))

    -- Draw points text
    print_small_text("SCORE", {1,1,1}, 0, 12, "center")
    print_hud_text(string.format("%08d", gPoints), {1,1,1}, 0, 26, "center")

    -- Draw lives graphics
    for i=1,gLives do
        love.graphics.draw(imgPlayer, love.math.newTransform(12 + (20 * (i - 1)), 8))
    end

    -- Draw combo
    print_small_text("x0", {1,1,1}, 12, 28)
    love.graphics.rectangle("fill", 12, 38, 80, 3)

end

-- Renders debug info to screen, if applicable
function render_debug()
    -- Abort if outside of debug
    if gDebug ~= true then
        return
    end

    -- Render player x and y
    print_small_text(string.format("x %03d y %03d", gPlayer.x, gPlayer.y), {1,1,1}, 16, SCREEN_Y - 24)
    print_small_text(string.format("pbp %0d w %0.2f mw %0.2f", gPlayerBullets.count, gWaveManager.wait, gWaveManager.micro_wait), {1,1,1}, 16, SCREEN_Y - 16)
end

-- Renders pause menu
function render_pause()
    -- Render background
    love.graphics.setColor(0,0,0, 0.5)
    love.graphics.rectangle("fill", 0, 0, SCREEN_X, SCREEN_Y)

    -- Render text
    print_hud_text("PAUSED", {1,1,1}, 0, 96, "center")
    print_small_text("Unpause by pressing ESCAPE.", {0.8,0.8,0.8}, 0, SCREEN_Y - 96, "center")
end

-- Renders wave complete banner
function render_wave_complete()
    -- Render banner
    love.graphics.setColor(0,0,0,0.4)
    love.graphics.rectangle("fill", 0, SCREEN_Y - 90, SCREEN_X, 64)

    -- Render text
    local str = ""
    if intermission_timer < intermission_target / 2 then
        str = string.format("Wave %0d Complete!", gWaveManager.wave)
    else
        str = "A new wave approaches..."
    end
    print_hud_text(str, {1,1,1}, 0, SCREEN_Y - 64, "center")
end

-- Prints HUD text.
function print_hud_text(str, color, x, y, align)
    -- Default args
    align = align or "left"

    -- Print shadow first
    love.graphics.setColor(0,0,0)
    love.graphics.printf(str, love.math.newTransform(x + 1, y + 1), SCREEN_X - x, align)

    -- Print main now
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.printf(str, love.math.newTransform(x, y), SCREEN_X - x, align)
end

-- Prints small text.
function print_small_text(str, color, x, y, align)
    -- Get information about string
    local len = string.len(str)
    local xs = len * 8
    local xb = align == "center" and SCREEN_X / 2 - xs / 2 or x

    -- Print back first
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", xb, y, xs, 8)

    -- Print main now
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.printf(str, debug, love.math.newTransform(x, y), SCREEN_X - x, align)
end


-- Centers window.
function recenter()
    local dim = {love.window.getDesktopDimensions(1)}
    love.window.setPosition((dim[1] / 2) - SCREEN_X, (dim[2] / 2) - SCREEN_Y, 1)
end

-- Mimics functionality of switch cases
function switch(x)
    return function(cases)
        setmetatable(cases, cases)
        local func = cases[x]
        if func then
            func()
        end
    end
end

-- Ensures sound effect is played on call
function forcePlay(sound)
    sound:stop()
    sound:play()
end