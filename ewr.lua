--[[
ewr script


todo:

]]--

ewr = {}
ewr.types                = {"55G6 EWR", "1L13 EWR","E-3A","E-2C","A-50","FPS-117"}
ewr.refreshTime         = 25
ewr.pictureLimit         = 5
ewr.closeTargetRadius     = 10000 --meters for god sight

local function round(num, numDecimalPlaces)

	if num == 0 then return 0 end
	
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

ewr.hasCommands = {}

ewr.EWRs 			= {}
ewr.EWRs.blue 		= {}
ewr.EWRs.red 		= {}
ewr.EWRs.neutral 	= {}
ewr.detectedUnits	= {}
ewr.autoDisplay		= {}
ewr.detectedUnits.red 	= {}
ewr.detectedUnits.blue	= {}
ewr.lastUpdateTime = 0

local function heading(unitName)

	local unit = Unit.getByName(unitName)
	local unitPos = unit:getPosition()
	local headingRad = math.atan2( unitPos.x.z, unitPos.x.x )
 
	if headingRad < 0 then headingRad = headingRad + 2 * math.pi end

	return headingRad * 180 / math.pi
end

local function unitConversionOutput(unitName,bearing,distance,altitude,dir,targetTypeName)
	
	local unit		= Unit.getByName(unitName)
	local altWord 	= ewr.hasCommands[unit:getGroup():getID()]
	local kmToMi 	= 0.6213711922
	local mToFt		= 3.28084
	
	if altWord == nil then altWord = "Imperial" end
	
	if altWord == "Metric" then
		return string.format("BRAA: %03.0f for %1.1f Km, Metrics %1.1f, %s, type %s",bearing,distance/1000,altitude/1000,dir,targetTypeName)
	elseif altWord == "Imperial" then
		if (altitude * mToFt) / 1000 < 1 then altWord = "Cherubs" altitude = altitude * 10 else altWord = "Angels" end
		return string.format("BRAA: %03.0f for %1.1f Miles, "..altWord.." %1.1f, %s, type %s",bearing,(distance/1000) * kmToMi, (altitude * mToFt) / 1000, dir, targetTypeName)
	end
end

function ewr.getEWRs(coalitionValue)
	
	local groundTable = coalition.getGroups(coalitionValue, Group.Category.GROUND)
	local awacsTable = coalition.getGroups(coalitionValue, Group.Category.AIRPLANE)
	local ewrTable, unitTable = {}, {}
	
	for keyG, group in next, groundTable do
		unitTable = group:getUnits()
		for keyU, unit in next, unitTable do
			for _, ewrTypeName in next, ewr.types do
				if unit:getTypeName() == ewrTypeName then
					table.insert(ewrTable, unit:getName())
				end
			end			
		end		
	end
	
	for keyG, group in next, awacsTable do
		unitTable = group:getUnits()
		for keyU, unit in next, unitTable do
			for _, ewrTypeName in next, ewr.types do
				if unit:getTypeName() == ewrTypeName then
					table.insert(ewrTable, unit:getName())
				end
			end			
		end		
	end
	
	return ewrTable
end

function ewr.getDetectedObjects(ewrName)
	
	local unit 			= Unit.getByName(ewrName)
	local group			= unit:getGroup()
	local controller	= group:getController()
	local targetTable	= controller:getDetectedTargets()
	ewr.lastUpdateTime	= math.ceil(timer.getTime())

	return targetTable
end

function ewr.returnLastUpdateTime()
	local lastUpdateTime = math.abs(math.ceil(timer.getTime() - ewr.lastUpdateTime))
	if lastUpdateTime < 1 then
		return "CURRENT PICTURE\n"
	else
		return "Last Update: " .. tostring(lastUpdateTime) .. " seconds.\n"
	end
end


function ewr.compileDetectedUnits(ewrList)

	local ewrObject
	local detectedUnitList,unitTable = {},{}
	
	for _, ewrName in next, ewrList do
		if Unit.getByName(ewrName) ~= nil then
			for unitKey, unitValues in next, ewr.getDetectedObjects(ewrName) do
				if unitValues.object ~= nil then
					if unitValues.object:inAir() and unitValues.object:getDesc().category == Unit.Category.AIRPLANE then
						unitTable = unitValues
						unitTable["position"] = unitTable.object:getPosition()
						detectedUnitList[unitValues.object:getName()] = unitTable
					end
				end
			end
		end
	end
	
	return detectedUnitList

end


