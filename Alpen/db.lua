local db = {}
local database = {}

local function distanceVec3(vec1, vec2) --use z instead of y for getPoint()
    local x1 = vec1.x
    local y1 = vec1.z
    local z1 = vec1.y
    local x2 = vec2.x
    local y2 = vec2.z
    local z2 = vec2.y

    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

local function getHeading(unit)
    local unitPos = unit:getPosition()
    local headingRad = math.atan2(unitPos.x.z, unitPos.x.x)

    if headingRad < 0 then headingRad = headingRad + 2 * math.pi end

    return headingRad * 180 / math.pi
end

function db:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function database.openDatabase(filepath, config_path, mission_table_path)
    local instance = db:new()
    local db = {}

    local config_file, config = io.open(config_path, "r"), {}
    if config_file then
        config = net.json2lua(config_file:read("*all"))
        config_file:close()
    else
        config =
            net.json2lua([[
                {
                    "reset_time" : 43200,
                    "next_mission_flag" : 13579,
                    "update_time" : 5,
                    "starting_lives": 6,
                    "airframe_cost" : {
                        "example_type_name" : 1
                    },
                    "default_cost" : {
                        "plane" : 2,
                        "helicopter" : 1,
                        "0" : 2,
                        "1" : 1
                    },
                    "life_return_radius" : 3000
                }
                ]])
    end

    local json = { players = {}, units = {}, objectives = {}, reset = -1, missionName = "", continue = true }
    local file = io.open(filepath, "r")
    if file then
        file:close()
    else
        file = io.open(filepath, "w")
        if file then
            json.continue = true
            json.reset = config.reset_time
            json.units[1] = {}
            json.units[2] = {}
            json.init = true
            file:write(net.lua2json(json))
            file:close()
        end
    end
    file:close()
    local f = io.open(filepath, "r")
    instance.filepath = filepath
    instance.config_filepath = config_path
    instance.db = net.json2lua(f:read("*all"))
    instance.config = config
    instance.activeAircraft = {}
    instance.lastLanded = {}
    f:close()
    local f = io.open(mission_table_path, "r")
    log.write("Mission DB", log.INFO, mission_table_path)
    instance.miz = net.json2lua(f:read("*all"))
    f:close()
    instance.mission_table_path = mission_table_path
    instance.continue = true
    return instance
end

function db:reloadMizTable()
    local f = io.open(self.mission_table_path, "r")
    self.miz = net.json2lua(f:read("*all"))
    f:close()
end

function db:checkLanded(coaAircraft)
    local landedAc = {}
    local airborneAc = {}

    for _, v in next, coaAircraft do
        for _, g in next, v do
            local units = g:getUnits()
            if #units > 0 then
                for _, u in next, units do
                    if u ~= nil then
                        if u:isExist() then
                            if u:getPlayerName() ~= nil then
                                if not u:inAir() then
                                    landedAc[u:getName()] = u
                                elseif u:inAir() then
                                    airborneAc[u:getName()] = u
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return landedAc, airborneAc
end

function db:getUCIDFromName(player_name)
    local players = net.get_player_list()
    for pid, playerName in next, players do
        if net.get_player_info(pid, "name") == player_name then
            return net.get_player_info(pid, "ucid")
        end
    end
    return nil
end

function db:checkStatus()
    local landedNearby = {}
    local landed = {}
    local airborne = {}

    for c = 1, 2 do
        local airbases = coalition.getAirbases(c)
        local airplanes = coalition.getGroups(c, Group.Category.AIRPLANE)
        local helis = coalition.getGroups(c, Group.Category.HELICOPTER)
        landed[c], airborne[c] = self:checkLanded({ airplanes, helis })

        for unitName, unitObject in next, landed[c] do
            for _, airbase in next, airbases do
                local dist = distanceVec3(unitObject:getPoint(), airbase:getPoint())

                if dist <= self.config.life_return_radius and airbase:getCoalition() == unitObject:getCoalition() then
                    landedNearby[unitName] = airbase:getName()
                    self.lastLanded[unitName] = airbase:getName()
                    break
                end
            end
        end
    end
    return landedNearby, landed, airborne
end

function db:setConfigFromLuaTable(t)
    self.config = t
end

function db:reset()
    --delete file to reset
    self.db.continue = false
    os.remove(self.filepath)
end

function db:write()
    if not self.db.continue then return false end
    local file = io.open(self.filepath, "w")
    if file then
        file:write(net.lua2json(self.db))
        file:close()
        return true
    end
    return false
end

function db:read()
    if not self.db.continue then return false end
    local file = io.open(self.filepath, "r")
    local s = "{}"
    if file then
        s = file:read("*all")
        file:close()
    end
    self.db = net.json2lua(s)
    return self.db
end

function db:update()
    local current = self:read()
    for ucid, player in next, current.players do
        self.db.players[ucid] = player
    end
    self.db.units = current.units
    self.db.objectives = current.objectives
end

