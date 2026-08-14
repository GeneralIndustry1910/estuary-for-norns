--- Screen drawing for Estuary. Playheads deliberately receive maximum contrast.
local UI = {}
UI.__index = UI

local ROW_Y = { 14, 28, 42, 56 }
local LEFT = 27
local RIGHT = 126

function UI.new(currents)
  return setmetatable({ currents = currents, selected = 1 }, UI)
end

local function short_name(name)
  if #name <= 9 then return name end
  return name:sub(1, 7) .. "~"
end

function UI:draw()
  screen.clear()
  screen.font_face(1)
  screen.font_size(8)

  for index, current in ipairs(self.currents) do
    local y = ROW_Y[index]
    screen.level(index == self.selected and 10 or 4)
    screen.move(1, y + 2)
    screen.text(short_name(current.name))

    -- The landscape shows the LFO shape assigned to this current.
    screen.level(current.loaded and 3 or 1)
    local count = #current.waveform
    local segment = (RIGHT - LEFT) / (count - 1)
    screen.move(LEFT, y)
    for point = 1, count do
      local amplitude = current:lfo_at_phase((point - 1) / (count - 1))
      local x = LEFT + (point - 1) * segment
      screen.line(x, y + 4 - amplitude * 8)
    end
    screen.stroke()

    screen.level(2)
    screen.move(LEFT, y + 5)
    screen.line(RIGHT, y + 5)
    screen.stroke()

    -- The playhead is the brightest and tallest element in every row.
    local playhead_x = LEFT + current.position * (RIGHT - LEFT)
    screen.level(current.loaded and 15 or 3)
    screen.move(playhead_x, y - 6)
    screen.line(playhead_x, y + 6)
    screen.stroke()
  end

  screen.update()
end

return UI