function ewr.getTargetListFromUnit(unitName)

	local unit = Unit.getByName(unitName)
	local coa = unit:getCoalition()
	local targetList,nonSortedList = {}, {}
	
	if coa == coalition.side.RED then
		targetList = ewr.detectedUnits.red
	elseif coa == coalition.side.BLUE then
		targetList = ewr.detectedUnits.blue
	end
	
	for k, v in pairs(targetList) do
		if v.object ~= nil then
			if v.object:isExist() then
				table.insert(nonSortedList, {v.object:getName(), ewr.distance2(unit:getPoint() , v.position.p), math.deg(math.atan2(v.position.x.z, v.position.x.x)+2*math.pi)})
			end
		end
	end

	return nonSortedList
end

function ewr.sortTargetListFromUnit(unitName)

	local unit = Unit.getByName(unitName)
	local coa = unit:getCoalition()
	local targetList,sortedList = {}, {}
	
	if coa == coalition.side.RED then
		targetList = ewr.detectedUnits.red
	elseif coa == coalition.side.BLUE then
		targetList = ewr.detectedUnits.blue
	end
	
	for k, v in pairs(targetList) do
		if v.object:isExist() and v.object ~= nil then
			table.insert(sortedList, {v.object:getName(), ewr.distance2(unit:getPoint() , v.position.p), math.deg(math.atan2(v.position.x.z, v.position.x.x)+2*math.pi)})
		end
	end
	
	table.sort(sortedList, function (a, b) return a[2] < b[2] end)

	return sortedList
end

function ewr.getCloseTargetsFromUnit(unitName)
	local foundUnits = {}
	local unit = Unit.getByName(unitName)

	if unit == nil then
		return
	end

	if not unit:isExist() then
		return
	end
	local volS = {
	  id = world.VolumeType.SPHERE,
	  params = {
		point = unit:getPoint(),
		radius = ewr.closeTargetRadius
	  }
	}
	
	local ifFound = function(foundItem)
		if foundItem:getCoalition() ~= unit:getCoalition() and foundItem:getDesc().category == Unit.Category.AIRPLANE then
			table.insert(foundUnits,foundItem)
			return true
		end
	end

	world.searchObjects(Object.Category.UNIT, volS, ifFound)

	local sortedList = {}
	
	for k, v in pairs(foundUnits) do
		if v ~= nil then
			if v:isExist() then
				table.insert(sortedList, {v:getName(), ewr.distance2(unit:getPoint() , v:getPoint()), math.deg(math.atan2(v:getPosition().x.z, v:getPosition().x.x)+2*math.pi)})
			end
		end
	end

	return sortedList
end

function ewr.sortFriendlyListFromUnit(unitName)

	local unit = Unit.getByName(unitName)
	local coa = unit:getCoalition()
	local targetList,sortedList, unitTable = {}, {}, {}
	
	if coa == coalition.side.RED then
		for i1,group in next, coalition.getGroups(1 , 0) do
			for i2, unit in next, group:getUnits() do
				if unit:getName() ~= unitName then
					unitTable = {}
					unitTable.object = unit
					unitTable.position = unit:getPosition()
					targetList[unit:getName()] = unitTable
				end
			end
		end
	elseif coa == coalition.side.BLUE then
		for i1,group in next, coalition.getGroups(2 , 0) do
			for i2, unit in next, group:getUnits() do
				if unit:getName() ~= unitName then
					unitTable = {}
					unitTable.object = unit 
					unitTable.position = unit:getPosition()
					targetList[unit:getName()] = unitTable
				end
			end
		end
	end
	
	for k, v in pairs(targetList) do
		if v.object:isExist() and v.object ~= nil then
			table.insert(sortedList, {v.object:getName(), ewr.distance2(unit:getPoint() , v.position.p), math.deg(math.atan2(v.position.x.z, v.position.x.x)+2*math.pi)})
		end
	end
	
	table.sort(sortedList, function (a, b) return a[2] < b[2] end)

	return sortedList
end


function ewr.directionDefines(dir) --still working this out
	
	--trigger.action.outText(tostring(dir),5)
	
	if dir < 0 then
		dir = 360 + dir
	end
	
	--trigger.action.outText(tostring(dir),5)
	
	if dir >= 135 and dir < 225 then
		return "Hot"
	elseif dir >= 45 and dir < 135 then
		return "Flank Left"
	elseif (dir >= 0 and dir < 45) or dir >= 315 and dir < 360 then
		return "Cold"
	elseif dir >= 225 and dir < 315 then
		return "Flank Right"
	end
	
	return tostring(dir)
end

