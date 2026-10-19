--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

-- Native NEW-model wizard pages. Other avoids Ethos's stock helicopter mixes.
local wizard = {}
local enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
local otherConfirmed = false
local categoryMode = false
local ignored = {}
local positions = {}
local layouts = {
    standard = {
        names = {"Aileron", "Elevator", "RF Throttle", "Rudder", "Pitch", "RF Arm", "RF Profile", "RF Blackbox", "RF Rescue"},
        arm = 6, throttle = 3, collective = 5
    },
    elrs = {
        names = {"Aileron", "Elevator", "Pitch", "Rudder", "RF Arm", "RF Throttle", "RF Profile", "RF Blackbox", "RF Rescue"},
        arm = 5, throttle = 6, collective = 3
    }
}
local layout = layouts.standard
local labels = {
    "Armed position (CH6)", "Throttle hold (CH3)",
    "Profile 1 (CH7 -100%)", "Profile 2 (CH7 0%)", "Profile 3 (CH7 +100%)",
    "Blackbox active (CH8)", "Rescue active (CH9)"
}

local function text(value)
    local width = lcd.getWindowSize()
    local limit = math.max(16, math.floor((width - 16) / 14))
    while #value > 0 do
        local count = math.min(#value, limit)
        if count < #value then
            local space = value:sub(1, count + 1):match("^.*() ")
            if space and space > 1 then count = space - 1 end
            while count > 0 and count < #value do
                local byte = value:byte(count + 1)
                if byte < 128 or byte >= 192 then break end
                count = count - 1
            end
        end
        form.addStaticText(form.addLine("", nil, false),
            {x = 0, y = 0, w = width - 16, h = 40}, value:sub(1, count))
        value = value:sub(count + 1):gsub("^ +", "")
    end
end

local function switchLabel(index)
    if index == 1 then return "Armed position (CH" .. layout.arm .. ")" end
    if index == 2 then return "Throttle hold (CH" .. layout.throttle .. ")" end
    return labels[index]
end

local function switchField(index)
    local field = form.addSwitchField(form.addLine(switchLabel(index)), nil,
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
    if not optionOnly then
        text("Ignore keeps this channel inactive at -100%.")
        assignment = switchField(index)
    end
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

local function validate()
    if not otherConfirmed then return "Restart creation: select Other, then confirm it." end
    if not allocationConfirmed then return "System > Sticks: confirm First four fixed OFF." end
    for i = 1, #labels do
        local source = positions[i]
        if not ignored[i] and (not source or source:category() ~= CATEGORY_SWITCH_POSITION or source:options() ~= 0) then
            return "Select a physical switch position:" .. " " .. switchLabel(i)
        end
    end
    local a, b, c = positions[3], positions[4], positions[5]
    if physicalSwitch(a) ~= physicalSwitch(b) or physicalSwitch(a) ~= physicalSwitch(c)
        or a:member() == b:member() or a:member() == c:member() or b:member() == c:member() then
        return "Use all three positions of one switch for each selector."
    end
    if physicalSwitch(positions[1]) == physicalSwitch(positions[2])
        or (not ignored[7] and (physicalSwitch(positions[1]) == physicalSwitch(positions[7])
            or physicalSwitch(positions[2]) == physicalSwitch(positions[7]))) then
        return "Arm, hold and rescue need separate switches."
    end
end

function wizard.close()
    for key in pairs(positions) do positions[key] = nil end
    for key in pairs(ignored) do ignored[key] = nil end
    enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
    otherConfirmed, categoryMode = false, false
    layout = layouts.standard
end

function wizard.startCategory()
    wizard.close()
    categoryMode, enabled, otherConfirmed = true, true, true
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
    text(page == 7 and (layout == layouts.elrs and "Rotorflight review: ELRS" or "Rotorflight review: Standard") or "Rotorflight switch setup")
    if attempted then text("Draft locked; restart creation to edit.") end
    if page == 1 then
        text("System > Sticks: First four channels fixed OFF.")
        local field
        if not categoryMode then
            field = form.addBooleanField(form.addLine("Other model selected"), nil,
                function() return otherConfirmed end,
                function(value)
                    if attempted then return end
                    otherConfirmed = value; reviewed = false
                end)
            field:enable(not attempted)
        end
        field = form.addBooleanField(form.addLine("First four fixed OFF"), nil,
            function() return allocationConfirmed end,
            function(value)
                if attempted then return end
                allocationConfirmed = value; reviewed = false
            end)
        field:enable(not attempted)
        if not categoryMode then
            field = form.addBooleanField(form.addLine("Set up Rotorflight switches"), nil,
                function() return enabled end,
                function(value)
                    if attempted then return end
                    enabled = value
                    if not value then layout = layouts.standard end
                    reviewed = false
                end)
            field:enable(not attempted)
        end
        field = form.addBooleanField(form.addLine("Use ELRS channel order"), nil,
            function() return layout == layouts.elrs end,
            function(value)
                if attempted then return end
                layout = value and layouts.elrs or layouts.standard
                -- Selecting an ELRS model also opts into its setup pages.
                if value then enabled = true end
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
        text("CH" .. layout.throttle .. ": hold -100%, released +100% (FC governor).")
        switchField(2)
    elseif page == 4 then
        text("CH7 selects both rates and profile: -100%, 0%, +100%.")
        for i = 3, 5 do switchField(i) end
    elseif page == 5 then
        if categoryMode then switchField(6) else optionalSwitch(6, "Ignore blackbox") end
    elseif page == 6 then
        if categoryMode then switchField(7) else optionalSwitch(7, "Ignore rescue") end
    elseif page == 7 then
        local problem = validate()
        -- Keep the confirmation above the summary and any validation message.
        -- Missing assignments must never push it beneath native navigation.
        if categoryMode then
            if not attempted then reviewed = problem == nil end
            text(problem and "Complete required assignments before Next." or "Next creates reviewed CH1-CH9.")
        elseif not attempted then
            local field
            field = form.addBooleanField(form.addLine("Create reviewed CH1-CH9"), nil,
                function() return reviewed end,
                function(value)
                    if not value or attempted then return end
                    reviewed = true
                    -- Other omits Ethos's channel-review run callback.
                    wizard.run()
                    field:enable(false)
                end)
            field:enable(problem == nil)
        end
        if problem then
            text(problem)
        else
            text("CH1 Ail / CH2 Ele / CH4 Rud / CH" .. layout.collective .. " Collective")
        end
        reviewRow("CH" .. layout.arm .. " Arm / CH" .. layout.throttle .. " Hold", positionName(1) .. " / " .. positionName(2))
        reviewRow("CH7 Rates / Profile", positionName(3) .. " / " .. positionName(4) .. " / " .. positionName(5))
        reviewRow("CH8 Blackbox / CH9 Rescue", positionName(6) .. " / " .. positionName(7))
    end
end

local function addMix(index, spec)
    spec.name = layout.names[index]
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
    if not enabled or attempted then return end
    local problem = validate()
    if problem then error(problem) end
    if not reviewed then error("Review the Rotorflight switch assignments before finishing.") end
    -- Free mixes are allocated in sequence; the API has no output-edit method.
    -- Require the Other / first-four-fixed-OFF preparation, then create the
    -- entire map in order. Never retry a failed/partial generation.
    attempted = true
    stick(1, ANALOG_STICK_AILERON) -- Aileron
    stick(2, ANALOG_STICK_ELEVATOR) -- Elevator
    -- Sequential free-mix allocation determines channel numbers.
    if layout == layouts.elrs then stick(3, ANALOG_STICK_THROTTLE) else binary(3, positions[2], -100, 100) end
    stick(4, ANALOG_STICK_RUDDER) -- Rudder
    if layout == layouts.elrs then
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
end

return wizard
