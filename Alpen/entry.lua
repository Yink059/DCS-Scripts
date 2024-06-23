local test_filepath = lfs.writedir() .. "Alpen/db.json"
local config_filepath = lfs.writedir() .. "Alpen/config.json"
local mission_table_path = lfs.writedir() .. "Alpen/mission.json"

local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")

local unit_db = database.openDatabase(test_filepath, config_filepath, mission_table_path)

if unit_db:getInit() ~= true then
    for i = 1, 2 do
        local groups = coalition.getGroups(i , Group.Category.GROUND)
        for _,g in next, groups do
            local delete = true

            for _, unit in next, g:getUnits() do
                for _, ewrTypeName in next, unit_db.config.EWR do
                    if unit:getTypeName() == ewrTypeName then
                        delete = false
                    end
                end
            end
            if delete then  
                log.write("Init Destroy", log.INFO, "destroying: " .. tostring(g:getName()))
                g:destroy()
            end
        end
    end
    unit_db:loadAllGroups()
else
    unit_db:setInit(false)
end

unit_db:startUpdateLoop(1)
unit_db:addEventHandlers()
