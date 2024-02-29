local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")

local test_filepath = lfs.writedir() .. "Alpen/unit_db.json"

local unit_db = database.openDatabase(test_filepath)

unit_db:startUpdateLoop(1, 10)
