local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")
local pw = "floggerz"
local test_filepath = lfs.writedir() .. "Alpen/db.json"
local config_filepath = lfs.writedir() .. "Alpen/config.json"
local lives_db = database.openDatabase(test_filepath, config_filepath)
local lives = {}

local gameMasters = {
    ["025ee29567ec00061db890812f4b8ec5"] = true, -- yink
}

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

function lives.onPlayerTryChangeSlot(pid, coa, sid)
    lives_db:read()
    local lives = lives_db:getLives(getUcid(pid))
    local category = DCS.getUnitProperty(sid, DCS.UNIT_GROUPCATEGORY)
    local cost = lives_db:getCategoryCost(tostring(category))

    net.send_chat_to("cost of ".. tostring(category) .. " is "  .. tostring(cost), pid)
    net.send_chat_to("Lives remaining: ".. tostring(lives), pid)
    if cost <= lives then
        net.send_chat_to("Slotted!", pid)
        return
    else
        net.send_chat_to("Not enough lives!", pid)
    end

    return false
end

DCS.setUserCallbacks(lives)