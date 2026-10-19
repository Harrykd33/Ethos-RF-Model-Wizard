--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

-- Keep the form implementation out of memory until model creation uses it.
return function(baseDir)
    local categoryMode = type(system.registerWizard) == "function"
    if not model.createMix or (not categoryMode and not system.registerWizardPage) then return end
    baseDir = baseDir or "SCRIPTS:/rfsuite"
    local controller
    -- Deferred wizard callbacks do not reliably retain main.lua's directory.
    -- SCRIPTS: resolves on both physical RADIO: storage and the simulator.
    local controllerPath = baseDir .. "/app/lib/model_wizard.lua"

    local function getController()
        if not controller then
            controller = assert(loadfile(controllerPath))()
            if categoryMode then controller.startCategory() end
        end
        return controller
    end

    local function reset()
        if controller then controller.close(); controller = nil end
    end

    local function available(page)
        return controller ~= nil and controller.available(page)
    end

    local function run()
        -- Ethos calls this when creating the draft mixes. Keep the selections
        -- and generation lock for native Back navigation.
        if controller then controller.run() end
    end

    local pages = {}
    for index = 1, 7 do
        local page = index
        pages[index] = {
            init = page == 1 and reset or nil,
            available = page == 1 and function() return true end or function() return available(page) end,
            build = function() getController().build(page) end,
            run = page == 7 and run or nil
        }
    end
    if categoryMode then
        -- A single cached mask; no render/wakeup allocations or image loads.
        local icon = assert(lcd.loadMask(baseDir .. "/icon.png"), "Rotorflight wizard icon missing")
        system.registerWizard("Rotorflight", icon, pages)
    else
        for _, page in ipairs(pages) do system.registerWizardPage(page) end
    end
end
