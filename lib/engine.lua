--------------------------------------------------
-- Estuary Engine
--------------------------------------------------

local Engine = {}
Engine.__index = Engine

function Engine.new()

    local self = setmetatable({}, Engine)

    self.time = 0
    self.currents = {}

    return self

end

--------------------------------------------------

function Engine:add(current)

    table.insert(self.currents,current)

end

--------------------------------------------------

function Engine:update(dt)

    self.time = self.time + dt

end

--------------------------------------------------

return Engine