-- `include("lib/...")` resolves from dust/code rather than from this script's
-- directory on norns. Loading from norns.state.path keeps the script working
-- regardless of the name of its enclosing folder.
local Current = dofile(norns.state.path .. "lib/current.lua")
local SoftcutEngine = dofile(norns.state.path .. "lib/softcut_engine.lua")
local UI = dofile(norns.state.path .. "lib/ui.lua")

local currents = {}
local engine
local ui
local tide_metro
local sample_gains = {}
local gain_file

local function save_sample_gains()
  util.make_dir(norns.state.data)
  tab.save(sample_gains, gain_file)
end

local function file_param(index)
  return "current_" .. index .. "_file"
end

local function add_current_params(index)
  local current = currents[index]
  params:add_group("CURRENT " .. index, 9)

  params:add_file(file_param(index), "sample")
  params:set_action(file_param(index), function(path)
    if engine:load(index, path) then
      params:set("current_" .. index .. "_gain", sample_gains[path] or 1)
      redraw()
    end
  end)

  params:add_control("current_" .. index .. "_speed", "speed",
    controlspec.new(-2, 2, "lin", 0.01, 1, "x"))
  params:set_action("current_" .. index .. "_speed", function(value)
    engine:set_rate(index, value)
  end)

  params:add_control("current_" .. index .. "_period", "tide period",
    controlspec.new(2, 120, "exp", 0.1, current.tide_period, "s"))
  params:set_action("current_" .. index .. "_period", function(value)
    current.tide_period = value
  end)

  params:add_control("current_" .. index .. "_phase", "tide phase",
    controlspec.new(0, 1, "lin", 0.01, current.tide_phase))
  params:set_action("current_" .. index .. "_phase", function(value)
    current.tide_phase = value
  end)

  params:add_control("current_" .. index .. "_volume", "volume",
    controlspec.new(0, 1, "lin", 0.01, current.volume))
  params:set_action("current_" .. index .. "_volume", function(value)
    current.volume = value
  end)

  params:add_control("current_" .. index .. "_gain", "sample gain",
    controlspec.new(0, 4, "lin", 0.01, 1, "x"))
  params:set_action("current_" .. index .. "_gain", function(value)
    current.sample_gain = value
    if current.path then
      sample_gains[current.path] = value
      save_sample_gains()
    end
  end)

  params:add_option("current_" .. index .. "_lfo_shape", "LFO shape",
    { "sine", "triangle", "saw", "square" }, current.lfo_shape)
  params:set_action("current_" .. index .. "_lfo_shape", function(value)
    current.lfo_shape = value
  end)

  params:add_control("current_" .. index .. "_lfo_rate", "LFO rate",
    controlspec.new(0.01, 10, "exp", 0.01, current.lfo_rate, "Hz"))
  params:set_action("current_" .. index .. "_lfo_rate", function(value)
    current.lfo_rate = value
  end)

  params:add_control("current_" .. index .. "_delay_send", "delay LFO amount",
    controlspec.new(0, 1, "lin", 0.01, current.delay_send))
  params:set_action("current_" .. index .. "_delay_send", function(value)
    current.delay_send = value
  end)
end

function init()
  gain_file = norns.state.data .. "sample_gains.data"
  sample_gains = tab.load(gain_file) or {}
  for index = 1, 4 do currents[index] = Current.new(index) end
  engine = SoftcutEngine.new(currents)
  ui = UI.new(currents)
  engine:init()

  params:add_separator("ESTUARY")
  params:add_control("proximity_falloff", "proximity falloff",
    controlspec.new(0.25, 8, "exp", 0.01, 1))
  params:set_action("proximity_falloff", function(value)
    engine.proximity_falloff = value
  end)

  params:add_control("delay_time", "delay time",
    controlspec.new(0.05, 4, "exp", 0.01, 0.5, "s"))
  params:set_action("delay_time", function(value)
    engine:set_delay_time(value)
  end)

  params:add_control("delay_feedback", "delay feedback",
    controlspec.new(0, 0.95, "lin", 0.01, 0.35))
  params:set_action("delay_feedback", function(value)
    engine:set_delay_feedback(value)
  end)

  for index = 1, 4 do add_current_params(index) end
  params:bang()

  tide_metro = metro.init(function()
    engine:update(util.time())
    redraw()
  end, 1 / 30)
  tide_metro:start()
end

function enc(number, delta)
  if number == 1 then
    ui.selected = util.clamp(ui.selected + delta, 1, 4)
  elseif number == 2 then
    params:delta("current_" .. ui.selected .. "_speed", delta)
  elseif number == 3 then
    params:delta("current_" .. ui.selected .. "_period", delta)
  end
  redraw()
end

function key(number, pressed)
  if pressed == 0 then return end
  if number == 2 then
    params:set("current_" .. ui.selected .. "_phase", 0)
  end
end

function redraw()
  if ui then ui:draw() end
end

function cleanup()
  if tide_metro then tide_metro:stop() end
  if engine then engine:cleanup() end
end
