local db = {}
local database = {}


function db:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function database.openDatabase(filepath, config_path)
    local instance = db:new()
    local db = {}

    local config_file, config = io.open(config_path, "r"), {}
    if config_file then
        config = net.json2lua(config_file:read("*all"))
    else
        config =
            net.json2lua([[
                {
                    "reset_time" : 43200,
                    "starting_lives": 6,
                    "airframe_cost" : {
                        "example_type_name" : 1
                    },
                    "default_cost" : {
                        "plane" : 2,
                        "helicopter" : 1
                    }
                }
                ]])
    end
    config_file:close()
    local file = io.open(filepath, "r")
    if file then
        file:close()
    else
        file = io.open(filepath, "w")
        if file then
            local json = { players = {}, units = {}, objectives = {}, reset = os.time(), missionName = "" }
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
    f:close()
    instance.continue = true
    return instance
end

function db:reset()
    --delete file to reset
    self.continue = false
    os.remove(self.filepath)
end

function db:write()
    local file = io.open(self.filepath, "w")
    if file then
        file:write(net.lua2json(self.db))
        file:close()
        return true
    end
    return false
end

function db:read()
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
        self.db.players[ucid] = player
        self:write()
        return true
    else
        return false
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

function db:subtractLife(ucid, amt)
    self:read()
    self.db.players[ucid].lives = self.db.players[ucid].lives - amt
    self:write()
end

function db:resetLives()
    self:read()
    for ucid, playerTable in next, self.db.players do
        self.db.players[ucid].lives = self.config["starting_lives"]
    end
    self.db.reset = os.time()
    self:write()
    log.write("Lives Reset", log.INFO, "Lives were reset at " .. tostring(self.db.reset))
    trigger.action.outText("Lives Reset!", 25)
end

function db:auditLifeTimer()
    self:read()
    local time = os.time()
    local reset_time = self.config.reset_time
    if time - reset_time > self.db.reset then
        self:resetLives()
    end
end

function db:resetPlayerLives(ucid)
    self:read()
    self.db.players[ucid].lives = self.config["starting_lives"]
    self:write()
end

function db:saveGroup(g)
    local group = {}
    group.name = g:getName()
    group.coa = g:getCoalition()
    group.task = "Ground Nothing"
    group.units = {}
    group.category = g:getCategory()
    for i, unit in next, g:getUnits() do
        group.units[i] = {}
        group.units[i].name = unit:getName()
        group.units[i].x = unit:getPoint().x
        group.units[i].y = unit:getPoint().z
        group.units[i].type = unit:getTypeName()
        group.country = unit:getCountry()
    end

    table.insert(self.db.units[group.coa], group)
end

function db:loadGroup(group)
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
    for i = 1, 2 do
        for groupName, group in next, self.db.units[i] do
            self:loadGroup(group)
        end
    end
end

function db:startUpdateLoop(start_time, update_time)
    if self.continue == true then
        local function update(self, time)
            self:saveAllGroups()
            self:auditLifeTimer()
            return time + update_time
        end
        timer.scheduleFunction(update, self, timer.getTime() + start_time)
    end
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
