-- Host Lua regression: run from repository root. Firmware APIs are mocked;
-- native draft persistence still needs a simulator/radio creation check.
local controller = "rotorflight-model-wizard/app/lib/model_wizard.lua"
THEME_WARNING_COLOR, THEME_ERROR_COLOR = 10, 20
THEME_PAGE_BGCOLOR, THEME_DEFAULT_COLOR, FONT_BOLD = 30, 40, 50
CATEGORY_SWITCH_POSITION, CATEGORY_ANALOG, CATEGORY_LOGIC_SWITCH = 1, 2, 3
ANALOG_STICK_AILERON, ANALOG_STICK_ELEVATOR = 0, 1
ANALOG_STICK_RUDDER, ANALOG_STICK_THROTTLE = 2, 3
LOGIC_SWITCH_FUNCTION_OR, LOGIC_SWITCH_FUNCTION_AND = 1, 2
local cases = 0
for _, category in ipairs({false, true}) do
    for layout = 1, 3 do
        for variant = 0, 3 do
            local fields, texts, mixes, logic = {}, {}, {}, 0
            local function field(line, rect, get, set)
                local f = {get = get, set = set, suffix = function() end}
                function f:enable(value) self.enabled = value end
                fields[line.label] = f
                return f
            end
            form = {
                height = function() return 108 end,
                addLine = function(label) return {label = label} end,
                addStaticText = function(line, rect, value)
                    local f = {}
                    function f:color(color) self.textColor = color end
                    if line and rect.x == 0 then line.label = value end
                    texts[value] = f
                    return f
                end,
                addSwitchField = field, addBooleanField = field,
                addChoiceField = function(line, rect, choices, get, set) return field(line or {label = "Model type"}, rect, get, set) end,
                addNumberField = function(line, rect, low, high, get, set)
                    return field({label = line.label .. " value"}, rect, get, set)
                end
            }
            lcd = {getWindowSize = function() return 800, 480 end, themeColor = function(c) return c end}
            local drawColor, drawFont = 0, 0
            lcd.color = function(value) if value then drawColor = value end; return drawColor end
            lcd.font = function(value) if value then drawFont = value end; return drawFont end
            lcd.getTextSize = function(value) return #value * 12, 24 end
            lcd.drawFilledRectangle = function(x, y, width, height)
                assert(x + width <= 784, "Title background must leave the native scrollbar clear")
                assert(height >= 0, "Title background height")
            end
            lcd.drawText = function(x, y, value)
                assert(drawFont == FONT_BOLD, "Page headings use bold font")
                texts[value] = {textColor = drawColor}
            end
            model = {
                createMix = function(kind, spec) assert(kind == "free"); mixes[#mixes + 1] = spec end,
                createLogicSwitch = function()
                    logic = logic + 1
                    return {name = function() end, func = function() end, values = function() end, negative = function() end}
                end
            }
            local function set(label, value) assert(fields[label], label).set(value) end
            local function position(member)
                return {member = function() return member end, category = function() return CATEGORY_SWITCH_POSITION end,
                    options = function() return 0 end, name = function() return "S" .. member end}
            end
            local wizard = assert(loadfile(controller))()
            if category then wizard.startCategory() else wizard.startLegacy() end
            wizard.build(1)
            wizard.paintTitle()
            if category then assert(texts["Requirements:"].textColor == THEME_ERROR_COLOR) end
            local confirmationFound = false
            for value, f in pairs(texts) do
                if value:find("Click the button below", 1, true) then
                    assert(f.textColor == THEME_WARNING_COLOR)
                    confirmationFound = true
                end
            end
            assert(confirmationFound, "Warning-colored first-four confirmation")
            set("First four fixed OFF", true)
            set("Model type", layout)
            wizard.build(7)
            local createLabel = "Click button to create CH1-CH" .. (layout == 3 and "8" or "9")
            assert(not fields[createLabel].enabled, "Incomplete input disables creation")
            assert(not wizard.run() and #mixes == 0, "Native Next cannot create an unconfirmed draft")
            if layout < 3 then
                local arm, hold = layout == 2 and 5 or 6, layout == 2 and 6 or 3
                wizard.build(2); set("Armed position (CH" .. arm .. ")", position(0))
                wizard.paintTitle()
                assert(texts.Arm.textColor == THEME_WARNING_COLOR)
                wizard.build(3); set("Throttle hold (CH" .. hold .. ")", position(3))
                wizard.build(4)
                for i, suffix in ipairs({"-100%", "0%", "+100%"}) do
                    set("Profile " .. i .. " (CH7 " .. suffix .. ")", position(i + 5))
                end
                wizard.build(5); wizard.build(6)
                set("Ignore blackbox", variant % 2 == 1)
                set("Ignore rescue", variant >= 2)
                set("Blackbox active (CH8)", position(9))
                set("Rescue active (CH9)", position(12))
            else
                wizard.build(2)
                set("Governor type", variant % 2 + 1)
                set("Throttle hold (CH3)", position(0))
                set("Ignore rescue", variant >= 2)
                set("Rescue active (CH8)", position(12))
                wizard.build(3)
                for i = 1, 3 do set("Gyro position " .. i .. " (CH5)", position(i + 5)) end
                wizard.build(4)
                for i, suffix in ipairs({"-100%", "0%", "+100%"}) do
                    set("Bank/IdleUP " .. i .. " (CH7 " .. suffix .. ")", position(i + 8))
                end
            end
            wizard.build(7)
            assert(fields[createLabel].enabled, "Complete input enables explicit creation")
            assert(texts[createLabel].textColor == THEME_ERROR_COLOR)
            assert(not wizard.run() and #mixes == 0, "Review still needs explicit confirmation")
            set(createLabel, true)
            local expected = layout == 3 and 8 or 9
            assert(#mixes == expected and mixes[1].name == "Aileron" and mixes[4].name == "Rudder")
            assert(mixes[expected].name == (layout == 3 and "Rescue" or "RF Rescue"))
            assert(logic == (layout == 3 and variant % 2 == 1 and 4 or 0))
            assert(not fields[createLabel].enabled)
            wizard.run(); set(createLabel, true); wizard.build(7)
            assert(#mixes == expected, "Late native callbacks and repeated clicks cannot duplicate mixes")
            cases = cases + 1
        end
    end
end
print("PASS: " .. cases .. " legacy/category creation cases, validation, colors, and duplicate prevention")