function db:readConfig()
    local file = io.open(self.config_filepath, "r")
    local s = "{}"
    if file then
        s = file:read("*all")
        file:close()
    end
    self.config = net.json2lua(s)
    return self.config
end

function db:writeConfig()
    local file = io.open(self.config_filepath, "w")
    if file then
        file:write(net.lua2json(self.config))
        file:close()
        return true
    end
    return false
end

function db:setConfigLivesResetTimer(time)
    self:readConfig()
    self.config.reset_time = time
    self:writeConfig()
end

function db:setConfigStartingLives(amt)
    self:readConfig()
    self.config.starting_lives = amt
    self:writeConfig()
end

function db:setMissionName(name)
    self:read()
    self.db.missionName = name
    self:write()
end

function db:getPlayer(ucid)
    self:read()
    return self.db.players[ucid]
end

function db:addPlayer(ucid, side)
    local current = self:read()
    if self:getPlayer(ucid) == nil then
        local player = {}
        player.side = side
        player.lives = self.config.starting_lives
        player.reset = self.config.reset_time
        player.side_reset = self.config.side_reset_time
        player.switch = self.config.switch_count
        self.db.players[ucid] = player
        self:write()
        return true
    else
        self.db.players[ucid].side = side
        return true
    end
end

function db:removePlayer(ucid)
    self:read()
    self.db.players[ucid] = nil
    self:write()
end

function db:updatePlayers()
end

function db:getCost(type_name, category)
    if self.config.airframe_cost[type_name] ~= nil then
        return self.config.airframe_cost[type_name]
    else
        return self.config.default_cost[category]
    end
end

function db:getLives(ucid)
    self:read()
    return self.db.players[ucid].lives
end

function db:getResetRemaining(ucid)
    self:read()
    return self.db.players[ucid].reset
end

function db:trySwitch(ucid)
    self:read()
    if self.db.players[ucid].switch > 0 and self.db.players[ucid].side ~= 0 then
        if self.db.players[ucid].side == 1 then
            self.db.players[ucid].side = 2
        elseif self.db.players[ucid].side == 2 then
            self.db.players[ucid].side = 1
        end
        self.db.players[ucid].switch = self.db.players[ucid].switch - 1
        self:write()
        return self.db.players[ucid].side
    else
        self.db.players[ucid].switch = 0
    end
    return 0
end

function db:subtractLife(ucid, amt)
    self:read()
    self.db.players[ucid].lives = self.db.players[ucid].lives - amt
    self:write()
end

function db:addLife(ucid, amt)
    self:read()
    self.db.players[ucid].lives = self.db.players[ucid].lives + amt
    self:write()
end

function db:resetAllLives()
    self:read()
    for ucid, playerTable in next, self.db.players do
        self.db.players[ucid].lives = self.config["starting_lives"]
        self.db.players[ucid].reset = self.config.reset_time
    end
    self:write()
    log.write("Lives Reset", log.INFO, "Lives were reset at " .. tostring(self.db.reset))
    trigger.action.outText("All Lives Reset!", 25, false)
end

function db:resetPlayerLives(ucid)
    self:read()

    self.db.players[ucid].lives = self.config["starting_lives"]
    self.db.players[ucid].switch = self.config.switch_count
    self.db.players[ucid].reset = self.config.reset_time

    self:write()
    log.write("Player Lives Reset", log.INFO, tostring(ucid) .. " lives were reset at " .. tostring(self.db.reset))
end

function db:resetPlayerLives(ucid)
    self:read()

    self.db.players[ucid].side = 0

    self:write()
    log.write("Player Side Reset", log.INFO, tostring(ucid))
end

function db:auditLifeTimer()
    self:read()

    for ucid, playerTable in next, self.db.players do
        if self.db.players[ucid].lives ~= self.config.starting_lives then
            local reset_remaining = self.db.players[ucid].reset - self.config.update_time
            if reset_remaining < 0 then
                self:resetPlayerLives(ucid)
            else
                self.db.players[ucid].reset = reset_remaining
                self:write()
            end
            local side_reset_remaining = self.db.players[ucid].side_reset - self.config.update_time
            if side_reset_remaining < 0 then
                self:resetPlayerSide(ucid)
            else
                self.db.players[ucid].side_reset = side_reset_remaining
                self:write()
            end
        end
    end
end

function db:saveGroup(g)
    local group = {}
    group.name = g:getName()
    group.coa = g:getCoalition()
    group.task = "Ground Nothing"
    group.units = {}
    group.category = g:getCategory()
    group.lateActivation = true
    local isEWR = false
    for i, unit in next, g:getUnits() do
        group.units[i] = {}
        group.units[i].name = unit:getName()
        group.units[i].x = unit:getPoint().x
        group.units[i].y = unit:getPoint().z
        group.units[i].heading = getHeading(unit)
        group.units[i].type = unit:getTypeName()
        group.country = unit:getCountry()
        if unit:isActive() then
            group.lateActivation = false
        end
        
        for k,v in next, self.config.EWR do
            if group.units[i].type == v then
                isEWR = true
            end
        end

    end
    if not isEWR then
        table.insert(self.db.units[group.coa], group)
    end
