-- Run with TEST_ELRS=true for the ELRS layout; false/nil tests standard.
-- Disposable X18RS Ethos 26.1.2 / 26.2.0-RC1 simulator ONLY. This changes scratch
-- radio settings and creates mixes. Stage translated /controller.lua and
-- /register.lua. The factory workspace must have no existing mixes.
simulator.setAnalog(1, -100)
simulator.loadModel("model00.bin")
simulator.sleep(0.2)
if not TEST_PRECONFIGURED then
system.openPage({system = 6})
simulator.sleep(0.2)
simulator.turnRotaryEncoder(8)
simulator.sleep(0.2)
simulator.touch(730, 440)
simulator.sleep(0.2)

end

local fields = {}
local nativeForm, nativeWindowSize = form, lcd.getWindowSize
lcd.getWindowSize = function() return 800, 480 end
form = {addLine = function(label) return label end, addStaticText = function() end}
local function field(label, _, get, set)
    local result = {get = get, set = set}
    result.enable = function(_, value) result.enabled = value end
    fields[label] = result
    return result
end
form.addSwitchField, form.addBooleanField = field, field
local nativeRegister, nativeLoadfile = system.registerWizardPage, loadfile
local descriptors, loads = {}, 0
local lastControllerPath
local register = assert(nativeLoadfile("/register.lua"))()
system.registerWizardPage = nil
register()
system.registerWizardPage = function(value) descriptors[#descriptors + 1] = value end
loadfile = function(path, ...)
    if path == "SCRIPTS:/rfsuite/app/lib/model_wizard.lua"
        or path == "SCRIPTS:/rotorflight-model-wizard/app/lib/model_wizard.lua" then
        loads = loads + 1
        lastControllerPath = path
        return nativeLoadfile("/controller.lua", ...)
    end
    return nativeLoadfile(path, ...)
end
register()
assert(#descriptors == 7 and loads == 0, "Lazy registration")
assert(descriptors[1].available() and not descriptors[2].available())
descriptors[1].build()
fields["Use ELRS channel order"].set(true)
assert(loads == 1 and descriptors[2].available(), "ELRS selection enables setup pages")
assert(fields["Set up Rotorflight switches"].get(), "Setup toggle reflects ELRS selection")
for page = 2, 7 do assert(descriptors[page].available(), "ELRS page available " .. page) end
fields["Set up Rotorflight switches"].set(false)
assert(not descriptors[2].available() and not fields["Use ELRS channel order"].get(), "Disable clears ELRS selection")
fields["Set up Rotorflight switches"].set(true)
assert(descriptors[2].available(), "Standard setup remains available")
descriptors[1].init()
assert(not descriptors[2].available(), "New-session reset")
descriptors[1].build()
assert(loads == 2 and not descriptors[2].available())
assert(lastControllerPath == "SCRIPTS:/rfsuite/app/lib/model_wizard.lua", "Suite callback must use an absolute path")
descriptors = {}
register("SCRIPTS:/rotorflight-model-wizard")
descriptors[1].build()
assert(loads == 3 and #descriptors == 7)
assert(lastControllerPath == "SCRIPTS:/rotorflight-model-wizard/app/lib/model_wizard.lua", "Standalone callback must use its absolute path")
system.registerWizardPage, loadfile = nativeRegister, nativeLoadfile

local wizard = assert(loadfile("/controller.lua"))()
local function set(label, value) assert(fields[label], label).set(value) end
local function position(member) return system.getSource({category = CATEGORY_SWITCH_POSITION, member = member}) end
local armChannel, throttleChannel, collectiveChannel = TEST_ELRS and 5 or 6, TEST_ELRS and 6 or 3, TEST_ELRS and 3 or 5
local armLabel = "Armed position (CH" .. armChannel .. ")"
local holdLabel = "Throttle hold (CH" .. throttleChannel .. ")"
local function output(channel) return system.getSource({category = CATEGORY_CHANNEL, member = channel - 1}):value() end
assert(not wizard.available())
wizard.run()
wizard.build(1)
set("Set up Rotorflight switches", true)
assert(not pcall(wizard.run), "Preparation must be confirmed")
set("Other model selected", true)
assert(not pcall(wizard.run), "Allocation preparation must be confirmed")
set("First four fixed OFF", true)
assert(not fields["Use ELRS channel order"].get(), "Standard layout by default")
set("Use ELRS channel order", true)
set("Use ELRS channel order", false)
set("Use ELRS channel order", TEST_ELRS == true)
assert(not pcall(wizard.run), "Missing switch assignments")
for page = 2, 6 do wizard.build(page) end
set(armLabel, position(0))
set(holdLabel, position(3))
set("Profile 1 (CH7 -100%)", position(6))
set("Profile 2 (CH7 0%)", position(7))
set("Profile 3 (CH7 +100%)", position(8))
for _, item in ipairs({{"Ignore blackbox", "Blackbox active (CH8)"}, {"Ignore rescue", "Rescue active (CH9)"}}) do
    assert(not fields[item[1]].get(), "Optional switch defaults to assigned")
    set(item[1], true)
    assert(not fields[item[2]].enabled, "Ignored switch disabled")
    set(item[1], false)
    assert(fields[item[2]].enabled, "Restored switch enabled")
end
if TEST_IGNORE_BLACKBOX then set("Ignore blackbox", true)
else set("Blackbox active (CH8)", position(9)) end
if TEST_IGNORE_RESCUE then set("Ignore rescue", true)
else set("Rescue active (CH9)", position(12)) end
wizard.build(7)
assert(fields["Create reviewed CH1-CH9"].enabled, "Unassigned ignored switches permit review")
if TEST_IGNORE_BLACKBOX then
    set("Ignore blackbox", false)
    wizard.build(7)
    assert(not fields["Create reviewed CH1-CH9"].enabled, "Blackbox required again when restored")
    set("Ignore blackbox", true)
    wizard.build(7)
end
if TEST_IGNORE_RESCUE then
    set("Ignore rescue", false)
    wizard.build(7)
    assert(not fields["Create reviewed CH1-CH9"].enabled, "Rescue required again when restored")
    set("Rescue active (CH9)", position(0))
    wizard.build(7)
    assert(not fields["Create reviewed CH1-CH9"].enabled, "Active rescue cannot share arm switch")
    set("Ignore rescue", true)
    wizard.build(7)
    assert(fields["Create reviewed CH1-CH9"].enabled, "Ignored rescue may retain an unused colliding selection")
    set("Rescue active (CH9)", nil)
end
assert(not pcall(wizard.run), "Review must be confirmed")
set("Profile 2 (CH7 0%)", position(6))
assert(not pcall(wizard.run), "Duplicated profile position")
set("Profile 2 (CH7 0%)", position(7))
set(holdLabel, position(2))
assert(not pcall(wizard.run), "Arm and hold must be independent")
set(holdLabel, position(3))
set("Create reviewed CH1-CH9", true) -- The confirmation generates Other drafts.
model.dirty() -- The macro uses a live test model; native creation saves its draft.
wizard.run()
local names = TEST_ELRS
    and {"Aileron", "Elevator", "Pitch", "Rudder", "RF Arm", "RF Throttle", "RF Profile", "RF Blackbox", "RF Rescue"}
    or {"Aileron", "Elevator", "RF Throttle", "Rudder", "Pitch", "RF Arm", "RF Profile", "RF Blackbox", "RF Rescue"}
for channel, name in ipairs(names) do assert(model.getChannel(channel - 1):name() == name, "Wrong CH" .. channel) end
assert(model.getChannel(9):name() == "", "No extra CH10 mix")
wizard.build(2)
assert(fields[armLabel].get():member() == 0, "Back retains assignments")
assert(fields[armLabel].enabled == false, "Generated assignment locked")
wizard.build(1)
assert(not fields["Use ELRS channel order"].enabled, "Generated layout locked")
set("Use ELRS channel order", not TEST_ELRS)
assert(fields["Use ELRS channel order"].get() == (TEST_ELRS == true), "Locked layout rejects mutation")
set(armLabel, position(2))
assert(fields[armLabel].get():member() == 0, "Locked assignment rejects mutation")
wizard.build(5)
wizard.build(6)
assert(not fields["Ignore blackbox"].enabled and not fields["Ignore rescue"].enabled, "Ignore fields lock")
set("Ignore blackbox", not TEST_IGNORE_BLACKBOX)
set("Ignore rescue", not TEST_IGNORE_RESCUE)
assert(fields["Ignore blackbox"].get() == (TEST_IGNORE_BLACKBOX == true), "Ignored blackbox locked")
assert(fields["Ignore rescue"].get() == (TEST_IGNORE_RESCUE == true), "Ignored rescue locked")
form, lcd.getWindowSize = nativeForm, nativeWindowSize

-- Exercise every arm/hold/profile/blackbox/rescue combination on exact channels.
for arm = -1, 1, 2 do
    simulator.setSwitch(0, arm)
    for hold = -1, 1, 2 do
        simulator.setSwitch(1, hold)
        for profile = -1, 1 do
            simulator.setSwitch(2, profile)
            for blackbox = -1, 1, 2 do
                simulator.setSwitch(3, blackbox)
                for rescue = -1, 1, 2 do
                    simulator.setSwitch(4, rescue)
                    simulator.sleep(0.02)
                    assert(output(throttleChannel) == hold * 1024, "CH3 throttle/hold")
                    assert(output(armChannel) == -arm * 1024, "CH6 arm")
                    assert(output(7) == profile * 1024, "CH7 shared rates/profile")
                    assert(output(8) == (TEST_IGNORE_BLACKBOX and -1024 or -blackbox * 1024), "CH8 blackbox")
                    assert(output(9) == (TEST_IGNORE_RESCUE and -1024 or -rescue * 1024), "CH9 rescue")
                end
            end
        end
    end
end
for _, axis in ipairs({{0, 4}, {1, collectiveChannel}, {2, 2}, {3, 1}}) do
    simulator.setAnalog(axis[1], 100)
    simulator.sleep(0.05)
    assert(output(axis[2]) == 1024, "Stick positive CH" .. axis[2])
    simulator.setAnalog(axis[1], -100)
    simulator.sleep(0.05)
    assert(output(axis[2]) == -1024, "Stick negative CH" .. axis[2])
end
simulator.setSwitch(0, 1)
simulator.setSwitch(1, -1)
simulator.sleep(1.2)
simulator.loadModel("model00.bin")
simulator.sleep(0.2)
for channel, name in ipairs(names) do assert(model.getChannel(channel - 1):name() == name, "Saved CH" .. channel) end
assert(output(throttleChannel) == -1024 and output(armChannel) == -1024, "Hold/disarm after reload")
if TEST_IGNORE_BLACKBOX then assert(output(8) == -1024, "Ignored blackbox after reload") end
if TEST_IGNORE_RESCUE then assert(output(9) == -1024, "Ignored rescue after reload") end
wizard.close()
assert(not wizard.available(), "Cleanup")
form = {addLine = function(label) return label end, addStaticText = function() end,
    addSwitchField = field, addBooleanField = field}
lcd.getWindowSize = function() return 800, 480 end
wizard.build(1)
assert(not fields["Use ELRS channel order"].get(), "Cleanup resets layout")
wizard.build(5)
wizard.build(6)
assert(not fields["Ignore blackbox"].get() and not fields["Ignore rescue"].get(), "Cleanup resets ignore flags")
lcd.getWindowSize = nativeWindowSize
form = nativeForm
print((TEST_ELRS and "ELRS " or "Standard ") .. "PASS: nine exact channels, 48 switch combinations, sticks, save/reload, validation, optional switches and cleanup")
