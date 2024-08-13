---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by jeffrey.
--- DateTime: 8/12/24 11:32 AM
---

--- Floats around the edge of the screen and
--- shoots at the player.

require("mod.entity")
require("mod.pool")
require("mod.enemy_bullet")
EnemyShooter = Entity:extend()

local STATE_TRAVEL = 0
local STATE_SHOOT = 1
local STATE_DEAD = -1

function EnemyShooter:new(x, y)
    EnemyShooter.super:new()
    self.sprite = love.graphics.newImage("asset/sprite/enemy_shooter.png")
    self.state = STATE_TRAVEL
    self.x = x or 0
    self.y = y or 0
    self.width = 16
    self.height = 16
    self.x_speed = -50
    self.y_speed = y - HUD_HEIGHT > (SCREEN_Y - HUD_HEIGHT) / 2 and -40 or 40
    self.points = 250

    self.bullet_pool = Pool(2)
    self.c_current = 0.0
    self.c_target = 1.5
end

function EnemyShooter:update(dt)
    self.super.update(self, dt)

    switch(self.state) {
        [STATE_TRAVEL] = function()
            -- Check if at edge
            if self.x <= SCREEN_X - 32 then
                self.x_speed = 0
                self.state = STATE_SHOOT
            end
        end,
        [STATE_SHOOT] = function()
            -- Wait for bullet cooldown
            self.c_current = self.c_current + dt
            if self.c_current >= self.c_target then
                -- Shoot bullet
                local b = EnemyBullet(self.x, self.y, self.bullet_pool)
                local res = self.bullet_pool:append(b)
                if res == true then forcePlay(sfxShoot) end

                -- Reset timer
                self.c_current = 0.0
            end
        end,
        [STATE_DEAD] = function()
            -- Increment death timer
            self.e_timer = self.e_timer + dt
            if self.e_timer >= self.e_end then
                if self.bullet_pool.count == 0 then gEnemies:remove_at(self.rid) end
            end
        end
    }

    if self.y <= HUD_HEIGHT + 16 or self.y >= SCREEN_Y - 16 then
        self.y_speed = self.y_speed * -1
    end

    for i,v in ipairs(self.bullet_pool.pool) do
        v.update(v, dt)
    end

end

function EnemyShooter:draw()

    self.super.draw(self)

    for i,v in ipairs(self.bullet_pool.pool) do
        v.draw(v)
    end
end
