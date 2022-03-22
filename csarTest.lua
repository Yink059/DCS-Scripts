yink = {}
csar = {}
util = {}


csar.redEnabled = false
csar.blueEnabled = false
csar.searchDistance = 200

--------------------------------------------------------------- util defines

function util.split(pString, pPattern) --string.split
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e+1
		s, e, cap = pString:find(fpat, last_end)
	end
	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(Table, cap)
	end
	return Table
end


--[[
util.distance

first parameter: first unit
second parameter: unit to measure to

finds the distance between two dcs objects
]]--

function util.distance( coord1 , coord2) --use z instead of y for getPoint()
	
	if coord1:isExist() then
		local x1 = coord1:getPoint().x
		local y1 = coord1:getPoint().z
	else
		local x1 = coord1.x
		local y1 = coord1.z
	end
	
	if coord2:isExist() then
		local x2 = coord2:getPoint().x
		local y2 = coord2:getPoint().z
	else
		local x2 = coord2.x
		local y2 = coord2.z
	end

	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

--[[
util.round

first parameter: any number
second parameter: number of decimal places to round to

returns a number rounded to the number of decimal places specified
]]--

function util.round(num, numDecimalPlaces)

	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

--[[
util.count

first parameter: table to count number of key/value pairs

if the n value of a table isnt specified (when you dont use table.insert), will count the number of key/value pairs
returns that value
]]--

function util.count(t)
	local i = 0
	for k, v in next, t do
		i = i + 1
	end
	return i
end



--------------------------------------------------------------- yink definitions


--------------------------------------------------------------- csar definitions

csar.instances = {}
csar.activeUnits = {}

function csarInstance:new (o)
	o = o or {}   
	setmetatable(o, self)
	self.__index = self
	return o
end

function csarInstance:setEjectionParams(object)
	self.point = object:getPoint()
	self.coa = object:getCoalition()
	self.type = object:getTypeName()
	self.state = "ejected"
end

function csar.createInstance(object)
	
	local instance = csarInstance:new()
	csarInstance:setEjectionParams(object)
	table.insert(csar.instances, instance)
	return
end

function csar.findClosestCSAR(point)
	
	if #csar.activeUnits <= 0 then
		return nil
	end
	
	local closestDistance, distance, index = util.distance(Unit.getByName(csar.activeUnits[1]),point), 0, 1
	
	for k, v in next, csar.activeUnits do
		if util.distance(Unit.getByName(k),point) < closestDistance then
			index = k
		end
	end
	
	return csar.activeUnits[index]
end

function csar.findActiveSpawn(point, coa)
	
	local spawnPoint, distance
	
	for k, v in next, csar.instances do
		distance = util.distance(point,v.point)
		if distance < csar.searchDistance and coa == v.coa  and v.state ~= "landed" then
			v.state = "landed"
			return v
		end
	end
	
	return nil
end
--------------------------------------------------------------- event handlers



YinkEventHandler = {} --event handlers

	--local old_onEvent = world.onEvent
	function YinkEventHandler:onEvent(event)		
	
--[[
world.event.S_EVENT_LANDING_AFTER_EJECTION

main function for spawning csar units
]]--

		if world.event.S_EVENT_LANDING_AFTER_EJECTION == event.id then		
			
			local o			= event.initiator			
			local staticObj = {}
			local side 		= o:getCoalition()
			local object	= csar.findActiveSpawn(event.initiator:getPoint(),side)
			
			if object == nil then
				o:destroy()
				return
			end
			
			local group 	= {}
			local unit 		= {}
			local freq 		= {}
			unit["name"] 		= "CSAR_" .. tostring(side) .. "_" .. tostring(timer.getTime()) -- name			
			if side == 1 and csar.redEnabled then
				group["country"] 	= country.id.RUSSIA
				unit["type"] 		= "Paratrooper AKS-74"
				trigger.action.radioTransmission("l10n/DEFAULT/beacon_silent.ogg", o:getPoint() , 0 , true , 121500000, 4 , unit["name"])
			elseif side == 2 and csar.blueEnabled then
				group["country"] 	= country.id.USA
				unit["type"] 		= "Soldier M4"
				trigger.action.radioTransmission("l10n/DEFAULT/beacon_silent.ogg", o:getPoint() , 1 , true , 31050000, 4 , unit["name"])
			end
			
			group["category"] 	= 2
			group["name"] 		= unit["name"] .. "_G"
			group["task"] 		= "Ground Nothing"
			group["units"]		= {}
			unit["x"]			= o:getPoint().x -- x
			unit["y"]			= o:getPoint().z -- y
			unit["heading"] 	= math.deg(math.atan2(o:getPosition().x.z, o:getPosition().x.x)+2*math.pi) -- heading
			table.insert(group["units"],unit)
			table.insert(csar.activeUnits,unit["name"])
						
			o:destroy()
			if side ~= 0 then
				coalition.addGroup(group["country"],group["category"],group)
				Group.getByName(group["name"]):getController():setOption(0,4)
			end
		end
		
		if event.initiator ~= nil then
			if event.initiator:getCategory() == 1 then
				if event.initiator:getPlayerName() ~= nil then
			
					if world.event.S_EVENT_EJECTION == event.id then
						csar.createInstance(event.initiator)
						return
					end
	
					if world.event.S_EVENT_BIRTH == event.id then
						return
					end
	
					if world.event.S_EVENT_TAKEOFF == event.id then
						return
					end	
	
					if world.event.S_EVENT_LAND == event.id then
						return
					end					
				end
			end
		end
		--return old_onEvent(event)
	end


world.addEventHandler(YinkEventHandler)

trigger.action.outText("yink.lua loaded",10)
log.write("scripting", log.INFO, "yink.lua loaded")










