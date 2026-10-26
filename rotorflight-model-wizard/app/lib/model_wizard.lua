--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

-- Shared controller for the Rotorflight category and older Other-model pages.
local wizard = {}
local enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
local categoryMode = false
local ignored = {}
local positions = {}
local textWidth, textLimit
local elrs = false
local layout = 1
local layoutChoices = {{"FrSky RF", 1}, {"ELRS RF", 2}, {"Heli FBL", 3}}
local fblNames = {"Aileron", "Elevator", "Throttle", "Rudder", "Gyro Gain", "Collective", "Bank/IdleUP", "Rescue"}
local throttleMode = 1
local throttleChoices = {{"FBL gov: CH7 speeds", 1}, {"ESC gov: CH3 speeds", 2}}
local speeds, gains = {0, 0, 0}, {0, 0, 0}
local fblTitles = {[2] = "Create Heli FBL Model", [3] = "Heli FBL: Gyro gain", [4] = "Heli FBL: Bank / IdleUP"}
local fblLabels = {
    [2] = "Throttle hold (CH3)", [3] = "Bank/IdleUP 1 (CH7 -100%)",
    [4] = "Bank/IdleUP 2 (CH7 0%)", [5] = "Bank/IdleUP 3 (CH7 +100%)",
    [7] = "Rescue active (CH8)", [8] = "Gyro position 1 (CH5)",
    [9] = "Gyro position 2 (CH5)", [10] = "Gyro position 3 (CH5)"
}
local channelNames = {
    "Aileron", "Elevator", "RF Throttle", "Rudder", "Pitch",
    "RF Arm", "RF Profile", "RF Blackbox", "RF Rescue"
}
local labels = {
    "Armed position (CH6)", "Throttle hold (CH3)",
    "Profile 1 (CH7 -100%)", "Profile 2 (CH7 0%)", "Profile 3 (CH7 +100%)",
    "Blackbox active (CH8)", "Rescue active (CH9)"
}

local titles = {"Create Heli FBL Model", "Arm", "Throttle hold", "Rates / profile", "Blackbox", "Rescue"}
local reviewLabel = "CH6 Arm / CH3 Hold"
local stickSummary = "CH1 Ail / CH2 Ele / CH4 Rud / CH5 Collective"

local function selectLayout(selection)
    if layout == selection then return end
    if layout == 3 or selection == 3 then
        for key in pairs(positions) do positions[key] = nil end
        for key in pairs(ignored) do ignored[key] = nil end
    end
    layout = selection
    local value = selection == 2
    elrs = value
    local arm, throttle = value and 5 or 6, value and 6 or 3
    labels[1] = "Armed position (CH" .. arm .. ")"
    labels[2] = "Throttle hold (CH" .. throttle .. ")"
    reviewLabel = "CH" .. arm .. " Arm / CH" .. throttle .. " Hold"
    stickSummary = value and "CH1 Ail / CH2 Ele / CH3 Collective / CH4 Rud"
        or "CH1 Ail / CH2 Ele / CH4 Rud / CH5 Collective"
    channelNames[3] = value and "Pitch" or "RF Throttle"
    channelNames[5] = value and "RF Arm" or "Pitch"
    channelNames[6] = value and "RF Throttle" or "RF Arm"
end

