local db, database = dofile(lfs.writedir() .. "Alpen/db.lua")
local pw = "floggerz"
local test_filepath = lfs.writedir() .. "Alpen/db.json"
local config_filepath = lfs.writedir() .. "Alpen/config.json"
local mission_table_path = lfs.writedir() .. "Alpen/mission.json"
local hooks_db = database.openDatabase(test_filepath, config_filepath)
local sideswitch = {}

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

function sideswitch.onMissionLoadEnd()
    hooks_db = database.openDatabase(test_filepath, config_filepath, mission_table_path)
    hooks_db:startUpdateHooks()
end

function sideswitch.onPlayerTryChangeSlot(pid, coa, sid)
    if coa == 0 then return end
    if hooks_db.db.continue == false then return end
    if hooks_db:getPlayer(getUcid(pid)) == nil or hooks_db:getPlayer(getUcid(pid)).side == 0 then
        net.send_chat_to("please type -red or -blue to pick a side!", pid)
        return false
    end

    if hooks_db:getPlayer(getUcid(pid)).side == coa then
        net.send_chat_to("Welcome back!", pid)
        return
    else
        net.send_chat_to("You're not on that team!", pid)
    end

    return false
end

function sideswitch.onPlayerTrySendChat(pid, msg, toAll)
    if hooks_db.db.continue == false then return end
    if hooks_db:getPlayer(getUcid(pid)) == nil or hooks_db:getPlayer(getUcid(pid)).side == 0 then
        if msg == "-red" then
            hooks_db:addPlayer(getUcid(pid), 1)
        elseif msg == "-blue" then
            hooks_db:addPlayer(getUcid(pid), 2)
        end
    else
        if msg == "-switch" then
            local switched = hooks_db:trySwitch(getUcid(pid))
            if switched ~= 0 then
                net.send_chat_to("You switched sides!", pid)
            else
                net.send_chat_to("Can't switch!", pid)
            end
        end
    end
    if gameMasters[getUcid(pid)] == true then
        if msg == "-pids" then
            local players = net.get_player_list()

            for i, tpid in next, players do
                net.send_chat_to(tostring(net.get_player_info(tpid, 'name')) .. " " .. tostring(getUcid(tpid)), pid)
            end

            return ""
        end
        if msg == "-reset" then
            hooks_db:reset()
            return ""
        end
        if string.find(msg, "-rp") then
            local ucid = split(msg, " ")[2]
            hooks_db:removePlayer(ucid)
            return ""
        end
    end
end

DCS.setUserCallbacks(sideswitch)
