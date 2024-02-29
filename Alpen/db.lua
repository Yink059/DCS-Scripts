local db = {}
local database = {}


function db:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function database.openDatabase(filepath)
    local instance = db:new()
    local db = {}
    local file = io.open(filepath, "r")
    if file then
        file:close()
    else
        file = io.open(filepath, "w")
        if file then
            local json = { players = {}, units = {}, objectives = {} }
            json.units[1] = {}
            json.units[2] = {}
            file:write(net.lua2json(json))
            file:close()
        end
    end
    file:close()
    local f = io.open(filepath, "r")
    instance.filepath = filepath
    instance.db = net.json2lua(f:read("*all"))
    f:close()
    return instance
end

function db:reset()
    --delete file to reset
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
    return net.json2lua(s)
end

function db:update()
    local current = self:read()
    for ucid, player in next, current.players do
        self.db.players[ucid] = player
    end
end

function db:setMissionName(name)
    self.missionName = name
end

function db:getPlayer(ucid)
    return self.db.players[ucid]
end

function db:addPlayer(ucid)
    if self:getPlayer(ucid) == nil then
        local player = {}
        player.side = ""
        player.lives = {}
        self.db.players[ucid] = player
        return true
    else
        return false
    end
end

function db:removePlayer(ucid)
    self.db.players[ucid] = nil
end

function db:updatePlayers()
end

function db:getLives(ucid)
    return self.db.players[ucid].lives
end

function db:subtractLife(type)
end

function db:resetLives()
    for ucid, playerTable in next, self.db.players do

    end
end

function db:resetPlayerLives(ucid)
end

function db:saveGroup(g)
    local group = {}
    group.name = g:getName()
    group.coa = g:getCoalition()
    group.task = "Ground Nothing"
    group.units = {}
    for i, unit in next, g:getUnits() do
        group.units[i] = {}
        group.units[i].name = unit:getName()
        group.units[i].x = unit:getPoint().x
        group.units[i].y = unit:getPoint().z
        group.units[i].type = unit:getTypeName()
        group.country = unit:getCountry()
    end

    trigger.action.outText(self.filepath, 20, false)

    table.insert(self.db.units[group.coa], group)
end

function db:loadGroup(group)
end

function db:saveAllGroups()
    for i = 1, 2 do
        self.db.units[i] = {}
        local groups = coalition.getGroups(i, 2)
        for _, g in next, groups do
            self:saveGroup(g)
        end
    end
end

function db:loadAllGroups()
end

function db:startUpdateLoop(start_time, update_time)
    local function update(self, time)
        self:update()
        self:saveAllGroups()
        self:write()
        return time + update_time
    end
    timer.scheduleFunction(update, self, timer.getTime() + start_time)
end

function db:startUpdateLoopHooks(start_time, update_time)
    local function update(self, time)
        self:update()
        self:saveAllGroups()
        self:write()
        return time + update_time
    end
    timer.scheduleFunction(update, self, DCS.getModelTime() + start_time)
end

return db, database
