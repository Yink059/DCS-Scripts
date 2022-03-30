yink = {}
csar = {}
util = {}

csarMaxPassengers = {}--delete later
csarMaxPassengers["Mi-24P"] 		= 3
csarMaxPassengers["UH-1H"]			= 10
csarMaxPassengers["Mi-8MT"]			= 14
csarMaxPassengers["Mi-8MTV2"]		= 10
csarMaxPassengers["SA342Mistral"]	= 2
csarMaxPassengers["SA342Minigun"]	= 3
csarMaxPassengers["SA342L"]			= 3
csarMaxPassengers["SA342M"]			= 3

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
	
	local x1 = coord1.x
	local y1 = coord1.z
	
	local x2 = coord2.x
	local y2 = coord2.z

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

function util.checkSpeed(unit)
	
	local vec3 = unit:getVelocity()
	local speed = math.sqrt((vec3.x^2) + (vec3.y^2) + (vec3.z^2))
	return speed
end


--------------------------------------------------------------- yink definitions


--------------------------------------------------------------- csar definitions

csar.instances = {}
csar.activeUnits = {}
csar.activeUnits.red = {}
csar.activeUnits.blue = {}
csarInstance = {}
csar.heliPassengers = {}
csar.hasCommands = {}
csar.redEnabled = true
csar.blueEnabled = true
csar.alreadySmoked = {}
csar.alreadyFlared = {}

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
	self.playerName = object:getPlayerName()
	self.state = "ejected"
end

function csar.createInstance(object)
	
	local instance = csarInstance:new()
	csarInstance:setEjectionParams(object)
	table.insert(csar.instances, instance)
	return
end

function csarInstance:setUnitName(unitName)
	self.unitName = unitName
end

function csarInstance:clearPoint()
	self.point = [x = 0,y = 0,z = 0]
end

function csar.getInstance(unitName)
	for k, v in next, csar.instances do
		if v.unitName == unitName then
			return v
		end
	end
	return nil
end

function csar.findClosestCSAR(args)
	
	local point, coa = args[1], args[2]
	local csarList
	
	if coa == 1 then
		csarList = csar.activeUnits.red
	else
		csarList = csar.activeUnits.blue
	end
	if csarList[1] == nil then
		return nil
	end
	
	if Unit.getByName(csarList[1]) == nil then
		return nil
	elseif not Unit.getByName(csarList[1]):isExist() then
		return nil
	end
	
	local closestDistance, distance, index = util.distance(Unit.getByName(csarList[1]):getPoint(),point), 0, 1
	
	for k, v in next, csarList do	
		if Unit.getByName(csarList[k]) ~= nil then
			if Unit.getByName(csarList[k]):isExist() then
				if util.distance(Unit.getByName(csarList[k]):getPoint(),point) < closestDistance then
					index = k
				end
			end
		end
	end
	return {objectName = csarList[index], distance = util.distance(Unit.getByName(csarList[index]):getPoint(),point)}
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


