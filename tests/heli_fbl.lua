-- Disposable Ethos simulator only; stage production controller at /controller.lua.
simulator.loadModel("model00.bin")
simulator.sleep(0.2)
local nativeForm, nativeSize = form, lcd.getWindowSize
local fields = {}
local function field(label, rect, get, set)
    if type(label) == "table" then label = label.label end
    local f = {get = get, set = set, enable = function(self, v) self.enabled = v end, suffix = function() end}
    fields[label] = f
    return f
end
form = {height = function() return 108 end, addLine = function(label) return {label = label} end,
    addStaticText = function(line, rect, value) if line and rect and rect.x == 0 then line.label = value end end,
    addSwitchField = field, addBooleanField = field,
    addChoiceField = function(label, rect, choices, get, set) return field(label, rect, get, set) end,
    addNumberField = function(line, rect, low, high, get, set) return field(line.label .. " value", rect, get, set) end}
lcd.getWindowSize = function() return 800, 480 end
local function set(label, value) assert(fields[label], label).set(value) end
local function position(member) return system.getSource({category = CATEGORY_SWITCH_POSITION, member = member}) end
local function output(channel) return system.getSource({category = CATEGORY_CHANNEL, member = channel - 1}):value() end
local wizard = assert(loadfile("/controller.lua"))()
if TEST_CATEGORY then wizard.startCategory() else wizard.startLegacy() end
wizard.build(1)
set("First four fixed OFF", true)
set("Model type", 3)
assert(not wizard.available(5) and not wizard.available(6) and wizard.available(7), "No extra governor assignment page")
wizard.build(2)
set("Governor type", TEST_ESC and 2 or 1)
set("Throttle hold (CH3)", position(0))
set("Ignore rescue", TEST_IGNORE_RESCUE == true)
if not TEST_IGNORE_RESCUE then set("Rescue active (CH8)", position(12)) end
wizard.build(3)
for i = 1, 3 do
    set("Gyro position " .. i .. " (CH5)", position(5 + i))
    set("Gyro position " .. i .. " (CH5) value", ({-30, 45, 70})[i])
end
wizard.build(4)
local bankLabels = {"Bank/IdleUP 1 (CH7 -100%)", "Bank/IdleUP 2 (CH7 0%)", "Bank/IdleUP 3 (CH7 +100%)"}
for i = 1, 3 do set(bankLabels[i], position(TEST_SHARED and 5 + i or 8 + i)) end
assert(not fields["Governor on (CH3)"], "FBL governor needs no separate on assignment")
if TEST_ESC then
    for i = 1, 3 do set(bankLabels[i] .. " value", ({60, 70, 85})[i]) end
end
local function ready(expected)
    wizard.build(7)
    assert(fields["Click button to create CH1-CH8"].enabled == expected, "Review availability")
end
set(bankLabels[2], position(TEST_SHARED and 6 or 9))
ready(false) -- Duplicated bank position.
set(bankLabels[2], position(TEST_SHARED and 7 or 10))
set("Gyro position 2 (CH5)", position(6))
ready(false)
set("Gyro position 2 (CH5)", position(7))
set("Throttle hold (CH3)", position(6))
ready(false) -- Hold cannot change gyro/bank settings.
set("Throttle hold (CH3)", position(0))
if not TEST_IGNORE_RESCUE then
    set("Rescue active (CH8)", position(0)); ready(false)
    set("Rescue active (CH8)", position(12))
end
-- Switching governor modes retains the single bank switch assignment.
set("Governor type", TEST_ESC and 1 or 2)
ready(true)
set("Governor type", TEST_ESC and 2 or 1)
ready(true)
local nativeLogicSwitch = model.createLogicSwitch
if not TEST_ESC then model.createLogicSwitch = nil end
ready(true)
set("Click button to create CH1-CH8", true)
model.createLogicSwitch = nativeLogicSwitch
model.dirty()
local names = {"Aileron", "Elevator", "Throttle", "Rudder", "Gyro Gain", "Collective", "Bank/IdleUP", "Rescue"}
for i, name in ipairs(names) do assert(model.getChannel(i - 1):name() == name, "Wrong CH" .. i) end
assert(model.getChannel(8):name() == "", "No CH9")
assert(wizard.run() == false, "Cannot create duplicate channels")
form, lcd.getWindowSize = nativeForm, nativeSize
for hold = -1, 1 do
    simulator.setSwitch(0, hold)
    for speed = -1, 1 do
        simulator.setSwitch(1, speed)
        for gyro = -1, 1 do
            simulator.setSwitch(2, gyro)
            for bank = -1, 1 do
                simulator.setSwitch(3, bank)
                for rescue = -1, 1, 2 do
                    simulator.setSwitch(4, rescue)
                    simulator.sleep(0.02)
                    local bankPosition = TEST_SHARED and gyro or bank
                    local throttle = TEST_ESC and ({20, 40, 70})[bankPosition + 2] or 100
                    if hold == -1 then throttle = -100 end
                    assert(math.abs(output(3) - throttle * 10.24) < 2, "CH3 hold/governor")
                    assert(math.abs(output(5) - ({-30, 45, 70})[gyro + 2] * 10.24) < 2, "CH5 gyro")
                    assert(output(7) == (TEST_SHARED and gyro or bank) * 1024, "CH7 banks")
                    assert(output(8) == (TEST_IGNORE_RESCUE and -1024 or -rescue * 1024), "CH8 rescue")
                end
            end
        end
    end
end
for _, axis in ipairs({{0, 4}, {1, 6}, {2, 2}, {3, 1}}) do
    for _, v in ipairs({-100, 100}) do
        simulator.setAnalog(axis[1], v); simulator.sleep(0.03)
        assert(math.abs(output(axis[2]) - v * 10.24) < 2, "Independent linear stick CH" .. axis[2])
    end
end
simulator.setSwitch(0, -1)
simulator.sleep(1.3)
simulator.loadModel("model00.bin"); simulator.sleep(0.2)
assert(output(3) == -1024, "Saved hold")
simulator.setSwitch(0, 1); simulator.setSwitch(2, 1); simulator.setSwitch(3, 1); simulator.sleep(0.1)
assert(math.abs(output(3) - (TEST_ESC and 716.8 or 1024)) < 2, "Saved governor")
for i, name in ipairs(names) do assert(model.getChannel(i - 1):name() == name, "Saved channels") end
wizard.close()
assert(not wizard.available(), "Cleanup")
print("PASS: Heli FBL " .. (TEST_ESC and "ESC" or "FBL") .. " governor, 162 switch combinations, hold override, gyro, bank, rescue, sticks, persistence")
