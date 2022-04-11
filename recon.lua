
local recon = {}
local util = {}

recon.reconTypes = {}

recon.reconTypes["MiG-21Bis"] = true
recon.reconTypes["AJS37"] = true

recon.duration = 12
recon.detectedTargets = {}
recon.radius = 1000
recon.minAlt = 500
recon.maxAlt = 5000

recon.parameters = {}
recon.parameters["MiG-21Bis"] = {}
recon.parameters["MiG-21Bis"].minAlt 	= 500
recon.parameters["MiG-21Bis"].maxAlt 	= 5000
recon.parameters["MiG-21Bis"].fov		= 32
recon.parameters["MiG-21Bis"].duration	= 15
recon.parameters["MiG-21Bis"].offset	= math.rad(10)
recon.parameters["MiG-21Bis"].name	= "MiG-21R"


recon.parameters["AJS37"] = {}
recon.parameters["AJS37"].minAlt 	= 50
recon.parameters["AJS37"].maxAlt 	= 600
recon.parameters["AJS37"].fov		= 60
recon.parameters["AJS37"].duration	= 20
recon.parameters["AJS37"].offset	= math.rad(70)
recon.parameters["AJS37"].name	= "SF 37"

------------------------------------------------------------------------------------------------------------------------util Definitions


function util.offsetCalc(object)
	local rad = (math.atan2(object:getPosition().x.z, object:getPosition().x.x)+2*math.pi)	
	local MSL = land.getHeight({x = object:getPoint().x,y = object:getPoint().z })
	local altitude = object:getPoint().y - MSL
	local distance = math.tan(recon.parameters[object:getTypeName()].offset) * altitude
	
	local x = object:getPoint().x + ((math.cos(rad) * distance ))
	local y = object:getPoint().z + (math.sin(rad) * distance )
				
				--trigger.action.outText(tostring( distance ),5)
				--trigger.action.outText(tostring((math.cos(rad) * distance )),5)
				--trigger.action.outText(tostring((math.sin(rad) * distance )),5)
	
	return {x = x, z = y}
end

function util.round(num, numDecimalPlaces)

	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

-----------------------------------------------------------------------------------------------------------------recon object Definitions
reconInstance = {}
recon.instances = {}

recon.marks = {}
recon.redMarkCount = 15000
recon.blueMarkCount = 16000
recon.marks.blue = {}
recon.marks.red = {}

function reconInstance:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function recon.createInstance(object)
	local instance = reconInstance:new()
	instance:setObjectParams(object)
	recon.instances[instance.objectName] = instance
	return instance
end

function reconInstance:setObjectParams(object)
	self.object = object
	self.point = object:getPoint()
	self.coa = object:getCoalition()
	self.type = object:getTypeName()
	self.group = object:getGroup()
	self.groupID = object:getGroup():getID()
	self.objectName = object:getName()
	self.playerName = object:getPlayerName()
	self.category = object:getGroup():getCategory()
	self.ammo = object:getAmmo()
	self.time = timer.getTime()
	self.exists = true
	self.capturing = false
	self.duration = recon.parameters[self.type].duration
	self.targetList = {}
	
	for k, v in next, net.get_player_list() do
		if net.get_player_info(v , 'name') == self.playerName then
			self.playerID = v
			break
		end
	end
	return self
end

function recon.findTargets(instance)
	
	local MSL = land.getHeight({x = instance.object:getPoint().x,y = instance.object:getPoint().z })
	
	local altitude = instance.object:getPoint().y - MSL
	
	local minAlt 	= recon.parameters[instance.type].minAlt
	local maxAlt 	= recon.parameters[instance.type].maxAlt
	local fov		= recon.parameters[instance.type].fov
	
	local radiusCalculated = altitude * math.tan(math.rad(fov))
	local offset = util.offsetCalc(instance.object)
	local volume = {
		id = world.VolumeType.SPHERE,
		params = {
			point = {x = offset.x, y = MSL, z = offset.z},
			radius = radiusCalculated
		}
	}
	local targetList = {}
	local ifFound = function(foundItem)
		if foundItem:getGroup():getCategory() == 2 and foundItem:getCoalition() ~= instance.coa then--and string.sub(foundItem:getName(),1,6) == "Sector" then
			targetList[foundItem:getName()] = foundItem
			--trigger.action.smoke(foundItem:getPoint(), 1)
			--trigger.action.outText(tostring(foundItem:getName()),6)
			return true
		end
	end
	
	if altitude > minAlt and altitude < maxAlt then
		world.searchObjects(Object.Category.UNIT , volume , ifFound)
		return targetList
	end
	return {}
end

function reconInstance:setCommandIndex(index)
	self.index = index
end

function reconInstance:checkNil()
	if self.object ~= nil then
		return self.object
	else
		recon.instances[self.objectName] = nil
		return nil
	end
end

function reconInstance:addToTargetList(list)
	
	for k, v in next, list do
		if self.targetList ~= nil then
			if self.targetList[k] == nil then
				--trigger.action.outText(v:getName(),5)
				self.targetList[k] = v
			end
		end
	end
end

function reconInstance:returnReconTargets()
	
	for k,v in next, self.targetList do
		if v == nil then
			self.targetList[k] = nil
		else
			if recon.detectedTargets[v:getName()] == nil then
				recon.outMarkTable[self.coa](v)
			end
		end
	end
	return
end

