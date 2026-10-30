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
    local headerHeli
    local headerLayout
    local launcherHeadingY, launcherHeadingHeight
    local refreshPage

    local function buildHeader(withModelType)
        if not headerHeli then headerHeli = lcd.loadMask(baseDir .. "/header-heli.png") end
        local width = lcd.getWindowSize()
        local oldFont = lcd.font()
        lcd.font(FONT_BOLD)
        local labelWidth, labelHeight = lcd.getTextSize("Heli Wizard")
        lcd.font(oldFont)
        local brandingWidth = labelWidth + (headerHeli and 96 or 0) + 24
        local selectorWidth = withModelType and math.min(240, math.floor(width * 0.30)) or 0
        local left = math.floor((width - brandingWidth - (withModelType and selectorWidth + 16 or 0)) / 2)
        headerLayout = {left = left, width = brandingWidth, labelWidth = labelWidth, labelHeight = labelHeight}
        form.addStaticText(nil, {x = 0, y = 0, w = width - 16, h = 40}, "")
        if withModelType then
            return {x = left + brandingWidth + 16, y = 0, w = selectorWidth, h = 40}
        end
    end

    local function paintHeader()
        local width = lcd.getWindowSize()
        local oldColor, oldFont = lcd.color(), lcd.font()
        lcd.font(FONT_BOLD)
        local label = "Heli Wizard"
        local left = headerLayout.left + 12
        lcd.color(lcd.themeColor(THEME_DEFAULT_BGCOLOR))
        lcd.drawFilledRectangle(headerLayout.left, 0, headerLayout.width, 40)
        lcd.color(lcd.themeColor(THEME_DEFAULT_COLOR))
        lcd.drawText(left, math.floor((40 - headerLayout.labelHeight) / 2), label)
        if headerHeli then lcd.drawMask(left + headerLayout.labelWidth + 16, 2, headerHeli) end
        if launcherHeadingY then
            lcd.color(lcd.themeColor(THEME_PAGE_BGCOLOR))
            lcd.drawFilledRectangle(0, 40, width - 16, launcherHeadingY + launcherHeadingHeight - 40)
            lcd.color(lcd.themeColor(THEME_ERROR_COLOR))
            lcd.drawText(0, launcherHeadingY, "Requirements:")
        end
        lcd.font(oldFont)
        lcd.color(oldColor)
        if controller then controller.paintTitle() end
    end

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

    local function buildPage(page)
        if not available(page) then return end
        refreshPage = nil
        launcherHeadingY = nil
        local current = getController()
        local modelTypeRect = buildHeader(true)
        current.build(page, modelTypeRect, function() refreshPage = page end)
    end

    local pages = {}
    for index = 1, 7 do
        local page = index
        pages[index] = {
            init = page == 1 and reset or nil,
            available = function() return available(page) end,
            build = function() buildPage(page) end,
            wakeup = function()
                if refreshPage == page and available(page) then
                    form.clear()
                    buildPage(page)
                end
            end,
            paint = paintHeader,
            run = page == 7 and run or nil
        }
    end
    local iconPath = categoryMode and "/icon.png" or "/legacy-icon.png"
    local icon = assert(lcd.loadMask(baseDir .. iconPath), "Rotorflight wizard icon missing")
    if categoryMode then
        system.registerWizard("Heli Wizard", icon, pages)
    else
        for _, page in ipairs(pages) do system.registerWizardPage(page) end
        system.registerSystemTool({
            name = "Heli Wizard", icon = icon,
            create = function()
                clearController()
                active, pending = false, false
                local width = lcd.getWindowSize()
                buildHeader()
                local function instruction(value, color)
                    local field = form.addStaticText(form.addLine("", nil, false), {x = 0, y = 0, w = width - 16, h = 40}, value)
                    if field and field.color then field:color(lcd.themeColor(color or THEME_WARNING_COLOR)) end
                end
                launcherHeadingY = 44
                local oldFont = lcd.font()
                lcd.font(FONT_BOLD)
                local _, titleHeight = lcd.getTextSize("Requirements:")
                lcd.font(oldFont)
                launcherHeadingHeight = titleHeight + 6
                form.addStaticText(nil, {x = 0, y = launcherHeadingY, w = width - 16, h = launcherHeadingHeight}, "")
                instruction("System>Sticks then disable")
                instruction("first 4 CH fixed")
                instruction("Press Create Heli FBL Model below, then choose:")
                instruction("Large + tile > Create model > Other.")
                form.addTextButton(form.addLine(""), nil, "Create Heli FBL Model", function()
                    pending = true
                    system.openPage({model = 0})
                end)
            end,
            paint = paintHeader
        })
    end
end
