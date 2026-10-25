-- Run with TEST_ELRS=true for the ELRS layout; false/nil tests FrSky.
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

local fields, texts = {}, {}
local nativeForm, nativeWindowSize = form, lcd.getWindowSize
lcd.getWindowSize = function() return 800, 480 end
local function line(label) return {label = label} end
local function staticText(line, rect, value)
    texts[value] = true
    if line and rect and rect.x == 0 then line.label = value end
end
form = {height = function() return 108 end, addLine = line, addStaticText = staticText}
local function field(label, _, get, set)
    if type(label) == "table" then label = label.label end
    local result = {get = get, set = set}
    result.enable = function(_, value) result.enabled = value end
    fields[label] = result
    return result
end
form.addSwitchField, form.addBooleanField = field, field
form.addChoiceField = function(label, rect, choices, get, set)
    assert(#choices == 3 and choices[1][1] == "FrSky RF" and choices[2][1] == "ELRS RF" and choices[3][1] == "Heli FBL", "Three model types")
    return field(label, rect, get, set)
end
form.addTextButton = function(_, _, label, press)
    fields[label] = {press = press}
end
local nativeRegister, nativeTool, nativeOpen = system.registerWizardPage, system.registerSystemTool, system.openPage
local nativeCategory, nativeMask, nativeLoadfile = system.registerWizard, lcd.loadMask, loadfile
local descriptors, loads, masks, tools = {}, 0, 0, 0
local tool, lastControllerPath, opened
local register = assert(nativeLoadfile("/register.lua"))()
system.registerWizardPage = nil
register()
system.registerWizardPage = function(value) descriptors[#descriptors + 1] = value end
system.registerSystemTool = function(value) tool = value; tools = tools + 1; return 9 end
system.openPage = function(value) opened = value end
lcd.loadMask = function(path)
    local expected = system.registerWizard and "/icon.png" or "/legacy-icon.png"
    assert(path == "SCRIPTS:/rfsuite" .. expected or path == "SCRIPTS:/rotorflight-model-wizard" .. expected, "Mode-specific absolute icon path")
    masks = masks + 1
    return nativeMask(expected)
end
loadfile = function(path, ...)
    if path == "SCRIPTS:/rfsuite/app/lib/model_wizard.lua"
        or path == "SCRIPTS:/rotorflight-model-wizard/app/lib/model_wizard.lua" then
        loads = loads + 1
        lastControllerPath = path
        return nativeLoadfile("/controller.lua", ...)
    end
    return nativeLoadfile(path, ...)
end
local function allHidden()
    for page = 1, 7 do assert(not descriptors[page].available(), "Normal wizard must hide Rotorflight page " .. page) end
end
local function launch()
    tool.create()
    assert(texts["Requirements:"] and texts["Go back to System, select Sticks, then disable"]
        and texts["First four channels fixed."] and texts["Large + tile > Create model > Other."], "Legacy launch instructions")
    allHidden() -- Opening and cancelling the tool must not arm a session.
    fields["Create Heli FBL Model"].press()
    assert(opened and opened.model == 0, "Tool opens model selection")
    descriptors[1].init() -- Consume activation once when native creation starts.
    assert(descriptors[1].available(), "Explicit launch exposes setup")
    descriptors[1].build()
end
register()
assert(#descriptors == 7 and loads == 0 and masks == 1 and tools == 1, "Lazy legacy registration")
assert(tool.name == "Model Wizard", "Ethos supplies the tile title")
descriptors[1].init()
allHidden()
descriptors[1].build()
assert(loads == 0, "Hidden pages cannot load the controller")
launch()
assert(loads == 1 and lastControllerPath == "SCRIPTS:/rfsuite/app/lib/model_wizard.lua", "Suite absolute path")
assert(not fields["Other model selected"] and not fields["Set up Rotorflight switches"], "No redundant opt-ins")
for page = 2, 7 do assert(descriptors[page].available(), "Explicit setup page available") end
fields["Model type"].set(2)
descriptors[1].init()
allHidden() -- Finishing or cancelling must not activate the next normal wizard.
descriptors[1].build()
assert(loads == 1, "Next normal wizard stays lazy")
launch()
assert(loads == 2 and fields["Model type"].get() == 1, "Explicit relaunch resets selections")
tool.create()
descriptors[1].init()
allHidden() -- Cancelled launcher without a button press does not authorize creation.
descriptors = {}
register("SCRIPTS:/rotorflight-model-wizard")
allHidden()
launch()
assert(loads == 3 and lastControllerPath == "SCRIPTS:/rotorflight-model-wizard/app/lib/model_wizard.lua", "Standalone absolute path")

-- New firmware uses only its own category, never the legacy launcher.
local category
system.registerWizardPage = nil
system.registerWizard = function(name, icon, pages)
    assert(name == "Rotorflight" and icon and #pages == 7, "Category registration")
    category = pages
end
local beforeLoads, beforeMasks, beforeTools = loads, masks, tools
register("SCRIPTS:/rotorflight-model-wizard")
assert(category and loads == beforeLoads and masks == beforeMasks + 1 and tools == beforeTools, "Lazy category without a legacy tool")
for key in pairs(fields) do fields[key] = nil end
category[1].build()
assert(loads == beforeLoads + 1 and category[2].available(), "Selecting category starts setup")
assert(not fields["Other model selected"] and not fields["Set up Rotorflight switches"], "No redundant category opt-ins")
fields["Ignore blackbox"].set(true)
assert(not category[5].available() and category[6].available() and category[7].available(), "Skip blackbox page only")
fields["Ignore rescue"].set(true)
assert(not category[6].available() and category[7].available(), "Skip rescue, retain centralized final run")
assert(category[7].run() == false, "Invalid category draft rejected before creation")
category[1].init()
category[1].build()
assert(category[5].available() and category[6].available() and fields["Model type"].get() == 1, "Category restart resets options")
assert(masks == beforeMasks + 1, "Mask loaded once per registration")
system.registerWizard, lcd.loadMask, loadfile = nativeCategory, nativeMask, nativeLoadfile
system.registerWizardPage, system.registerSystemTool, system.openPage = nativeRegister, nativeTool, nativeOpen

local wizard = assert(loadfile("/controller.lua"))()
local function set(label, value) assert(fields[label], label).set(value) end
local function position(member) return system.getSource({category = CATEGORY_SWITCH_POSITION, member = member}) end
local armChannel, throttleChannel, collectiveChannel = TEST_ELRS and 5 or 6, TEST_ELRS and 6 or 3, TEST_ELRS and 3 or 5
local armLabel = "Armed position (CH" .. armChannel .. ")"
local holdLabel = "Throttle hold (CH" .. throttleChannel .. ")"
local function output(channel) return system.getSource({category = CATEGORY_CHANNEL, member = channel - 1}):value() end
assert(not wizard.available())
wizard.run()
for key in pairs(fields) do fields[key] = nil end
if TEST_CATEGORY then
    wizard.startCategory()
    wizard.build(1)
    assert(wizard.available() and not fields["Other model selected"] and not fields["Set up Rotorflight switches"], "Category starts enabled")
else
    wizard.startLegacy()
    wizard.build(1)
    assert(wizard.available() and not fields["Other model selected"] and not fields["Set up Rotorflight switches"], "Legacy launch starts enabled")
end
assert(wizard.run() == false, "Allocation preparation must be confirmed")
set("First four fixed OFF", true)
assert(fields["Model type"].get() == 1, "FrSky layout by default")
set("Model type", 2)
set("Model type", 1)
set("Model type", TEST_ELRS and 2 or 1)
assert(wizard.run() == false, "Missing switch assignments")
for page = 2, 6 do wizard.build(page) end
set(armLabel, position(0))
set(holdLabel, position(3))
set("Profile 1 (CH7 -100%)", position(6))
set("Profile 2 (CH7 0%)", position(7))
set("Profile 3 (CH7 +100%)", position(8))
for _, item in ipairs({{"Ignore blackbox", "Blackbox active (CH8)"}, {"Ignore rescue", "Rescue active (CH9)"}}) do
    assert(not fields[item[1]].get(), "Optional switch defaults to assigned")
    set(item[1], true)
    if TEST_CATEGORY then
        assert(not wizard.available(item[1] == "Ignore blackbox" and 5 or 6), "Ignored assignment page hidden")
    else
        assert(not fields[item[2]].enabled, "Ignored switch disabled")
    end
    set(item[1], false)
    if TEST_CATEGORY then
        assert(wizard.available(item[1] == "Ignore blackbox" and 5 or 6), "Restored assignment page available")
    else
        assert(fields[item[2]].enabled, "Restored switch enabled")
    end
end
if TEST_IGNORE_BLACKBOX then set("Ignore blackbox", true)
else set("Blackbox active (CH8)", position(9)) end
if TEST_IGNORE_RESCUE then set("Ignore rescue", true)
else set("Rescue active (CH9)", position(12)) end
assert(wizard.run() == false, "Generation requires a completed review")
local function reviewReady(expected)
    for key in pairs(texts) do texts[key] = nil end
    wizard.build(7)
    if TEST_CATEGORY then
        assert(not fields["Click button to create CH1-CH9"], "Category uses native Next/run")
        if not expected then assert(wizard.run() == false, "Incomplete category review cannot create mixes") end
    else
        assert(fields["Click button to create CH1-CH9"].enabled == expected, "Legacy review validity")
    end
end
reviewReady(true)
if TEST_IGNORE_BLACKBOX then
    set("Ignore blackbox", false)
    reviewReady(false)
    assert(wizard.run() == false, "Blackbox required again when restored")
    set("Ignore blackbox", true)
    wizard.build(7)
end
if TEST_IGNORE_RESCUE then
    set("Ignore rescue", false)
    reviewReady(false)
    assert(wizard.run() == false, "Rescue required again when restored")
    set("Rescue active (CH9)", position(0))
    reviewReady(false)
    assert(wizard.run() == false, "Active rescue cannot share arm switch")
    set("Ignore rescue", true)
    reviewReady(true) -- An ignored rescue may retain an unused colliding selection.
    set("Rescue active (CH9)", nil)
end
if not TEST_CATEGORY then assert(wizard.run() == false, "Review must be confirmed") end
set("Profile 2 (CH7 0%)", position(6))
reviewReady(false)
assert(wizard.run() == false, "Duplicated profile position")
set("Profile 2 (CH7 0%)", position(7))
set(holdLabel, position(2))
reviewReady(false)
assert(wizard.run() == false, "Arm and hold must be independent")
set(holdLabel, position(3))
reviewReady(true)
if TEST_CATEGORY then wizard.run() -- Native final-page callback generates all channels.
else set("Click button to create CH1-CH9", true) end -- Legacy Other requires explicit generation.
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
assert(not fields["Model type"].enabled, "Generated layout locked")
set("Model type", TEST_ELRS and 1 or 2)
assert(fields["Model type"].get() == (TEST_ELRS and 2 or 1), "Locked layout rejects mutation")
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
form = {height = function() return 108 end, addLine = line, addStaticText = staticText,
    addSwitchField = field, addBooleanField = field, addChoiceField = function(label, rect, choices, get, set) return field(label, rect, get, set) end}
lcd.getWindowSize = function() return 800, 480 end
wizard.build(1)
assert(fields["Model type"].get() == 1, "Cleanup resets layout")
wizard.build(5)
wizard.build(6)
assert(not fields["Ignore blackbox"].get() and not fields["Ignore rescue"].get(), "Cleanup resets ignore flags")
lcd.getWindowSize = nativeWindowSize
form = nativeForm
print((TEST_CATEGORY and "Category " or "Legacy ") .. (TEST_ELRS and "ELRS " or "FrSky ") .. "PASS: nine exact channels, 48 switch combinations, sticks, save/reload, validation, optional switches and cleanup")