function recon.redOutMark(unit)
	if unit == nil then return end
	local lat,lon,alt = coord.LOtoLL(unit:getPoint())
	local temp,pressure = atmosphere.getTemperatureAndPressure(unit:getPoint())
	local outString = tostring(util.round(lat,4))..", " .. tostring(util.round(lon,4)) .." | ".. tostring(util.round((29.92 * (pressure/100) / 1013.25) * 25.4,2)) .."\nTYPE: " .. unit:getTypeName()
	trigger.action.markToCoalition(recon.redMarkCount, outString , unit:getPoint() , 1 , false)
	recon.marks.red[unit:getName()] = recon.redMarkCount
	recon.redMarkCount = recon.redMarkCount + 1
	return recon.redMarkCount - 1
end

function recon.blueOutMark(unit)
	if unit == nil then return end
	local lat,lon,alt = coord.LOtoLL(unit:getPoint())
	local temp,pressure = atmosphere.getTemperatureAndPressure(unit:getPoint())
	local outString = tostring(util.round(lat,4))..", " .. tostring(util.round(lon,4)) .." | ".. tostring(util.round(pressure/100,2)) .." " .. tostring(util.round(29.92 * (pressure/100) / 1013.25,2)) .."\nTYPE: " .. unit:getTypeName()
	trigger.action.markToCoalition(recon.blueMarkCount, outString , unit:getPoint() , 2 , false)
	recon.marks.blue[unit:getName()] = recon.blueMarkCount
	recon.blueMarkCount = recon.blueMarkCount + 1
	return recon.blueMarkCount - 1
end

recon.outMarkTable = { [1] = recon.redOutMark, [2] = recon.blueOutMark }

function recon.getInstance(unitName)
	if recon.instances[unitName] ~= nil then
		if recon.instances[unitName].object ~= nil then
			return recon.instances[unitName]
		else
			reconInstance[unitName] = nil
			return nil
		end
	else
		return nil
	end
end


function recon.captureData(instance)

	if instance.capturing and instance.duration > 0 then
		instance.duration = instance.duration - 0.5
		trigger.action.outTextForGroup(instance.groupID,"CAPTURE TIME: " .. tostring(instance.duration),1)--,true)

		instance:addToTargetList(recon.findTargets(instance))
		timer.scheduleFunction(recon.captureData, instance, timer.getTime() + 0.5)
		
	end
	if instance.duration <= 0 and instance.loop then
		instance.loop = false
		trigger.action.outTextForGroup(instance.groupID,"ERROR: NO FILM",5,true)
		
		instance:returnReconTargets()
		
		instance.capturing = false
		trigger.action.outTextForGroup(instance.groupID,"RECON MODE DISABLED ",5)
		missionCommands.removeItemForGroup(instance.groupID,instance.index)
		local index = missionCommands.addCommandForGroup(instance.groupID , "ENABLE RECON MODE" , nil , recon.control , instance)
		instance.capturing = false
		instance:setCommandIndex(index)
	end
	
	return
end

function reconInstance:captureData()
	
	if self.duration == 0 then
		trigger.action.outTextForGroup(self.groupID,"ERROR: NO FILM",2)
		return
	else
		self.capturing = true
	end
	
	if self.capturing and self.duration > 0 then
		self.loop = true
		trigger.action.outTextForGroup(self.groupID,"UNCAGING | TIME REMAINING: " .. tostring(self.duration),1)
		missionCommands.removeItemForGroup(self.groupID,self.index)
		local index = missionCommands.addCommandForGroup(self.groupID , "DISABLE RECON MODE" , nil , recon.control , self)
		self:setCommandIndex(index)
		timer.scheduleFunction(recon.captureData, self, timer.getTime() + 2)
	end
	return
end


------------------------------------------------------------------------------------------------------------------------command Definitions



------------------------------------------------------------------------------------------------------------------------function Definitions

function recon.checkIfRecon(unit)			
	if recon.reconTypes[unit:getTypeName()] then
		if unit:getAmmo() == nil then
			return true
		else
			return false
		end
	else
		return false
	end
end

function recon.control(instance)

	if not instance.capturing then
		instance:captureData()
		return 
	end

	if instance.capturing then
		instance.capturing = false
		trigger.action.outTextForGroup(instance.groupID,"RECON MODE DISABLED ",2)
		missionCommands.removeItemForGroup(instance.groupID,instance.index)
		local index = missionCommands.addCommandForGroup(instance.groupID , "ENABLE RECON MODE" , nil , recon.control , instance)
		instance.capturing = false
		instance:setCommandIndex(index)
	end

	return
end

------------------------------------------------------------------------------------------------------------------------Event Handler Definitions

local reconEventHandler = {}

function reconEventHandler:onEvent(event)	

	if world.event.S_EVENT_BIRTH == event.id then
		return
	end
	
	if world.event.S_EVENT_DEAD == event.id then
		return
	end
	
	if world.event.S_EVENT_TAKEOFF == event.id then
		local instance
		if recon.reconTypes[event.initiator:getTypeName()] then
			
			--trigger.action.outText("in recon valid table",20)
			if recon.instances[event.initiator:getName()] ~= nil then
			
				instance = recon.getInstance(event.initiator:getName())
				--trigger.action.outText("in instance table",20)
				
				missionCommands.removeItemForGroup(event.initiator:getGroup():getID(),instance.index)
				instance:setObjectParams(event.initiator)
			else
				--trigger.action.outText("not in instance table",20)
				instance = recon.createInstance(event.initiator)
			end
			
			if recon.checkIfRecon(event.initiator) then
				trigger.action.outTextForGroup(instance.groupID,"Valid "..recon.parameters[event.initiator:getTypeName()].name.." reconnaissance flight.",20)
				local index = missionCommands.addCommandForGroup(instance.groupID , "ENABLE RECON MODE" , nil , recon.control , instance)
				instance.capturing = false
				instance:setCommandIndex(index)
			end
		end	
		return
	end

end

world.addEventHandler(reconEventHandler)
