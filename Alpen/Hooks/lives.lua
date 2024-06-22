local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")
local pw = "floggerz"
local test_filepath = lfs.writedir() .. "Alpen/db.json"
local config_filepath = lfs.writedir() .. "Alpen/config.json"
local mission_table_path = lfs.writedir() .. "Alpen/mission.json"
local lives = {}
local lives_db


local gameMasters = {
    ["025ee29567ec00061db890812f4b8ec5"] = true, -- yink
}

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end


local function split(pString, pPattern) --string.split
    local Table = {}
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(Table, cap)
        end
        last_end = e + 1
        s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
        cap = pString:sub(last_end)
        table.insert(Table, cap)
    end
    return Table
end

local function getUcid(pid)
    return net.get_player_info(pid, 'ucid')
end

function lives.onMissionLoadEnd()
    lives_db = database.openDatabase(test_filepath, config_filepath, mission_table_path)
end

function lives.onPlayerTryChangeSlot(pid, coa, sid)
    if lives_db.db.continue == false then return end
    lives_db:read()
    local lives = lives_db:getLives(getUcid(pid))
    local time_left = lives_db:getResetRemaining(getUcid(pid))
    local type_name = DCS.getUnitProperty(sid, DCS.UNIT_TYPE)
    local category = DCS.getUnitProperty(sid, DCS.UNIT_GROUPCATEGORY)
    local cost = lives_db:getCost(tostring(type_name),tostring(category))

    net.send_chat_to("cost of ".. tostring(type_name) .. " is "  .. tostring(cost), pid)
    net.send_chat_to("Lives remaining: ".. tostring(lives), pid)
    net.send_chat_to("Time to reset: ".. formatTime(math.floor(time_left)), pid)
    if cost <= lives then
        net.send_chat_to("Slotted!", pid)
        return
    else
        net.send_chat_to("Not enough lives!", pid)
    end

    return false
end

DCS.setUserCallbacks(lives)