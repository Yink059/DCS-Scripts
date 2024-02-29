local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")

local test_filepath = lfs.writedir() .. "Alpen/hooks_db.json"

local unit_db = database.openDatabase(test_filepath)

local lives = {}

function lives.onMissionLoadEnd()
    unit_db:startUpdateLoopHooks(1, 10)
end

DCS.setUserCallbacks(lives)

