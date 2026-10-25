--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

return function(baseDir)
    local categoryMode = type(system.registerWizard) == "function"
    if not model.createMix then return end
    if not categoryMode and (not system.registerWizardPage or not system.registerSystemTool or not system.openPage) then return end
    baseDir = baseDir or "SCRIPTS:/rfsuite"
    local controller
    local pending, active = false, false
    local controllerPath = baseDir .. "/app/lib/model_wizard.lua"

    local function clearController()
        if controller then controller.close(); controller = nil end
    end

    local function getController()
        if not controller then
            controller = assert(loadfile(controllerPath))()
            if categoryMode then controller.startCategory() else controller.startLegacy() end
        end
        return controller
    end

    local function reset()
        clearController()
        -- Each explicit legacy launch authorizes one native creation session.
        if not categoryMode then active, pending = pending, false end
    end

    local function available(page)
        if not categoryMode and not active and not pending then return false end
        return page == 1 or controller ~= nil and controller.available(page)
    end

    local function run()
        return (categoryMode or active) and controller ~= nil and controller.run()
    end

    local pages = {}
    for index = 1, 7 do
        local page = index
        pages[index] = {
            init = page == 1 and reset or nil,
            available = function() return available(page) end,
            build = function()
                if available(page) then getController().build(page) end
            end,
            run = page == 7 and run or nil
        }
    end
    local iconPath = categoryMode and "/icon.png" or "/legacy-icon.png"
    local icon = assert(lcd.loadMask(baseDir .. iconPath), "Rotorflight wizard icon missing")
    if categoryMode then
        system.registerWizard("Rotorflight", icon, pages)
    else
        for _, page in ipairs(pages) do system.registerWizardPage(page) end
        system.registerSystemTool({
            name = "Model Wizard", icon = icon,
            create = function()
                clearController()
                active, pending = false, false
                local width = lcd.getWindowSize()
                local function instruction(value, color)
                    local field = form.addStaticText(form.addLine("", nil, false), {x = 0, y = 0, w = width - 16, h = 40}, value)
                    if field and field.color then field:color(lcd.themeColor(color or THEME_WARNING_COLOR)) end
                end
                instruction("Requirements:", THEME_ERROR_COLOR)
                instruction("Go back to System, select Sticks, then disable")
                instruction("First four channels fixed.")
                instruction("Press Create Heli FBL Model below, then choose:")
                instruction("Large + tile > Create model > Other.")
                form.addTextButton(form.addLine(""), nil, "Create Heli FBL Model", function()
                    pending = true
                    system.openPage({model = 0})
                end)
            end
        })
    end
end
