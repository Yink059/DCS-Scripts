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

lives = {}
lives.activeUnits = {}
lives.unitNames = {}
local unitExemption = {}

unitExemption["Mi-8MT"]	 = true
unitExemption["Mi-8MTV2"] = true
unitExemption["UH-1H"] = true

for k, v in next, unitExemption do
	trigger.action.setUserFlag(k,v)
end

csar.searchDistance = 500

csar.blueEnabled = true
csar.redEnabled = true

csar.activeUnits 	= {}
csar.isLanded 	= {}

trigger.action.setUserFlag("lifeLimit_helicopter",2)
trigger.action.setUserFlag("lifeLimit_airplane",1)
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

function util.bearing(vec3A, vec3B)
	local azimuth = math.atan2(vec3B.z - vec3A.z, vec3B.x - vec3A.x)
	return azimuth<0 and math.deg(azimuth+2*math.pi) or math.deg(azimuth)
end

--------------------------------------------------------------- yink definitions

--------------------------------------------------------------- csar instance definitions

csarInstance = {}
csar.instances = {}

function csarInstance:new (t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self
	return t
end

function csarInstance:setEjectionParams(object)
	self.object = object
	self.point = object:getPoint()
	self.coa = object:getCoalition()
	self.type = object:getTypeName()
	self.playerName = object:getPlayerName()
	self.category = object:getGroup():getCategory()
	self.time = timer.getTime()
	self.visible = true
	
	for k, v in next, net.get_player_list() do
		if net.get_player_info(v , 'name') == self.playerName then
			self.playerID = v
			break
		end
	end
	
	self.state = "ejected"
end

function csar.createInstance(object)
	
	if lives.activeUnits[object:getName()] == false then
		return nil
	end
	
	local instance = csarInstance:new()
	instance:setEjectionParams(object)
	table.insert(csar.instances, instance)
	
	return instance
end

function csar.getInstance(unitName)
	for k, v in next, csar.instances do
		if v.unitName == unitName then
			return v
		end
	end
	return nil
end

function csar.getInstanceByPlayerName(playerName)
	for k, v in next, csar.instances do
		if v.playerName == playerName then
			return v
		end
	end
	return nil
end

function csarInstance:setUnitName(unitName)
	self.unitName = unitName
end

function csarInstance:clearPoint()
	self.point = {x = 0,y = 0,z = 0}
end

function csarInstance:reset(point)
	self.point = point
	self.state = "ejected"
	self.visible = true
end

function csarInstance:delete()
	for k, v in next, csar.instances do
		if self == v then
			table.remove(csar.instances, k)
		end
	end
	self = nil
end
--------------------------------------------------------------- csar definitions

csar.activeUnits = {}
csar.activeUnits.red = {}
csar.activeUnits.blue = {}
csar.heliPassengers = {}
csar.hasCommands = {}
csar.redEnabled = true
csar.blueEnabled = true
csar.alreadySmoked = {}
csar.alreadyFlared = {}

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
	
	if unit:getCoalition() == 1 then
		csar.updateLists()
		csarList = csar.activeUnits.red
	elseif unit:getCoalition() == 2 then
		csar.updateLists()
		csarList = csar.activeUnits.blue
	end
	
	
	local throwSmoke 	= true
	local throwFlare	= true
	local transmitting	= false
	local closestCSAR = csar.findClosestCSAR({unit:getPoint(), unit:getCoalition()})
	if closestCSAR == nil then return time+10 end
	local smokeColor = {1,4}

	if util.checkSpeed(unit) < 2 then
		
		if closestCSAR.distance < 100 then
			local passengerCount =csar.heliPassengers[unit:getName()]["n"]
			if passengerCount < csarMaxPassengers[unit:getTypeName()] then
				csar.heliPassengers[unit:getName()][closestCSAR.objectName] = csar.getInstance(closestCSAR.objectName)
				csar.heliPassengers[unit:getName()]["n"] = csar.heliPassengers[unit:getName()]["n"] + 1
				trigger.action.outTextForGroup(unit:getGroup():getID(),  csar.heliPassengers[unit:getName()][closestCSAR.objectName].type .. " pilot ".. csar.heliPassengers[unit:getName()][closestCSAR.objectName].playerName .." extracted! Seats remaining: "..tostring(csarMaxPassengers[unit:getTypeName()] - csar.heliPassengers[unit:getName()]["n"]),10)
				csar.getInstance(closestCSAR.objectName).visible = false
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
			timer.scheduleFunction(function() csar.alreadySmoked[closestCSAR.objectName] = nil end, nil, timer.getTime() + 300) --reset smoke timer
		end
	end
	
	if not csar.alreadyFlared[closestCSAR.objectName] then --if the unit can throw its initial flare still
		if closestCSAR.distance < 4000 and closestCSAR.distance > 500 then
			local csarUnit = Unit.getByName(closestCSAR.objectName)
			csar.alreadyFlared[closestCSAR.objectName] = false
			trigger.action.signalFlare(csarUnit:getPoint() , 2 , math.random(1,360) )
		end
	end
	return time+10
end

function csar.createCsarUnit(coa,point,obj)			
	local staticObj = {}
	local side 		= coa
	local object	= csar.findActiveSpawn(point,side)
		
	if object == nil then
		if obj ~= nil then obj:destroy() end
		return
	end
	
	local group 	= {}
	local unit 		= {}
	local freq 		= {}
	unit["name"] 		= "CSAR_" .. tostring(side) .. "_" .. tostring(timer.getTime()) .."_".. tostring(math.random(99999)) -- name
	object:setUnitName(unit["name"])
	
	local setImmortal = { 
		id = 'SetImmortal', 
		params = { 
			value = true
		} 
	}
	
	if side == 1 and csar.redEnabled then
		group["country"] 	= country.id.RUSSIA
		table.insert(csar.activeUnits.red,unit["name"])
		unit["type"] 		= "Paratrooper AKS-74"
		trigger.action.radioTransmission("l10n/DEFAULT/beacon_silent.ogg", point , 0 , true , 121500000, 4 , unit["name"])
	elseif side == 2 and csar.blueEnabled then
		group["country"] 	= country.id.USA
		table.insert(csar.activeUnits.blue,unit["name"])
		unit["type"] 		= "Soldier M4"
		trigger.action.radioTransmission("l10n/DEFAULT/beacon_silent.ogg", point , 1 , true , 31050000, 4 , unit["name"])
	end
			
	group["category"] 	= 2
	group["name"] 		= unit["name"] .. "_G"
	group["task"] 		= "Ground Nothing"
	group["units"]		= {}
	unit["x"]			= point.x + math.random(-10,10) -- x
	unit["y"]			= point.z + math.random(-10,10) -- y
	unit["heading"] 	= math.random(360)
	table.insert(group["units"],unit)
	
	
	--trigger.action.outText(object.type,5)
	
	--trigger.action.outText(object.unitName,5)
	
	--trigger.action.outText(object.time,5)
	
	if side ~= 0 then
		coalition.addGroup(group["country"],group["category"],group)
		Group.getByName(group["name"]):getController():setOption(0,4)
		Group.getByName(group["name"]):getController():setCommand(setImmortal)
	end
end

function csar.returnUnits(unit)
	local coa = unit:getCoalition()
	local bases = coalition.getAirbases(coa)
	local closestBase = bases[1]
	local distance
	local closestDistance = util.distance(unit:getPoint(), closestBase:getPoint())
	
	for k, v in next, bases do
		distance = util.distance(unit:getPoint(), v:getPoint())
		if distance < closestDistance then
			closestDistance = distance
			closestBase = v
		end
	end
	
	local outputString = "Passengers Returned to ".. closestBase:getName() ..":"
	
	if closestDistance < 500 and csar.heliPassengers[unit:getName()]["n"] > 0 then
		for k, v in next, csar.heliPassengers[unit:getName()] do
			if v.playerName ~= nil then
				outputString = outputString  .. "\n" .. v.playerName .. " | " .. v.type
			end
		end
		csar.heliPassengers[unit:getName()]["n"] = 0
		trigger.action.outTextForGroup(unit:getGroup():getID(),outputString,15)
	end
	
	
end

function csar.bailOut(object)
	if csar.heliPassengers[object:getName()] ~= nil then
		if csar.heliPassengers[object:getName()]["n"] > 0 then
			for k, v in next, csar.heliPassengers[object:getName()] do
				if type(v) ~= "number" then
					v:reset(object:getPoint())
					csar.createCsarUnit(object:getCoalition(), object:getPoint(), nil)
				end
			end
		end			
	end
					
	local create = true
	for k, v in next, csar.instances do
		if v.object == object then
			create = false
		end
	end
						
	if unitExemption[object:getTypeName()] then
		create = false
	end
					
	if create then
		csar.createInstance(object)
		csar.createCsarUnit(object:getCoalition(), object:getPoint(), object)
	end
	
	for k, v in next, net.get_player_list() do
		if net.get_player_info(v , 'name') == object:getPlayerName() then
			net.force_player_slot(v,0,'')
			break--timer.scheduleFunction(function(v2) net.force_player_slot(v2,0,'') end , v , timer.getTime() + 2) 
		end
	end
	
	return
end



function csar.bail(args, time)
	local bail = trigger.misc.getUserFlag("bail")

	if tostring(bail) == '1' then
		for k, v in next, coalition.getPlayers(1) do
			if tostring(trigger.misc.getUserFlag(v:getPlayerName().."_bail")) == '1' then
				trigger.action.outTextForGroup(v:getGroup():getID(),"bailing out "..v:getPlayerName(),5)--test
				trigger.action.setUserFlag(v:getPlayerName() .."_bail", 0)
				csar.bailOut(v)
			end
		end
		for k, v in next, coalition.getPlayers(2) do
			if tostring(trigger.misc.getUserFlag(v:getPlayerName().."_bail")) == '1' then
				trigger.action.outTextForGroup(v:getGroup():getID(),"bailing out "..v:getPlayerName(),5)--test
				trigger.action.setUserFlag(v:getPlayerName() .."_bail", 0)
				csar.bailOut(v)
			end
		end
	end
	trigger.action.setUserFlag("bail",0)
	return time + 1
end

timer.scheduleFunction(csar.bail, nil , timer.getTime()+1)


function csar.list(objectName)
	
	local object = Unit.getByName(objectName)
	local outputString = "CSAR List:"
	local coa = object:getCoalition()
	local bulls = coalition.getMainRefPoint(coa)
	local csarList, bearing, distance
	
	if object:getCoalition() == 1 then
		csarList = csar.activeUnits.red
	elseif object:getCoalition() == 2 then
		csarList = csar.activeUnits.blue
	end
	
	for k, v in next, csar.instances do
		if v.coa == coa and v.visible then
			bearing = util.round(util.bearing(bulls, v.point))
			distance = util.round(util.distance(bulls,v.point)/1000)
			outputString = outputString .. "\n".. v.type .." Pilot " .. v.playerName .. " at bullseye " .. tostring(bearing) .. " for ".. tostring(distance).. "."
		end
	end
	trigger.action.outTextForGroup(object:getGroup():getID(), outputString, 15)
end

function csar.updateLists()
	csar.activeUnits.red = {}
	csar.activeUnits.blue = {}
	
	for k, v in next, csar.instances do
		if v.coa == 1 then
			table.insert(csar.activeUnits.red, v.unitName)
		elseif v.coa == 2 then		
			table.insert(csar.activeUnits.blue, v.unitName)
		end
	end
end

csar.playersOutOfLives = {}
csar.playersOutOfLives["heli"] = {}
csar.playersOutOfLives["plane"] = {}
csar.playersOutOfLives["resetting_plane"] = {}
csar.playersOutOfLives["resetting_heli"] = {}

function csar.resetLives(pid)
	
	local name 	= net.get_player_info(pid , 'name')
	local coa 	= net.get_player_info(pid , 'side')
	local slot 	= net.get_player_info(pid , 'slot')
	local ucid 	= tostring(net.get_player_info(pid , 'ucid'))
	
	local livesAirplanes 	= trigger.misc.getUserFlag(tostring(pid).."_lives_airplane")
	local airplaneLimit 	= trigger.misc.getUserFlag("lifeLimit_airplane")
	
	local livesHelicopter 	= trigger.misc.getUserFlag(tostring(pid).."_lives_helicopter")
	local helicopterLimit 	= trigger.misc.getUserFlag("lifeLimit_helicopter")
	
	trigger.action.outText(tostring(livesAirplanes),5)
	trigger.action.outText(tostring(airplaneLimit),5)
	
	
	if livesAirplanes < airplaneLimit then
		csar.playersOutOfLives["plane"][ucid] = false
	end
	
	if livesHelicopter < helicopterLimit then
		csar.playersOutOfLives["heli"][ucid] = false
	end
	
	trigger.action.outText("lives: " .. tostring(livesAirplanes >= airplaneLimit),5)
	trigger.action.outText("player out of lives?: " .. tostring(csar.playersOutOfLives["plane"][ucid]),5)
	
	local unit, category
	local exists, bool = false, false
	for k, v in next, coalition.getPlayers(1) do
		if v:getPlayerName() == name then
			unit = v
			category = unit:getGroup():getCategory()
			exists = true
			break
		end
	end	
	for k, v in next, coalition.getPlayers(2) do
		if v:getPlayerName() == name then
			unit = v
			category = unit:getGroup():getCategory()
			exists = true
			break
		end
	end	
	
	bool = (coa == 0) or (category ~= 0)
	
	if livesAirplanes >= airplaneLimit and bool and not csar.playersOutOfLives["resetting_plane"][ucid] then

		trigger.action.outText('resetting!',5)
		csar.playersOutOfLives["resetting_plane"][ucid] = true
		
		timer.scheduleFunction(
			function(pid2)
				
				local name = net.get_player_info(pid2 , 'name')
				local unit
				local category = -1
				local exists, bool = false, false
				for k, v in next, coalition.getPlayers(1) do
					if v:getPlayerName() == name then
						unit = v
						category = unit:getGroup():getCategory()
						exists = true
						break
					end
				end	
				for k, v in next, coalition.getPlayers(2) do
					if v:getPlayerName() == name then
						unit = v
						category = unit:getGroup():getCategory()
						exists = true
						break
					end
				end			
				
				local instance
				local ucid2	= tostring(net.get_player_info(pid , 'ucid'))
				csar.playersOutOfLives["resetting_plane"][ucid2] = false
				if tonumber(trigger.misc.getUserFlag(pid2.."_lives_airplane")) >= airplaneLimit and category ~= 0 then
					trigger.action.setUserFlag(tostring(pid2).."_lives_airplane",airplaneLimit - 1) 
					instance = csar.getInstanceByPlayerName(net.get_player_info(pid , 'name'))
					if instance ~= nil then
						instance:delete()
					end
				end
			end,
			pid,
			timer.getTime() + 10
		)
		
	end
	
	if livesHelicopter >= helicopterLimit and coa == 0 and not csar.playersOutOfLives["heli"][ucid] then
		
		timer.scheduleFunction(
			function(pid2)
				if tonumber(trigger.misc.getUserFlag(pid2.."_lives_airplane")) >= helicopterLimit then
					trigger.action.setUserFlag(tostring(pid2).."_lives_airplane", helicopterLimit - 1) 
				end
			end,
			pid,
			timer.getTime() + 10
		)
	end
	
	return	
end

function csar.resetLoop(args, time)

	for k, v in next, net.get_player_list() do
		local pid = net.get_player_info(v , 'id')
		csar.resetLives(pid)
	end
	return time + 5
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
			if event.initiator:getPlayerName() ~= nil then 
				csar.heliPassengers[event.initiator:getName()] = {}
				csar.heliPassengers[event.initiator:getName()]["n"] = 0 --list of rescued pilots on aircraft
				trigger.action.setUserFlag(event.initiator:getPlayerName() .."_bail", false)
				lives.activeUnits[event.initiator:getName()] = false
			end
			if event.initiator:getGroup():getCategory() == 1 then --if player is helicopter						
				if csar.hasCommands[event.initiator:getGroup():getID()] == nil then
					local subMenu = missionCommands.addSubMenuForGroup(event.initiator:getGroup():getID() , "Infantry and CSAR Commands" )
					missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Closest CSARs" , subMenu , csar.list , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Load Troops" , subMenu , infantry.load , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Unload Troops" , subMenu , infantry.unload , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Toggle Troop Drop" , subMenu , infantry.toggleDrop , event.initiator:getName())
					--missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Check Passengers" , subMenu , infantry.passengers , event.initiator:getName())
					csar.hasCommands[event.initiator:getGroup():getID()] = true
				end
				
				if event.initiator:getCoalition() == 1 then
					timer.scheduleFunction(csar.loop, {event.initiator, csar.activeUnits.red, event.initiator:getID()}, timer.getTime() + 1)
				else
					timer.scheduleFunction(csar.loop, {event.initiator, csar.activeUnits.blue, event.initiator:getID()}, timer.getTime() + 1)
				end
			end
		end

		if world.event.S_EVENT_LANDING_AFTER_EJECTION == event.id then
			event.initiator:destroy()
			return
		end
		
		if event.initiator ~= nil then
			if event.initiator:getCategory() == 1 then
				if event.initiator:getPlayerName() ~= nil then	
					----------------------------------------------
					if world.event.S_EVENT_EJECTION == event.id then
						csar.createInstance(event.initiator)
						csar.createCsarUnit(event.initiator:getCoalition(), event.initiator:getPoint(), event.initiator)--(coa,point,obj)		
						return
					end
					----------------------------------------------
					if world.event.S_EVENT_CRASH == event.id then
					
						if csar.heliPassengers[event.initiator:getName()] ~= nil then
							if csar.heliPassengers[event.initiator:getName()]["n"] > 0 then
								for k, v in next, csar.heliPassengers[event.initiator:getName()] do
									if type(v) ~= "number" then
										v:reset(event.initiator:getPoint())
										csar.createCsarUnit(event.initiator:getCoalition(), event.initiator:getPoint(), nil)
									end
								end
							end			
						end
					
						local create = true
						for k, v in next, csar.instances do
							if v.object == event.initiator then
								create = false
							end
						end
						
						if unitExemption[event.initiator:getTypeName()] then
							create = false
						end
						
						--add no spawn for csar chopper
						if create then
							csar.createInstance(event.initiator)
							csar.createCsarUnit(event.initiator:getCoalition(), event.initiator:getPoint(), event.initiator)
						end
						
						
						return
					end
					----------------------------------------------
					if world.event.S_EVENT_TAKEOFF == event.id then
						if lives.activeUnits[event.initiator:getName()] == false then
							lives.activeUnits[event.initiator:getName()] = true
							
							local coa = event.initiator:getCoalition()
							local bases = coalition.getAirbases(coa)
							local closestBase = bases[1]
							local distance
							local closestDistance = util.distance(event.initiator:getPoint(), closestBase:getPoint())
							local pid
				
							for k, v in next, bases do
								distance = util.distance(event.initiator:getPoint(), v:getPoint())
								if distance <= closestDistance then
									closestDistance = distance
									closestBase = v
								end
							end							

							trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"You have taken off from "..closestBase:getName(),5)
							
							if unitExemption[event.initiator:getTypeName()] then
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"CSAR Chopper: no life modification.",5)
								return
							end
							
							for k, v in next, net.get_player_list() do
								if net.get_player_info(v , 'name') == event.initiator:getPlayerName() then
									pid = v
									break
								end
							end
							
							if event.initiator:getGroup():getCategory() == Group.Category.AIRPLANE then
								trigger.action.setUserFlag(tostring(pid).."_lives_airplane",tonumber(trigger.misc.getUserFlag(pid.."_lives_airplane")) + 1)
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Airplane life used! Lives remaining: "..tostring( tonumber(trigger.misc.getUserFlag('lifeLimit_airplane')) - tonumber(trigger.misc.getUserFlag(pid.."_lives_airplane")) ),5)
							elseif event.initiator:getGroup():getCategory() == Group.Category.HELICOPTER then
								trigger.action.setUserFlag(tostring(pid).."_lives_helicopter",tonumber(trigger.misc.getUserFlag(pid.."_lives_helicopter")) + 1)
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Helicopter life used! Lives remaining: "..tostring( tonumber(trigger.misc.getUserFlag('lifeLimit_helicopter')) - tonumber(trigger.misc.getUserFlag(pid.."_lives_helicopter")) ),5)
							end
						end
						return
					end	
					----------------------------------------------
					if world.event.S_EVENT_LAND == event.id then
					
						if lives.activeUnits[event.initiator:getName()] == true then
							
							local coa = event.initiator:getCoalition()
							local bases = coalition.getAirbases(coa)
							local closestBase = bases[1]
							local distance
							local closestDistance = util.distance(event.initiator:getPoint(), closestBase:getPoint())
							local pid, playerID
				
							for k, v in next, bases do
								distance = util.distance(event.initiator:getPoint(), v:getPoint())
								if distance <= closestDistance then
									closestDistance = distance
									closestBase = v
								end
							end
							
							if closestDistance < 500 or (event.place ~= nil and event.place:getCoalition() == coa) then
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"You have landed at "..closestBase:getName(),5)
								lives.activeUnits[event.initiator:getName()] = false
							end
							
							if  lives.activeUnits[event.initiator:getName()] == false then
								if csar.heliPassengers[event.initiator:getName()]["n"] > 0 then
									for k, v in next, csar.heliPassengers[event.initiator:getName()] do
										if type(v) ~= "number" then
											if v.category == Group.Category.AIRPLANE then
												trigger.action.setUserFlag(tostring(v.playerID).."_lives_airplane",tonumber(trigger.misc.getUserFlag(v.playerID.."_lives_airplane")) - 1)
												trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Airplane life returned for: "..v.playerName,5)
												v:delete()
											elseif v.category == Group.Category.HELICOPTER then
												trigger.action.setUserFlag(tostring(v.playerID).."_lives_helicopter",tonumber(trigger.misc.getUserFlag(v.playerID.."_lives_helicopter")) - 1)		
												trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Helicopter life returned for: "..v.playerName,5)	
												v:delete()									
											end
										end
									end
									csar.heliPassengers[event.initiator:getName()] = {}
									csar.heliPassengers[event.initiator:getName()]["n"] = 0
								end
							end
							
							if unitExemption[event.initiator:getTypeName()] then
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"CSAR Chopper: no life modification.",5)
								return
							end
							
							for k, v in next, net.get_player_list() do
								if net.get_player_info(v , 'name') == event.initiator:getPlayerName() then
									pid = v
									break
								end
							end
							
							if event.initiator:getGroup():getCategory() == Group.Category.AIRPLANE then
								trigger.action.setUserFlag(tostring(pid).."_lives_airplane",tonumber(trigger.misc.getUserFlag(pid.."_lives_airplane")) - 1)
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Airplane life returned! Lives remaining: "..tostring( tonumber(trigger.misc.getUserFlag('lifeLimit_airplane')) - tonumber(trigger.misc.getUserFlag(pid.."_lives_airplane")) ),5)
							elseif event.initiator:getGroup():getCategory() == Group.Category.HELICOPTER then
								trigger.action.setUserFlag(tostring(pid).."_lives_helicopter",tonumber(trigger.misc.getUserFlag(pid.."_lives_helicopter")) - 1)
								trigger.action.outTextForGroup(event.initiator:getGroup():getID(),"Helicopter life returned! Lives remaining: "..tostring( tonumber(trigger.misc.getUserFlag('lifeLimit_helicopter')) - tonumber(trigger.misc.getUserFlag(pid.."_lives_helicopter")) ),5)
							end
						end
					
						--return csar
						return
					end
					----------------------------------------------	
				end
			end
		end
		--return old_onEvent(event)
	end


world.addEventHandler(YinkEventHandler)

trigger.action.outText("csar.lua loaded",10)
log.write("scripting", log.INFO, "csar.lua loaded")