local function text(value, topOffset, themeColor, absolute)
    while #value > 0 do
        local count = #value
        if count > textLimit then
            count = textLimit
            local space = value:sub(1, count + 1):match("^.*() ")
            if space and space > 1 then count = space - 1 end
            while count > 0 and count < #value do
                local byte = value:byte(count + 1)
                if byte < 128 or byte >= 192 then break end
                count = count - 1
            end
        end
        local line
        if not absolute then line = form.addLine("", nil, false) end
        local field = form.addStaticText(line,
            {x = 0, y = topOffset or 0, w = textWidth - 16, h = 40},
            count == #value and value or value:sub(1, count))
        if themeColor and field and field.color then field:color(lcd.themeColor(themeColor)) end
        if count == #value then return (topOffset or 0) + 40 end
        if absolute then topOffset = (topOffset or 0) + 40 end
        value = value:sub(count + 1):gsub("^ +", "")
    end
end

local function coloredLine(label, themeColor)
    local line = form.addLine("")
    local labelField = form.addStaticText(line,
        {x = 0, y = 8, w = textWidth - 180, h = 40}, label)
    if labelField and labelField.color then labelField:color(lcd.themeColor(themeColor)) end
    return line
end

local function switchField(index, line, rect)
    local field = form.addSwitchField(line or form.addLine(layout == 3 and fblLabels[index] or labels[index]), rect,
        function() return positions[index] end,
        function(value)
            if attempted then return end
            positions[index] = value; reviewed = false
        end)
    field:enable(not attempted and not ignored[index])
    return field
end

local function optionalSwitch(index, label, optionOnly)
    local assignment
    local field = form.addBooleanField(form.addLine(label), nil,
        function() return ignored[index] == true end,
        function(value)
            if attempted then return end
            ignored[index] = value
            reviewed = false
            if assignment then assignment:enable(not value) end
        end)
    field:enable(not attempted)
    if not optionOnly then assignment = switchField(index) end
end

local function positionName(index)
    if ignored[index] then return "Ignored" end
    local source = positions[index]
    return source and source:name() or "---"
end

local function reviewSummary(rows)
    -- Parent these fields directly to the form. A FormLine clips its children
    -- to one native row, even when a child rectangle extends below that row.
    local y = form.height() + 2
    local split = math.floor(textWidth * 0.5)
    for _, row in ipairs(rows) do
        if row[2] then
            form.addStaticText(nil, {x = 0, y = y, w = split - 8, h = 32}, row[1])
            form.addStaticText(nil, {x = split, y = y, w = textWidth - split - 16, h = 32}, row[2])
            y = y + 36
        else
            y = text(row[1], y, nil, true)
        end
    end
end

local function physicalSwitch(source)
    return math.floor(source:member() / 3)
end

local function validTriplet(first)
    local a, b, c = positions[first], positions[first + 1], positions[first + 2]
    if not a or not b or not c then return false end
    return physicalSwitch(a) == physicalSwitch(b) and physicalSwitch(a) == physicalSwitch(c)
        and a:member() ~= b:member() and a:member() ~= c:member() and b:member() ~= c:member()
end

local function physicalPosition(index)
    local source = positions[index]
    return source and source:category() == CATEGORY_SWITCH_POSITION and source:options() == 0
end

local function validAssignments()
    if not allocationConfirmed then return false end
    if layout == 3 then
        for i = 2, 10 do
            local needed = i == 2 or i >= 3 and i <= 5 or i == 7 and not ignored[7]
                or i >= 8
            if needed and not physicalPosition(i) then return false end
        end
        if not validTriplet(3) or not validTriplet(8) then return false end
        local hold = physicalSwitch(positions[2])
        if hold == physicalSwitch(positions[3]) or hold == physicalSwitch(positions[8]) then return false end
        if not ignored[7] then
            local rescue = physicalSwitch(positions[7])
            if rescue == hold or rescue == physicalSwitch(positions[3]) or rescue == physicalSwitch(positions[8]) then return false end
        end
        return throttleMode == 1 or type(model.createLogicSwitch) == "function"
    end
    for i = 1, #labels do
        local source = positions[i]
        if not ignored[i] and (not source or source:category() ~= CATEGORY_SWITCH_POSITION or source:options() ~= 0) then
            return false
        end
    end
    local a, b, c = positions[3]:member(), positions[4]:member(), positions[5]:member()
    local profileSwitch = math.floor(a / 3)
    if profileSwitch ~= math.floor(b / 3) or profileSwitch ~= math.floor(c / 3)
        or a == b or a == c or b == c then
        return false
    end
    local arm, hold = physicalSwitch(positions[1]), physicalSwitch(positions[2])
    if arm == hold then return false end
    if not ignored[7] then
        local rescue = physicalSwitch(positions[7])
        if rescue == arm or rescue == hold then return false end
    end
    return true
end

function wizard.close()
    for key in pairs(positions) do positions[key] = nil end
    for key in pairs(ignored) do ignored[key] = nil end
    enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
    categoryMode = false
    throttleMode = 1
    for i = 1, 3 do speeds[i], gains[i] = 0, 0 end
    textWidth, textLimit = nil, nil
    selectLayout(1)
end

function wizard.startLegacy()
    wizard.close()
    enabled = true
end

function wizard.startCategory()
    wizard.startLegacy()
    categoryMode = true
end

function wizard.available(page)
    if not enabled then return false end
    if layout == 3 then return page ~= 5 and page ~= 6 end
    if categoryMode then
        if page == 5 then return not ignored[6] end
        if page == 6 then return not ignored[7] end
    end
    return true
end

local function valueSwitch(index, values, item, minimum)
    local line = form.addLine(fblLabels[index])
    local split = math.floor(textWidth * 0.52)
    local valueWidth = math.min(124, math.floor(textWidth * 0.2))
    switchField(index, line, {x = split, y = 0, w = textWidth - split - valueWidth - 24, h = 40})
    local field = form.addNumberField(line, {x = textWidth - valueWidth - 8, y = 0, w = valueWidth, h = 40}, minimum, 100,
        function() return values[item] end,
        function(value)
            if attempted then return end
            values[item] = value; reviewed = false
        end)
    field:suffix("%")
    field:enable(not attempted)
end

local function valuesText(values)
    return values[1] .. "/" .. values[2] .. "/" .. values[3] .. "%"
end

local function positionsText(first)
    return positionName(first) .. "/" .. positionName(first + 1) .. "/" .. positionName(first + 2)
end

function wizard.build(page)
    local width = lcd.getWindowSize()
    if width ~= textWidth then
        textWidth, textLimit = width, math.max(16, math.floor((width - 16) / 14))
    end
    local title = page == 7 and (layout == 3 and "Heli FBL review" or elrs and "Rotorflight review: ELRS" or "Rotorflight review: FrSky")
        or layout == 3 and fblTitles[page] or titles[page]
    if layout == 3 and page == 4 and throttleMode == 2 then title = "ESC gov CH3 / Bank/IdleUP CH7" end
    if page == 1 then
        -- Wrapped instructions share a compact text block instead of taking
        -- a full native form row for every line. Reserve its height before
        -- adding controls so the fields cannot overlap the instructions.
        local y = text(categoryMode and "Requirements:" or title, 4,
            categoryMode and THEME_ERROR_COLOR or nil, true)
        if categoryMode then
            y = text("Go back to System, select Sticks, then disable First four channels fixed.", y,
                THEME_WARNING_COLOR, true)
        end
        y = text("Click the button below to confirm you disabled first four channels", y + 6,
            THEME_WARNING_COLOR, true)
        local before = form.height()
        -- Absolute text already contributes to the native form height on
        -- current Ethos. Only reserve rows if that height is still too short.
        if before < y then
            form.addLine("", nil, false)
            local rowHeight = form.height() - before
            if rowHeight > 0 then
                for i = 1, math.ceil((y - form.height()) / rowHeight) do
                    form.addLine("", nil, false)
                end
            end
        end
    else
        text(title, 12, page > 1 and page < 7 and THEME_WARNING_COLOR or nil)
    end
    if page > 1 and page < 7 then
        text("Click box and flip desired switch and switch direction.")
    end
    if page == 1 then
        local field
        field = form.addBooleanField(form.addLine("First four fixed OFF"), nil,
            function() return allocationConfirmed end,
            function(value)
                if attempted then return end
                allocationConfirmed = value; reviewed = false
            end)
        field:enable(not attempted)
        field = form.addChoiceField(form.addLine("Model type"), nil, layoutChoices,
            function() return layout end,
            function(value)
                if attempted then return end
                selectLayout(value)
                reviewed = false
            end)
        field:enable(not attempted)
        if categoryMode and layout ~= 3 then
            optionalSwitch(6, "Ignore blackbox", true)
            optionalSwitch(7, "Ignore rescue", true)
        end
    elseif layout == 3 and page < 7 then
        if page == 2 then
            local field = form.addChoiceField(form.addLine("Governor type"), nil, throttleChoices,
                function() return throttleMode end,
                function(value)
                    if attempted then return end
                    throttleMode = value; reviewed = false
                end)
            field:enable(not attempted)
            switchField(2)
            optionalSwitch(7, "Ignore rescue")
        elseif page == 3 then
            for i = 1, 3 do valueSwitch(i + 7, gains, i, -100) end
        elseif page == 4 then
            for i = 3, 5 do
                if throttleMode == 2 then valueSwitch(i, speeds, i - 2, 0)
                else switchField(i) end
            end
        end
    elseif page == 2 then
        switchField(1)
    elseif page == 3 then
        switchField(2)
    elseif page == 4 then
        for i = 3, 5 do switchField(i) end
    elseif page == 5 then
        if categoryMode then switchField(6) else optionalSwitch(6, "Ignore blackbox") end
    elseif page == 6 then
        if categoryMode then switchField(7) else optionalSwitch(7, "Ignore rescue") end
    elseif page == 7 then
        local ready = validAssignments()
        if not attempted then
            local field
            field = form.addBooleanField(coloredLine(layout == 3 and "Click button to create CH1-CH8" or "Click button to create CH1-CH9", THEME_ERROR_COLOR), nil,
                function() return reviewed end,
                function(value)
                    if not value or attempted then return end
                    reviewed = true
                    -- Create explicitly in both firmware paths; do not depend
                    -- on the Other-model wizard dispatching a run callback.
                    wizard.run()
                    field:enable(false)
                end)
            field:enable(ready)
        end
        if layout == 3 then
            reviewSummary({
                {"CH1 Ail / CH2 Ele / CH4 Rud / CH6 Collective"},
                {"CH3 " .. (throttleMode == 1 and "FBL gov On" or "ESC gov: " .. valuesText(speeds)) .. " / Hold " .. positionName(2)},
                {"CH5 Gyro: " .. valuesText(gains) .. " / " .. positionsText(8)},
                {"CH7 Bank/IdleUP / CH8 Rescue", positionsText(3) .. " / " .. positionName(7)}
            })
            return
        end
        reviewSummary({
            {stickSummary},
            {reviewLabel, positionName(1) .. " / " .. positionName(2)},
            {"CH7 Rates / Profile", positionName(3) .. " / " .. positionName(4) .. " / " .. positionName(5)},
            {"CH8 Blackbox / CH9 Rescue", positionName(6) .. " / " .. positionName(7)}
        })
    end
end

local function addMix(index, spec)
    spec.name = layout == 3 and fblNames[index] or channelNames[index]
    model.createMix("free", spec)
    -- Native wizard output allocation is deferred until the model is saved.
    -- getChannel() here reads the active model, not the draft being built.
end

local function stick(index, member)
    addMix(index, {input = {category = CATEGORY_ANALOG, member = member}})
end

local function binary(index, source, active, inactive)
    addMix(index, {actions = {{action = "offset", condition = source, active = active, inactive = inactive}}})
end

local function selector(index, first, values)
    addMix(index, {actions = {
        {action = "offset", condition = positions[first], active = values[1], inactive = 0},
        {action = "offset", condition = positions[first + 1], active = values[2], inactive = 0},
        {action = "offset", condition = positions[first + 2], active = values[3], inactive = 0}
    }})
end

local bankValues = {-100, 0, 100}
local function fblThrottle()
    if throttleMode == 1 then
        -- The FBL selects its three speeds from CH7. CH3 is only run / hold.
        binary(3, positions[2], -100, 100)
        return
    end
    -- Native logical gates enforce hold independently of every governor position.
    -- These persist in the new model; no Lua wakeup task is needed after creation.
    local run = model.createLogicSwitch()
    run:name("FBL Run"); run:func(LOGIC_SWITCH_FUNCTION_OR)
    run:values({positions[2]}); run:negative(true)
    -- Other starts with no logic switches. Use draft slot descriptors: name
    -- lookup reads the active model and cannot resolve newly created switches.
    local runSource = {category = CATEGORY_LOGIC_SWITCH, member = 0}
    local actions = {{action = "offset", active = -100, inactive = -100}}
    for i = 1, 3 do
        local name = "FBL Gov " .. i
        local gate = model.createLogicSwitch()
        gate:name(name); gate:func(LOGIC_SWITCH_FUNCTION_AND)
        gate:values({runSource, positions[i + 2]})
        actions[#actions + 1] = {action = "offset", condition = {category = CATEGORY_LOGIC_SWITCH, member = i},
            active = speeds[i] * 2, inactive = 0}
    end
    addMix(3, {actions = actions})
end

function wizard.run()
    if not enabled or attempted or not reviewed or not validAssignments() then return false end
    -- Free mixes are allocated in sequence; the API has no output-edit method.
    -- Require the Other / first-four-fixed-OFF preparation, then create the
    -- entire map in order. Never retry a failed/partial generation.
    attempted = true
    stick(1, ANALOG_STICK_AILERON)
    stick(2, ANALOG_STICK_ELEVATOR)
    if layout == 3 then
        fblThrottle()
        stick(4, ANALOG_STICK_RUDDER)
        selector(5, 8, gains)
        stick(6, ANALOG_STICK_THROTTLE)
        selector(7, 3, bankValues)
        binary(8, ignored[7] and nil or positions[7], ignored[7] and -100 or 100, -100)
        return true
    end
    -- Sequential free-mix allocation determines channel numbers.
    if elrs then stick(3, ANALOG_STICK_THROTTLE) else binary(3, positions[2], -100, 100) end
    stick(4, ANALOG_STICK_RUDDER)
    if elrs then
        binary(5, positions[1], 100, -100) -- ELRS AUX1 arm, low when disarmed.
        binary(6, positions[2], -100, 100) -- FC governor command.
    else
        stick(5, ANALOG_STICK_THROTTLE) -- Collective, independent of throttle hold.
        binary(6, positions[1], 100, -100)
    end
    addMix(7, {actions = {
        {action = "offset", condition = positions[3], active = -100, inactive = 0},
        {action = "offset", condition = positions[4], active = 0, inactive = 0},
        {action = "offset", condition = positions[5], active = 100, inactive = 0}
    }})
    -- Retain both slots when ignored so later channel numbers cannot shift.
    for index = 6, 7 do
        if ignored[index] then
            binary(index + 2, nil, -100, -100)
        else
            binary(index + 2, positions[index], 100, -100)
        end
    end
    return true
end

return wizard
