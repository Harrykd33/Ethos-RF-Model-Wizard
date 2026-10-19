--[[
  Copyright (C) 2026 Rotorflight Project
  GPLv3 -- https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local function init()
    -- The suite already registers these pages when its integration is installed.
    -- Check the file rather than script load order to avoid duplicate pages.
    local integrated = io.open("SCRIPTS:/rfsuite/lib/register_model_wizard.lua", "r")
    if integrated then
        integrated:close()
        return
    end
    local baseDir = "SCRIPTS:/rotorflight-model-wizard"
    assert(loadfile(baseDir .. "/lib/register_model_wizard.lua"))()(baseDir)
end

return {init = init}
