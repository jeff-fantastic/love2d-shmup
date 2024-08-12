---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by jeffrey.
--- DateTime: 8/10/24 10:02 PM
---

--- Keeps track of combos.

ComboManager = Object:extend()

function ComboManager:new()
    self:init()
end

function ComboManager:init()
    self.active = false
    self.point_cache = 0
    self.multiplier = 0
    self.current_time = 0.0
    self.time_to_end = 3.0
end

function ComboManager:update(delta)
    -- Abort if inactive
    if self.active ~= true then return end

    -- Otherwise increment timer
    if self.active == true then
        self.current_time = self.current_time + delta
        if self.current_time >= self.time_to_end then
            -- Add points to global
            local total = self.point_cache * self.multiplier - self.point_cache
            gPoints = gPoints + total

            -- Initialize
            self:init()
        end
    end
end

-- Adds point to combo manager
function ComboManager:increment(points)
    self.point_cache = self.point_cache + points
    self.active = true
    self.current_time = 0.0
    self.time_to_end = self.time_to_end * 0.9
    self.multiplier = self.multiplier + 1
end