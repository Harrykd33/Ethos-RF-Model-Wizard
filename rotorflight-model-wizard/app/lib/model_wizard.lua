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
local channelNames = {
    "Aileron", "Elevator", "RF Throttle", "Rudder", "Pitch",
    "RF Arm", "RF Profile", "RF Blackbox", "RF Rescue"
}
local labels = {
    "Armed position (CH6)", "Throttle hold (CH3)",
    "Profile 1 (CH7 -100%)", "Profile 2 (CH7 0%)", "Profile 3 (CH7 +100%)",
    "Blackbox active (CH8)", "Rescue active (CH9)"
}

local titles = {"Rotorflight switch setup (Requirements)", "Arm", "Throttle hold", "Rates / profile", "Blackbox", "Rescue"}
local reviewLabel = "CH6 Arm / CH3 Hold"
local stickSummary = "CH1 Ail / CH2 Ele / CH4 Rud / CH5 Collective"

local function selectLayout(value)
    if elrs == value then return end
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

local function text(value, topOffset)
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
        form.addStaticText(form.addLine("", nil, false),
            {x = 0, y = topOffset or 0, w = textWidth - 16, h = 40},
            count == #value and value or value:sub(1, count))
        if count == #value then return end
        value = value:sub(count + 1):gsub("^ +", "")
    end
end

local function switchField(index)
    local field = form.addSwitchField(form.addLine(labels[index]), nil,
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

local function reviewRow(label, value)
    form.addStaticText(form.addLine(label, nil, false), nil, value)
end

local function physicalSwitch(source)
    return math.floor(source:member() / 3)
end

local function validAssignments()
    if not allocationConfirmed then return false end
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
    textWidth, textLimit = nil, nil
    selectLayout(false)
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
    if categoryMode then
        if page == 5 then return not ignored[6] end
        if page == 6 then return not ignored[7] end
    end
    return true
end

function wizard.build(page)
    local width = lcd.getWindowSize()
    if width ~= textWidth then
        textWidth, textLimit = width, math.max(16, math.floor((width - 16) / 14))
    end
    text(page == 7 and (elrs and "Rotorflight review: ELRS" or "Rotorflight review: FrSky") or titles[page], 12)
    if page > 1 and page < 7 then
        text("Click box and flip desired switch and switch direction.")
    end
    if page == 1 then
        text("System > Sticks: First four channels fixed OFF.")
        local field
        field = form.addBooleanField(form.addLine("First four fixed OFF"), nil,
            function() return allocationConfirmed end,
            function(value)
                if attempted then return end
                allocationConfirmed = value; reviewed = false
            end)
        field:enable(not attempted)
        field = form.addBooleanField(form.addLine("Use ELRS channel order"), nil,
            function() return elrs end,
            function(value)
                if attempted then return end
                selectLayout(value)
                reviewed = false
            end)
        field:enable(not attempted)
        if categoryMode then
            optionalSwitch(6, "Ignore blackbox", true)
            optionalSwitch(7, "Ignore rescue", true)
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
        if categoryMode then
            if not attempted then reviewed = ready end
        elseif not attempted then
            local field
            field = form.addBooleanField(form.addLine("Create CH1-CH9"), nil,
                function() return reviewed end,
                function(value)
                    if not value or attempted then return end
                    reviewed = true
                    -- Other omits Ethos's channel-review run callback.
                    wizard.run()
                    field:enable(false)
                end)
            field:enable(ready)
        end
        text(stickSummary)
        reviewRow(reviewLabel, positionName(1) .. " / " .. positionName(2))
        reviewRow("CH7 Rates / Profile", positionName(3) .. " / " .. positionName(4) .. " / " .. positionName(5))
        reviewRow("CH8 Blackbox / CH9 Rescue", positionName(6) .. " / " .. positionName(7))
    end
end

local function addMix(index, spec)
    spec.name = channelNames[index]
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

function wizard.run()
    if not enabled or attempted or not reviewed or not validAssignments() then return false end
    -- Free mixes are allocated in sequence; the API has no output-edit method.
    -- Require the Other / first-four-fixed-OFF preparation, then create the
    -- entire map in order. Never retry a failed/partial generation.
    attempted = true
    stick(1, ANALOG_STICK_AILERON)
    stick(2, ANALOG_STICK_ELEVATOR)
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