function csar.loop(args, time) --timer.scheduleFunction(csar.loop, {event.initiator, csar.activeUnits, event.initiator:getID()}, timer.getTime())
	
	local unit 			= args[1]
	local csarList 		= args[2]
	local id 			= args[3]
	

	if not unit:isExist() then
		--trigger.action.outText(tostring(id).." removed from heli csar loop by not existing",5)
		return nil
	elseif unit:getCategory() ~= 1 then
		--trigger.action.outText(tostring(id).." removed from heli csar loop by category",5)
		return nil
	end
	
	if unit:getID() ~= id then
		return nil
	end
	
	local throwSmoke 	= true
	local throwFlare	= true
	local transmitting	= false
	local closestCSAR = csar.findClosestCSAR({unit:getPoint(), unit:getCoalition()})
	if closestCSAR == nil then return time+10 end
	local smokeColor = {1,4}

	if util.checkSpeed(unit) < 2 then
		
		if closestCSAR.distance < 100 then
			local passengerCount =csar.heliPassengers[unit:getName()]["n"] + (infantry.heliSquads[unit:getName()] * 4)
			if passengerCount < csarMaxPassengers[unit:getTypeName()] then
				csar.getInstance(closestCSAR.objectName):clearPoint()
				csar.heliPassengers[unit:getName()][closestCSAR.objectName] = csar.getInstance(closestCSAR.objectName)
				csar.heliPassengers[unit:getName()]["n"] = csar.heliPassengers[unit:getName()]["n"] + 1
				trigger.action.outTextForGroup(unit:getGroup():getID(),"Pilot extracted! Seats remaining: "..tostring(csarMaxPassengers[unit:getTypeName()] - csar.heliPassengers[unit:getName()]["n"]),10)
				
				if Unit.getByName(closestCSAR.objectName):getCoalition() == 1 then
					for k,v in next, csar.activeUnits.red do
						if v == closestCSAR.objectName then
							table.remove(csar.activeUnits.red, k)
						end
					end
				else
					for k,v in next, csar.activeUnits.blue do
						if v == closestCSAR.objectName then
							table.remove(csar.activeUnits.blue, k)
						end
					end
				end
				Unit.getByName(closestCSAR.objectName):destroy()
				csar.alreadySmoked[closestCSAR.objectName] = nil
				csar.alreadyFlared[closestCSAR.objectName] = nil
				
			else
				trigger.action.outTextForGroup(unit:getGroup():getID(),"You're full with "..tostring(csarMaxPassengers[unit:getTypeName()] - csar.heliPassengers[unit:getName()]["n"]).." passengers.",10)
			end
		end
	end
	
	if not csar.alreadySmoked[closestCSAR.objectName] then --if the unit can throw its initial smoke still
		if closestCSAR.distance < 2000 then
			local csarUnit = Unit.getByName(closestCSAR.objectName)
			csar.alreadySmoked[closestCSAR.objectName] = true
			trigger.action.smoke(csarUnit:getPoint(), smokeColor[csarUnit:getCoalition()])
			timer.scheduleFunction(function() csar.alreadySmoked[closestCSAR.objectName] = nil end, nil, timer.getTime() + 300)
		end
	end
	
	if not csar.alreadyFlared[closestCSAR.objectName] then --if the unit can throw its initial smoke still
		if closestCSAR.distance < 4000 then
			local csarUnit = Unit.getByName(closestCSAR.objectName)
			csar.alreadyFlared[closestCSAR.objectName] = true
			trigger.action.signalFlare(csarUnit:getPoint() , 2 , math.random(1,360) )
		end
	end
	return time+10
end

---------------------------------------------------------- event handlers

YinkEventHandler = {} --event handlers

	--local old_onEvent = world.onEvent
	function YinkEventHandler:onEvent(event)		
	
--[[
world.event.S_EVENT_LANDING_AFTER_EJECTION

main function for spawning csar units
]]--


		if world.event.S_EVENT_BIRTH == event.id then
			if event.initiator:getGroup():getCategory() == 1 then --if player is helicopter						
				if csar.hasCommands[event.initiator:getGroup():getID()] == nil then
					local subMenu = missionCommands.addSubMenuForGroup(event.initiator:getGroup():getID() , "Infantry and CSAR Commands" )
					missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Closest CSAR" , subMenu , csar.findClosestCSAR , {event.initiator:getPoint(),event.initiator:getCoalition()})
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Load Troops" , subMenu , infantry.load , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Unload Troops" , subMenu , infantry.unload , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Toggle Troop Drop" , subMenu , infantry.toggleDrop , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Check Passengers" , subMenu , infantry.passengers , event.initiator:getName())
					csar.hasCommands[event.initiator:getGroup():getID()] = true
				end
				csar.heliPassengers[event.initiator:getName()] = {}
				csar.heliPassengers[event.initiator:getName()]["n"] = 0 --list of rescued pilots on aircraft
				if event.initiator:getCoalition() == 1 then
				return
					timer.scheduleFunction(csar.loop, {event.initiator, csar.activeUnits.red, event.initiator:getID()}, timer.getTime() + 1)
				else
				return
					timer.scheduleFunction(csar.loop, {event.initiator, csar.activeUnits.blue, event.initiator:getID()}, timer.getTime() + 1)
				end
			end
		end

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
			object:setUnitName(unit["name"])
			
			if side == 1 and csar.redEnabled then
				group["country"] 	= country.id.RUSSIA
				table.insert(csar.activeUnits.red,unit["name"])
				unit["type"] 		= "Paratrooper AKS-74"
				trigger.action.radioTransmission("l10n/DEFAULT/beacon_silent.ogg", o:getPoint() , 0 , true , 121500000, 4 , unit["name"])
			elseif side == 2 and csar.blueEnabled then
				group["country"] 	= country.id.USA
				table.insert(csar.activeUnits.blue,unit["name"])
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
						--reset vars
						return
					end
	
					if world.event.S_EVENT_TAKEOFF == event.id then
						return
					end	
	
					if world.event.S_EVENT_LAND == event.id then
						--return csar
						return
					end					
				end
			end
		end
		--return old_onEvent(event)
	end


world.addEventHandler(YinkEventHandler)

trigger.action.outText("csar.lua loaded",10)
log.write("scripting", log.INFO, "csar.lua loaded")









