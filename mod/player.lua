---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by jefftastic.
--- DateTime: 8/8/24 12:28 PM
---

require("mod.entity")
require("mod.player_bullet")
Player = Entity:extend()

-- Initialize constants
local STATE_ALIVE = 0
local STATE_DEAD  = -1

local WEAPON_SINGLE = 1
local WEAPON_TRIPLE = 2

-- Returns a player object
function Player.new(self)
    Player.super.new(self)
    self.sprite = imgPlayer
    self.boom = love.graphics.newImage("asset/sprite/boom.png")
    self.state = STATE_ALIVE
    self.weapon = WEAPON_TRIPLE
    self.x = 32
    self.y = SCREEN_Y / 2
    self.width = 8
    self.height = 8
    self.x_input = 0
    self.y_input = 0
    self.max_speed = 150

    self.dead = false
    self.e_timer = 0
    self.e_end = 1
end

-- Update player based on input, collide
function Player.update(self, dt)
    switch(self.state) {
        [STATE_ALIVE] = function()
            -- Manage input and move
            self.updateSpeed(self, dt)
            self.super.update(self, dt)
        end,
        [STATE_DEAD] = function()
            -- Increment death timer
            self.e_timer = self.e_timer + dt
            if self.e_timer >= self.e_end then self.dead = true end
        end
    }

    -- Clamp position on screen
    self.x = math.max(16, math.min(self.x, SCREEN_X / 3))
    self.y = math.max(16 + HUD_HEIGHT, math.min(self.y, SCREEN_Y - 16))
end

-- Update player visuals
function Player.draw(self)
    if self.dead ~= true then self.super.draw(self) end
end

function Player.input(self, scancode)
    -- Get vector of movement
    self.y_input = -booltonum(love.keyboard.isDown("up")) + booltonum(love.keyboard.isDown("down"))
    self.x_input = -booltonum(love.keyboard.isDown("left")) + booltonum(love.keyboard.isDown("right"))

    -- Check for shooting
    if scancode == "z" then
        self:fireWeapon()
    end
end

-- Manages speed values
function Player.updateSpeed(self, dt)
    self.x_speed = self.x_speed + ((self.max_speed * self.x_input) - self.x_speed) * (12 * dt)
    self.y_speed = self.y_speed + ((self.max_speed * self.y_input) - self.y_speed) * (12 * dt)
end

function Player:destroy()
    -- Set values
    self.state = STATE_DEAD
    self.x_speed = 0
    self.y_speed = 0
    self.sprite = self.boom
    forcePlay(sfxBoom)

    -- Set game state
    set_game_state(GS_DEAD)
end

-- Fires weapon
function Player:fireWeapon()
    switch(self.weapon) {
        [WEAPON_SINGLE] = function()
            -- Create a bullet at our position
            local b = PlayerBullet(self.x, self.y)
            b.x = self.x
            b.y = self.y

            -- Add to pool
            local res = gPlayerBullets:append(b)
            if res == true then
                -- Play sound effect
                forcePlay(sfxShoot)
            end
        end,
        [WEAPON_TRIPLE] = function()
            -- Abort if any bullets exist
            if gPlayerBullets.count > 0 then return end

            -- Create triple bullet
            for i=0,2 do
                local b = PlayerBullet(self.x, self.y)
                b.x = self.x
                b.y = self.y
                b.y_speed = 30 + (-30 * i)

                -- Add to pool
                local res = gPlayerBullets:append(b)
                if res == true then
                    -- Play sound effect
                    forcePlay(sfxShoot)
                end
            end
        end
    }
end

-- Returns weapon graphic
function Player:getWeaponGraphic()
    return imgWeapon[self.weapon]
end

-- Converts bool into a number
function booltonum(b)
    return b and 1 or 0
end