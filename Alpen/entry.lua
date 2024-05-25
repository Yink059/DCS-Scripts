local test_filepath = lfs.writedir() .. "Alpen/db.json"
local config_filepath = lfs.writedir() .. "Alpen/config.json"

local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")

local unit_db = database.openDatabase(test_filepath, config_filepath)

if unit_db:getInit() ~= true then
    for i = 1, 2 do
        local groups = coalition.getGroups(i , Group.Category.GROUND)
        for _,g in next, groups do
            log.write("Init Destroy", log.INFO, "destroying: " .. tostring(g:getName()))
            g:destroy()
        end
    end
    unit_db:loadAllGroups()
else
    unit_db:setInit(false)
end

unit_db:startUpdateLoop(1)
unit_db:addEventHandlers()