function ewr.bogeyDope(unitName)
	
	local ewrList = ewr.getTargetListFromUnit(unitName)
	local closeList = ewr.getCloseTargetsFromUnit(unitName)
	local list = ewr.combineLists({ewrList,closeList})
	local unit = Unit.getByName(unitName)

	if #list <= 0 then
		trigger.action.outTextForUnit(unit:getID(), "No targets detected.", 10, true)
		return
	end
	local target, dir = Unit.getByName(list[1][1]), ""
	local bearing = ewr.bearingUnit(unit,target)
	local altitude = target:getPoint().y
	local distance = list[1][2]
	local direction = bearing - heading(target:getName())
	local dir = ewr.directionDefines(direction)
	local output = ewr.returnLastUpdateTime() .. unitConversionOutput(unitName,bearing,distance,altitude,dir,target:getTypeName())
	trigger.action.outTextForUnit(unit:getID(), output, 10, true)

	return
end

function ewr.picture(unitName)
	local output = ewr.returnLastUpdateTime() .. "Picture:\n"
	local ewrList = ewr.getTargetListFromUnit(unitName)
	local closeList = ewr.getCloseTargetsFromUnit(unitName)
	local list = ewr.combineLists({ewrList,closeList})
	local unit = Unit.getByName(unitName)

	local counter = 0
	if #list <= 0 then
		trigger.action.outTextForUnit(unit:getID(), "No targets detected.", 10, true)
		return
	end
	
	for k, v in pairs(list) do
		if counter >= ewr.pictureLimit then break end
		local target, dir = Unit.getByName(v[1]), ""
		if target:getDesc().category == 0 then
			local bearing = ewr.bearingUnit(unit,target)
			local altitude = target:getPoint().y
			local distance = v[2]
			local direction =  bearing - heading(target:getName())
			local dir = ewr.directionDefines(direction)
			output = output .. unitConversionOutput(unitName,bearing,distance,altitude,dir,target:getTypeName()) .. "\n"
			counter = counter + 1
		end
	end
	
	trigger.action.outTextForUnit(unit:getID(), output, 10, true)

	return
end

function ewr.combineLists(listList)

	local sortedList = {}
	local alreadyAdded = {}

	for i,list in next, listList do
		for k, v in pairs(list) do
			if alreadyAdded[v[1]] ~= true then
				table.insert(sortedList, v)
				alreadyAdded[v[1]] = true
			end
		end
	end

	table.sort(sortedList, function (a, b) return a[2] < b[2] end)

	return sortedList
end

function ewr.friendlyPicture(unitName)
	local output = "Friendly Picture:\n"
	local list = ewr.sortFriendlyListFromUnit(unitName)
	local unit = Unit.getByName(unitName)
	local counter = 0
	if #list <= 0 then
		trigger.action.outTextForUnit(unit:getID(), "No targets detected.", 10, true)
		return
	end
	
	for k, v in pairs(list) do
		if counter >= ewr.pictureLimit then break end
		local target, dir = Unit.getByName(v[1]), ""
		local bearing = ewr.bearingUnit(unit,target)
		local altitude = target:getPoint().y
		local distance = v[2]
		local direction = bearing - heading(target:getName())
		local dir = ewr.directionDefines(direction)
		local playerName = ", callsign " .. tostring(target:getPlayerName())
		if playerName ~= ", callsign nil" then
			output = output .. unitConversionOutput(unitName,bearing,distance,altitude,dir,target:getTypeName()) .. playerName .. "\n"
			counter = counter + 1
		end
	end
	
	trigger.action.outTextForUnit(unit:getID(), output, 10, true)

	return
end


function ewr.intercept(unitName)

	if not ewr.intercepting[unitName] then return end
	
	local list = ewr.sortTargetListFromUnit(unitName)
	local unit = Unit.getByName(unitName)
	if #list <= 0 then
		return
	end
	local target, dir, t = Unit.getByName(list[1][1]), "", 0
	local bearing = ewr.bearingUnit(unit,target)
	local altitude = target:getPoint().y
	local speed = speed(target)
	local distance = list[1][2]
	local direction = heading(target:getName()) - bearing
	dir = ewr.directionDefines(direction)
	
	local a = ((speed(unit)^2) - ((speed(target)^2))) 
	local b = 2 * distance * speed * math.cos(direction)
	local c = -1 * distance^2
	
	local t1 = ((-b + math.sqrt(b^2 - (4 * a * c)))/(2 * a)) or -1
	local t2 = ((-b - math.sqrt(b^2 - (4 * a * c)))/(2 * a)) or -1
	
	local x = math.sin(direction) * (speed * t)
	
	local interceptAngle = math.asin(x/(speed(unit) * t))
	
	--schdule this: ewr.intercept(unitName)
end

