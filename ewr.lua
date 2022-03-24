--[[
ewr script


todo:

add imperial unit option
age out targets?
modify unit table to include time and such? (getDetectedTargets, ewr.sortTargetListFromUnit)
]]--

ewr = {}

ewr.types 			= {"55G6 EWR", "1L13 EWR"}
ewr.EWRs 			= {}
ewr.EWRs.blue 		= {}
ewr.EWRs.red 		= {}
ewr.EWRs.neutral 	= {}
ewr.detectedUnits	= {}

ewr.detectedUnits.red 	= {}
ewr.detectedUnits.blue	= {}


function ewr.getEWRs(coalitionValue)
	
	local groupTable = coalition.getGroups(coalitionValue, Group.Category.GROUND)
	local ewrTable, unitTable = {}
	
	for keyG, group in next, groupTable do
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

	return targetTable
end

function ewr.compileDetectedUnits(ewrList)

	local ewrObject
	local detectedUnitList = {}
	
	for _, ewrName in next, ewrList do
		if Unit.getByName(ewrName) ~= nil then
			for unitKey, unitValues in next, ewr.getDetectedObjects(ewrName) do
				detectedUnitList[unitValues.object:getName()] = unitValues
			end
		end
	end
	
	return detectedUnitList

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
		table.insert(sortedList, {v.object:getName(), ewr.distance(unit, v.object)})
	end
	
	table.sort(sortedList, function (a, b) return a[2] < b[2] end)

	return sortedList
end

function ewr.directionDefines(dir) --still working this out
	
	if dir < 0 then
		dir = 360 + dir
	end
	
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
	
	local list = ewr.sortTargetListFromUnit(unitName)
	local unit = Unit.getByName(unitName)
	if #list <= 0 then
		return
	end
	local target, dir = Unit.getByName(list[1][1]), ""
	local bearing = ewr.bearingUnit(unit,target)
	local altitude = target:getPoint().y
	local distance = list[1][2]
	local direction = bearing - math.deg(math.atan2(target:getPosition().x.z, target:getPosition().x.x)+2*math.pi)
	dir = ewr.directionDefines(direction)
	
	output = string.format("BRA: %03.0f for %1.1f, Metrics %d %s, type %s",bearing,distance/1000,altitude/1000,dir,target:getTypeName())
	
	trigger.action.outText(output,5)

	return
end

function ewr.picture(unitName)
	local ouput = "Picture:\n"
	local list = ewr.sortTargetListFromUnit(unitName)
	local unit = Unit.getByName(unitName)
	if #list <= 0 then
		return
	end
	
	for k, v in pairs(list) do
		local target, dir = Unit.getByName(v[1]), ""
		local bearing = ewr.bearingUnit(unit,target)
		local altitude = target:getPoint().y
		local distance = v[2]
		local direction = bearing - math.deg(math.atan2(target:getPosition().x.z, target:getPosition().x.x)+2*math.pi)
		local dir = ewr.directionDefines(direction)
		output = output + string.format("%s: %03.0f for %1.1f, Metrics %d %s \n",target:getTypeName(),bearing,distance/1000,altitude/1000,dir)
	end
	
	trigger.action.outText(output,20)

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
	local direction = bearing - math.deg(math.atan2(target:getPosition().x.z, target:getPosition().x.x)+2*math.pi)
	dir = ewr.directionDefines(direction)
	
	local a = ((speed(unit)^2) - ((speed(target)^2))
	local b = 2 * distance * speed * math.cos(direction)
	local c = -1 * distance^2
	
	local t1 = (-b + math.sqrt(b^2 - (4 * a * c)))/(2 * a) or -1
	local t2 = (-b - math.sqrt(b^2 - (4 * a * c)))/(2 * a) or -1
	
	local x = math.sin(direction) * (speed * t)
	
	local interceptAngle = math.asin(x/(speed(unit) * t))
	
	--schdule this: ewr.intercept(unitName)
end

function ewr.loop (args, time)
	
	ewr.EWRs.red			= ewr.getEWRs(coalition.side.RED)
	ewr.EWRs.blue			= ewr.getEWRs(coalition.side.BLUE)
	
	ewr.detectedUnits.red  	= ewr.compileDetectedUnits(ewr.EWRs.red)
	ewr.detectedUnits.blue  = ewr.compileDetectedUnits(ewr.EWRs.blue)
	
	 ewr.bogeyDope("testUnit")
	
	return time + 5
end

timer.scheduleFunction(ewr.loop, "" , timer.getTime() + 1)



function ewr.distance( unit1 , unit2) --use z instead of y for getPoint()
	
		local x1 = unit1:getPoint().x
		local y1 = unit1:getPoint().z
		local x2 = unit2:getPoint().x
		local y2 = unit2:getPoint().z

	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 )
end



function ewr.bearing(vec3A, vec3B)
	local azimuth = math.atan2(vec3B.z - vec3A.z, vec3B.x - vec3A.x)
	return azimuth<0 and math.deg(azimuth+2*math.pi) or math.deg(azimuth)
end

function ewr.bearingUnit(unitA, unitB)
	return ewr.bearing(unitA:getPoint(),unitB:getPoint())
end

local function speed(unit)
	local vec3 = unit:getVelocity()
	local speed = math.sqrt((vec3.x^2) + (vec3.y^2) + (vec3.z^2))
	return speed
end