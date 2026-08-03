--- All Softcut setup, sample loading, and level updates live here.
local SoftcutEngine = {}
SoftcutEngine.__index = SoftcutEngine

local BUFFER_SECONDS = 300
local VOICE_COUNT = 4
local DELAY_VOICE = 5
local DELAY_SECONDS = 8
local DELAY_START = BUFFER_SECONDS - DELAY_SECONDS
local SLOT_SECONDS = DELAY_START / VOICE_COUNT

local function basename(path)
  return path:match("([^/]+)$") or path
end

function SoftcutEngine.new(currents)
  return setmetatable({ currents = currents, proximity_falloff = 1,
    delay_time = 0.5, delay_feedback = 0.35 }, SoftcutEngine)
end

function SoftcutEngine:init()
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(0)

  for voice = 1, VOICE_COUNT do
    local start = (voice - 1) * SLOT_SECONDS + 0.01
    softcut.enable(voice, 1)
    softcut.buffer(voice, 1)
    softcut.play(voice, 0)
    softcut.loop(voice, 1)
    softcut.loop_start(voice, start)
    softcut.loop_end(voice, start + 1)
    softcut.position(voice, start)
    softcut.rate(voice, 1)
    softcut.fade_time(voice, 0.05)
    softcut.level_slew_time(voice, 0.05)
    softcut.level(voice, 0)
    softcut.phase_quant(voice, 0.04)
    softcut.level_cut_cut(voice, DELAY_VOICE, 0)
  end

  softcut.enable(DELAY_VOICE, 1)
  softcut.buffer(DELAY_VOICE, 1)
  softcut.loop(DELAY_VOICE, 1)
  softcut.loop_start(DELAY_VOICE, DELAY_START)
  softcut.loop_end(DELAY_VOICE, DELAY_START + self.delay_time)
  softcut.position(DELAY_VOICE, DELAY_START)
  softcut.rate(DELAY_VOICE, 1)
  softcut.rec_level(DELAY_VOICE, 1)
  softcut.pre_level(DELAY_VOICE, self.delay_feedback)
  softcut.level(DELAY_VOICE, 1)
  softcut.level_slew_time(DELAY_VOICE, 0.05)
  softcut.rec(DELAY_VOICE, 1)
  softcut.play(DELAY_VOICE, 1)

  softcut.event_phase(function(voice, position)
    local current = self.currents[voice]
    if current then current:set_position(position) end
  end)
  softcut.poll_start_phase()
end

function SoftcutEngine:load(voice, path)
  if not path or path == "-" or path == "" then return false end

  local channels, frames, sample_rate = audio.file_info(path)
  if not channels or not frames or not sample_rate or sample_rate == 0 then
    print("estuary: could not read " .. path)
    return false
  end

  local start = (voice - 1) * SLOT_SECONDS + 0.01
  local duration = math.min(frames / sample_rate, SLOT_SECONDS - 0.02)
  if duration <= 0 then return false end

  softcut.play(voice, 0)
  softcut.buffer_clear_region(start, SLOT_SECONDS)
  softcut.buffer_read_mono(path, 0, start, duration, 1, 1)
  softcut.loop_start(voice, start)
  softcut.loop_end(voice, start + duration)
  softcut.position(voice, start)
  softcut.rate(voice, self.currents[voice].speed)
  self.currents[voice]:set_sample(path, basename(path), start, start + duration)
  softcut.play(voice, 1)
  return true
end

function SoftcutEngine:set_rate(voice, rate)
  self.currents[voice].speed = rate
  softcut.rate(voice, rate)
end

function SoftcutEngine:set_delay_time(seconds)
  self.delay_time = seconds
  softcut.loop_end(DELAY_VOICE, DELAY_START + seconds)
end

function SoftcutEngine:set_delay_feedback(amount)
  self.delay_feedback = amount
  softcut.pre_level(DELAY_VOICE, amount)
end

function SoftcutEngine:update(now)
  for voice, current in ipairs(self.currents) do
    local level = 0
    if current.loaded then
      level = current:tide_level(now) * current.sample_gain
        * current:proximity_gain(self.currents, self.proximity_falloff)
    end
    softcut.level(voice, level)
    local lfo = current:update_lfo(now)
    softcut.level_cut_cut(voice, DELAY_VOICE,
      current.loaded and current.delay_send * lfo or 0)
  end
end

function SoftcutEngine:cleanup()
  softcut.poll_stop_phase()
  for voice = 1, DELAY_VOICE do softcut.enable(voice, 0) end
end

return SoftcutEngine
