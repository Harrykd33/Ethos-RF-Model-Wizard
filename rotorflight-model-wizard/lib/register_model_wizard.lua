--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

-- Keep the form implementation out of memory until model creation uses it.
return function(baseDir)
    if not system.registerWizardPage or not model.createMix then return end
    local controller
    -- Deferred wizard callbacks do not reliably retain main.lua's directory.
    -- SCRIPTS: resolves on both physical RADIO: storage and the simulator.
    local controllerPath = (baseDir or "SCRIPTS:/rfsuite") .. "/app/lib/model_wizard.lua"

    local function getController()
        if not controller then controller = assert(loadfile(controllerPath))() end
        return controller
    end

    local function reset()
        if controller then controller.close(); controller = nil end
    end

    local function available()
        return controller ~= nil and controller.available()
    end

    local function run()
        -- Ethos runs this when it generates the draft channel review, before
        -- the name screen. Retain the selections for native Back navigation.
        if controller then controller.run() end
    end

    for index = 1, 7 do
        local page = index
        system.registerWizardPage({
            init = page == 1 and reset or nil,
            available = page == 1 and function() return true end or available,
            build = function() getController().build(page) end,
            run = page == 7 and run or nil
        })
    end
end