function ewr.loop (args, time)
	
	ewr.EWRs.red			= ewr.getEWRs(coalition.side.RED)
	ewr.EWRs.blue			= ewr.getEWRs(coalition.side.BLUE)
	
	ewr.detectedUnits.red  	= ewr.compileDetectedUnits(ewr.EWRs.red)
	ewr.detectedUnits.blue  = ewr.compileDetectedUnits(ewr.EWRs.blue)
	
	for unitName, isOn in next, ewr.autoDisplay do
		if isOn then
			local unit = Unit.getByName(unitName)
			if unit ~= nil then
				if unit:isExist() then
					ewr.picture(unitName)
				end
			end
		end
	end

	return time + ewr.refreshTime
end

timer.scheduleFunction(ewr.loop, "" , timer.getTime() + 1)

function ewr.distance( unit1 , unit2) --use z instead of y for getPoint()
	
		local x1 = unit1:getPoint().x
		local y1 = unit1:getPoint().z
		local x2 = unit2:getPoint().x
		local y2 = unit2:getPoint().z

	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

function ewr.distance2(point1 , point2) --use z instead of y for getPoint()
	
		local x1 = point1.x
		local y1 = point1.z
		local x2 = point2.x
		local y2 = point2.z

	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end

function ewr.swapDistanceUnits(unitName)
	
	local unit = Unit.getByName(unitName)
	
	if ewr.hasCommands[unit:getGroup():getID()] == "Metric" then	
		ewr.hasCommands[unit:getGroup():getID()] = "Imperial"
	elseif ewr.hasCommands[unit:getGroup():getID()] == "Imperial" then	
		ewr.hasCommands[unit:getGroup():getID()] = "Metric"
	end
	trigger.action.outTextForUnit(unit:getID() , "New distance units: " .. tostring(ewr.hasCommands[unit:getGroup():getID()]), 5)
end

function ewr.bearing(vec3A, vec3B)
	local azimuth = math.atan2(vec3B.z - vec3A.z, vec3B.x - vec3A.x)
	return azimuth<0 and math.deg(azimuth+2*math.pi) or math.deg(azimuth)
end

function ewr.bearingUnit(unitA, unitB)
	local bearing = ewr.bearing(unitA:getPoint(),unitB:getPoint())
	bearing = round((bearing / 10), 1) * 10
	
	return bearing
end

function ewr.toggleAutoDisplay(unitName)
	local unit = Unit.getByName(unitName)
	if ewr.autoDisplay[unitName] ~= true then
		ewr.autoDisplay[unitName] = true
	else
		ewr.autoDisplay[unitName] = false
	end
	trigger.action.outTextForUnit(unit:getID() , "EWR Auto Display state: " .. tostring(ewr.autoDisplay[unitName]), 5)
end

local function speed(unit)
	local vec3 = unit:getVelocity()
	local speed = math.sqrt((vec3.x^2) + (vec3.y^2) + (vec3.z^2))
	return speed
end

ewrEventHandler = {} --event handlers

function ewrEventHandler:onEvent(event)

	if world.event.S_EVENT_BIRTH == event.id then
		if event.initiator.getPlayerName == nil then return end
		ewr.autoDisplay[event.initiator:getName()] = false
		if ewr.hasCommands[event.initiator:getGroup():getID()] == nil then
			local subMenu = missionCommands.addSubMenuForGroup(event.initiator:getGroup():getID() , "EWR System" )
			missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Bogey Dope" , subMenu , ewr.bogeyDope , event.initiator:getName())
			missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Request Picture" , subMenu , ewr.picture , event.initiator:getName())
			missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Request Friendly Picture" , subMenu , ewr.friendlyPicture , event.initiator:getName())
			missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Swap Distance Units" , subMenu , ewr.swapDistanceUnits , event.initiator:getName())
			missionCommands.addCommandForGroup(event.initiator:getGroup():getID() , "Toggle Auto Display" , subMenu , ewr.toggleAutoDisplay , event.initiator:getName())
			local units
			if event.initiator:getCoalition() == 1 then units = "Metric" else units = "Imperial" end
			ewr.hasCommands[event.initiator:getGroup():getID()] = units
		end
		trigger.action.outTextForUnit(event.initiator:getID() , "Yink's Edubs System Loaded.\nCurrent distance units: " .. tostring(ewr.hasCommands[event.initiator:getGroup():getID()]), 15)
	end
	
end

world.addEventHandler(ewrEventHandler)

trigger.action.outText("Yink's Edubs System Loaded",20)
log.write("ewr.lua", log.INFO, "Yink's Edubs System Loaded")
