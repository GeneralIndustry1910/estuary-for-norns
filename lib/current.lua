--- State for one continuously looping sample.
local Current = {}
Current.__index = Current

function Current.new(index)
  return setmetatable({
    index = index,
    path = nil,
    name = "empty",
    speed = 1,
    position = 0,
    tide_period = 16,
    tide_phase = (index - 1) / 4,
    volume = 0.8,
    sample_gain = 1,
    lfo_shape = 1,
    lfo_rate = 0.1,
    delay_send = 0,
    lfo_value = 0,
    loaded = false,
    loop_start = 0,
    loop_end = 1,
    waveform = { 0.3, 0.55, 0.8, 0.45, 0.7, 0.35, 0.6, 0.4 }
  }, Current)
end

function Current:set_sample(path, name, loop_start, loop_end)
  self.path = path
  self.name = name
  self.loop_start = loop_start
  self.loop_end = loop_end
  self.position = 0
  self.loaded = true
end

function Current:set_position(seconds)
  local duration = self.loop_end - self.loop_start
  if not self.loaded or duration <= 0 then
    self.position = 0
    return
  end
  self.position = ((seconds - self.loop_start) / duration) % 1
end

function Current:tide_level(now)
  local cycle = (now / self.tide_period + self.tide_phase) % 1
  return self.volume * (0.5 - 0.5 * math.cos(cycle * math.pi * 2))
end

--- Return a 0..1 gain based on the nearest other loaded playhead.
-- Positions wrap, so playheads near opposite ends of a loop are still close.
function Current:proximity_gain(currents, falloff)
  local nearest = 0.5
  local has_neighbor = false

  for _, other in ipairs(currents) do
    if other ~= self and other.loaded then
      local distance = math.abs(self.position - other.position)
      distance = math.min(distance, 1 - distance)
      nearest = math.min(nearest, distance)
      has_neighbor = true
    end
  end

  if not has_neighbor then return 0 end
  local linear = math.max(0, 1 - nearest * 2)
  return linear ^ (falloff or 1)
end

function Current:lfo_at_phase(phase)
  phase = phase % 1
  if self.lfo_shape == 2 then
    return 1 - math.abs(phase * 2 - 1)
  elseif self.lfo_shape == 3 then
    return phase
  elseif self.lfo_shape == 4 then
    return phase < 0.5 and 1 or 0
  end
  return 0.5 - 0.5 * math.cos(phase * math.pi * 2)
end

function Current:update_lfo(now)
  self.lfo_value = self:lfo_at_phase(now * self.lfo_rate + self.tide_phase)
  return self.lfo_value
end

return Current
