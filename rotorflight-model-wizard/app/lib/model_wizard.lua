--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

-- Native NEW-model wizard pages. Other avoids Ethos's stock helicopter mixes.
local wizard = {}
local enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
local otherConfirmed = false
local positions = {}
local channelNames = {"Aileron", "Elevator", "RF Throttle", "Rudder", "Pitch", "RF Arm", "RF Profile", "RF Blackbox", "RF Rescue"}
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

local function switchField(index)
    local field = form.addSwitchField(form.addLine(labels[index]), nil,
        function() return positions[index] end,
        function(value) positions[index] = value; reviewed = false end)
    field:enable(not attempted)
end

local function positionName(index)
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
    if not otherConfirmed then return "Restart model creation and select Other, then confirm the model type." end
    if not allocationConfirmed then return "Confirm First four channels fixed is OFF in System > Sticks." end
    for i = 1, #labels do
        local source = positions[i]
        if not source or source:category() ~= CATEGORY_SWITCH_POSITION or source:options() ~= 0 then
            return "Select a physical switch position:" .. " " .. labels[i]
        end
    end
    local a, b, c = positions[3], positions[4], positions[5]
    if physicalSwitch(a) ~= physicalSwitch(b) or physicalSwitch(a) ~= physicalSwitch(c)
        or a:member() == b:member() or a:member() == c:member() or b:member() == c:member() then
        return "Use all three positions of one switch for each selector."
    end
    if physicalSwitch(positions[1]) == physicalSwitch(positions[2])
        or physicalSwitch(positions[1]) == physicalSwitch(positions[7])
        or physicalSwitch(positions[2]) == physicalSwitch(positions[7]) then
        return "Arm, hold and rescue need separate switches."
    end
end

function wizard.close()
    for key in pairs(positions) do positions[key] = nil end
    enabled, reviewed, attempted, allocationConfirmed = false, false, false, false
    otherConfirmed = false
end

function wizard.available()
    return enabled
end

function wizard.build(page)
    text("Rotorflight switch setup")
    if attempted then text("Draft locked; restart creation to edit.") end
    if page == 1 then
        text("Choose Other for the Rotorflight channel map.")
        text("System > Sticks: First four channels fixed OFF.")
        local field = form.addBooleanField(form.addLine("Other model selected"), nil,
            function() return otherConfirmed end,
            function(value) otherConfirmed = value; reviewed = false end)
        field:enable(not attempted)
        field = form.addBooleanField(form.addLine("First four fixed OFF"), nil,
            function() return allocationConfirmed end,
            function(value) allocationConfirmed = value; reviewed = false end)
        field:enable(not attempted)
        field = form.addBooleanField(form.addLine("Set up Rotorflight switches"), nil,
            function() return enabled end,
            function(value) enabled = value; reviewed = false end)
        field:enable(not attempted)
    elseif page == 2 then
        switchField(1)
    elseif page == 3 then
        text("CH3: hold -100%, released +100% (FC governor).")
        switchField(2)
    elseif page == 4 then
        text("CH7 selects both rates and profile: -100%, 0%, +100%.")
        for i = 3, 5 do switchField(i) end
    elseif page == 5 then
        switchField(6)
    elseif page == 6 then
        switchField(7)
    elseif page == 7 then
        text("CH1 Ail / CH2 Ele / CH4 Rud / CH5 Collective")
        reviewRow("CH6 Arm / CH3 Hold", positionName(1) .. " / " .. positionName(2))
        reviewRow("CH7 Rates / Profile", positionName(3) .. " / " .. positionName(4) .. " / " .. positionName(5))
        reviewRow("CH8 Blackbox / CH9 Rescue", positionName(6) .. " / " .. positionName(7))
        local problem = validate()
        if problem then text(problem) end
        if attempted then return end
        local field
        field = form.addBooleanField(form.addLine("Create reviewed CH1-CH9"), nil,
            function() return reviewed end,
            function(value)
                if not value or attempted then return end
                reviewed = true
                -- Other omits Ethos's channel-review page and its run callback.
                -- This explicit confirmation must generate the draft itself.
                wizard.run()
                field:enable(false)
            end)
        field:enable(problem == nil and not attempted)
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
    if not enabled or attempted then return end
    local problem = validate()
    if problem then error(problem) end
    if not reviewed then error("Review the Rotorflight switch assignments before finishing.") end
    -- Free mixes are allocated in sequence; the API has no output-edit method.
    -- Require the Other / first-four-fixed-OFF preparation, then create the
    -- entire map in order. Never retry a failed/partial generation.
    attempted = true
    stick(1, 3) -- Aileron
    stick(2, 1) -- Elevator
    binary(3, positions[2], -100, 100)
    stick(4, 0) -- Rudder
    stick(5, 2) -- Collective, independent of the governor command on CH3.
    binary(6, positions[1], 100, -100)
    addMix(7, {actions = {
        {action = "offset", condition = positions[3], active = -100, inactive = 0},
        {action = "offset", condition = positions[4], active = 0, inactive = 0},
        {action = "offset", condition = positions[5], active = 100, inactive = 0}
    }})
    binary(8, positions[6], 100, -100)
    binary(9, positions[7], 100, -100)
end

return wizard