end

function db:loadGroup(group, mizGroup)
    coalition.addGroup(group.country, group.category, group)
end

function db:saveAllGroups()
    self:read()
    for i = 1, 2 do
        self.db.units[i] = {}
        local groups = coalition.getGroups(i, 2)
        for _, g in next, groups do
            self:saveGroup(g)
        end
    end
    self:write()
end

function db:loadAllGroups()
    self:read()
    self:reloadMizTable()
    for i = 1, 2 do
        for _, group in next, self.db.units[i] do
            for coaName, coaTable in next, self.miz.mission.coalition do
                for c, countryTable in next, coaTable.country do
                    if countryTable.vehicle ~= nil then
                        for g, groupTable in next, countryTable.vehicle.group do
                            if groupTable.name == group.name then
                                for _, unit in next, group.units do
                                    for _, unitTable in next, groupTable.units do
                                        if unitTable.name == unit.name then
                                            if unitTable.playerCanDrive == true then
                                                log.write("playerCanDrive",log.INFO, unitTable.name)
                                                unit.playerCanDrive = true
                                            end
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end
            end
            self:loadGroup(group)
        end
    end
end

function db:lifeLoop()
    local landedNearby, landed, airborne = self:checkStatus()

    for coa, coaTable in next, airborne do
        for unitName, unitObject in next, coaTable do
            if unitObject ~= nil then
                if unitObject:isExist() then
                    if self.activeAircraft[unitName] ~= true then
                        self.activeAircraft[unitName] = true
                        local playerName = unitObject:getPlayerName()
                        if playerName == nil then return end
                        local lastAirfield = self.lastLanded[unitName]
                        local type_name = unitObject:getTypeName()
                        local category = unitObject:getDesc().category
                        local cost = self:getCost(tostring(type_name), tostring(category))

                        local ucid = self:getUCIDFromName(playerName)
                        landedNearby[unitName] = nil
                        self:subtractLife(ucid, cost)

                        trigger.action.outTextForUnit(unitObject:getID(),
                            "You have taken off from " .. lastAirfield .. ".",
                            15)
                        trigger.action.outTextForUnit(unitObject:getID(),
                            type_name ..
                            " Cost: " .. tostring(cost) .. " | Lives Left: " .. tostring(self:getLives(ucid)),
                            15)
                    end
                end
            end
        end
    end

    for coa, coaTable in next, landed do
        for unitName, unitObject in next, coaTable do
            if unitObject ~= nil then
                if unitObject:isExist() then
                    if self.activeAircraft[unitName] ~= false and landedNearby[unitName] ~= nil then
                        self.activeAircraft[unitName] = false
                        local playerName = unitObject:getPlayerName()
                        if playerName == nil then return end
                        local lastAirfield = landedNearby[unitName]
                        local type_name = unitObject:getTypeName()
                        local category = unitObject:getDesc().category
                        local cost = self:getCost(tostring(type_name), tostring(category))
                        local ucid = self:getUCIDFromName(playerName)

                        self:addLife(ucid, cost)

                        trigger.action.outTextForUnit(unitObject:getID(),
                            "You have landed at " .. landedNearby[unitName] .. ".",
                            15)
                        trigger.action.outTextForUnit(unitObject:getID(),
                            type_name ..
                            " Cost: " .. tostring(cost) .. " | Lives Total: " .. tostring(self:getLives(ucid)),
                            15)
                    end
                end
            end
        end
    end
end

function db:addEventHandlers()
    local eh = {}

    local enumFunctions = {}

    local function birth(event)
        if event.initiator ~= nil then
            if event.initiator:getPlayerName() ~= nil then
                self.activeAircraft[event.initiator:getName()] = false
            end
        end
    end

    enumFunctions["S_EVENT_BIRTH"] = birth

    function eh:onEvent(event)
        for enum, func in next, enumFunctions do
            if event.id == world.event[enum] then
                func(event)
                return nil
            end
        end
    end

    trigger.action.outText("Added Event Handlers!", 15)
    self.EventHandler = world.addEventHandler(eh)
end

function db:startUpdateLoop(start_time)
    local function update(self, time)
        if trigger.misc.getUserFlag(self.config.next_mission_flag) == 1 then
            self:reset()
        end

        if self.db.continue == false then return nil end
        self:saveAllGroups()
        self:auditLifeTimer()
        self:lifeLoop()
        return time + self.config.update_time
    end
    timer.scheduleFunction(update, self, timer.getTime() + start_time)
end

function db:startUpdateHooks()
    local function update(self, time)
        return time
    end
    return self
end

function db:getInit()
    self:read()
    return self.db.init
end

function db:setInit(bool)
    self:read()
    self.db.init = bool
    self:write()
end

return db, database
