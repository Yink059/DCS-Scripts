--dynamic mission editor


----------------------------------------------------------------------------------------------------------------  object definitions

missionObject = {}

dme = {}
dme.instances = {}

function missionObject:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function dme.createInstance(missionName)
	local instance = missionObject:new()
	instance:sourceFile(missionName)
	dme.instances[missionName] = instance
	return instance
end

function missionObject:sourceFile(filename)
	self.sourceFile = filename
	self.mission = dme.returnMissionTemplate(filename)
	
	self.returnFiles = {}
	self.returnFiles["mission"] = self.mission
	self.returnFiles["dictionary"] = false
	self.returnFiles["mapResource"] = false
	self.returnFiles["options"] = false
	self.returnFiles["theatre"] = false
	self.returnFiles["warehouses"] = false
end


function dme.writeMissionTemplateToFile(templateMission,fileToWrite)
	
	local missionString = dme.serializeWithCycles("mission", templateMission)
	
	local vm = "start cmd /c C:\\source\\7z.exe e -y "..fileToWrite.." -oC:\\export"
	os.execute(vm)
	dme.sleep(1)
	local f = assert(io.open("C:\\export\\mission", "w"))
	f:write(missionString)
	f:close()
	vm = "start cmd /c C:\\source\\7z.exe a "..fileToWrite.. " C:\\\\export\\\\"
	os.execute(vm)
end

function missionObject:writeMissionTemplateToFile(fileToWrite)
	
	local vm = "start cmd /c C:\\source\\7z.exe e -y ".. self.sourceFile .." -oC:\\export"
	os.execute(vm)
	dme.sleep(1)
	
	for fileName, fileValue in next, self.returnFiles do
		if fileValue ~= false then
			local f = assert(io.open("C:\\export\\" .. fileName, "w"))
			f:write(dme.serializeWithCycles(fileName, fileValue))
			f:close()
		end
	end
	
	vm = "start cmd /c C:\\source\\7z.exe a "..fileToWrite.. " C:\\\\export\\\\"
	os.execute(vm)
end

function dme.returnMissionTemplate(filename)

	local vm = "start cmd /c C:\\source\\7z.exe e -y "..filename.." -oC:\\export"
	os.execute(vm)
	dme.sleep(1)
	local f = io.open("C:\\export\\mission","r")
	local s = f:read("*all")
	f:close()
	s = "local " .. s .. "\ndme_mission = mission"
	if loadstring then
		loadstring(s)()
	else
		load(s)()
	end
	
	return dme_mission
end

function missionObject:getWeatherFromTemplate(filename)

	local missionTemplate = dme.returnMissionTemplate(filename)
	self.mission.weather = missionTemplate.weather
	return self.mission.weather
end

function missionObject:getRestrictionsFromTemplate(filename)
	return
end

function missionObject:getDifficultyFromTemplate(filename)
	return
end

----------------------------------------------------------------------------------------------------------------  restriction definitions

function dme.loadWeaponTemplates(filename)
	
	local missionTemplate = dme.returnMissionTemplate(filename)
	
	local weaponTemplates = {}
	
	for coalition, coaTable in next, missionTemplate.coalition do
		weaponTemplates[coalition] = {}
		
		for countries, countryTable in coaTable.country do
			
			for groupKey, groupValue in next, countryTable.plane.group do
			
				for unitKey, unitTables in next, groupValue do
					print(tostring(unitKey))
				end
				
			end
			
		end
	
	end
	
	return weaponTemplates
end

----------------------------------------------------------------------------------------------------------------  date definitions

function missionObject:setDay(day)
	if type(day) == "number" then self.mission.date["Day"] = day return true end
	return false
end

function missionObject:setMonth(month)
	if type(month) == "number" then self.mission.date["Month"] = month return true end
	return false
end

function missionObject:setYear(year)
	if type(year) == "number" then self.mission.date["Year"] = year return true end
	return false
end


----------------------------------------------------------------------------------------------------------------  time definitions

function missionObject:setTime(time)
	if type(time) == "number" then self.mission.start_time = time return true end
	return false
end

----------------------------------------------------------------------------------------------------------------  weather definitions

function missionObject:setTemperature(temp)
	if type(temp) == "number" then self.mission.weather.season.temperature = temp return true end
	return false
end

function missionObject:setQNH(qnh)
	if type(qnh) == "number" then self.mission.weather.qnh = qnh return true end
	return false
end

function missionObject:setGroundTurbulence(gt)
	if type(gt) == "number" then self.mission.weather.groundTurbulence = gt return true end
	return false
end

function missionObject:setDustDensity(dd)
	if type(dd) == "number" then self.mission.weather.dust_density = dd return true end
	return false
end

function missionObject:setWindAt2000(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.mission.weather.wind["at2000"]["dir"] = dir self.mission.weather.wind["at2000"]["speed"] = speed return true end
	return false
end

function missionObject:setWindAtGround(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.mission.weather.wind["atGround"]["dir"] = dir self.mission.weather.wind["atGround"]["speed"] = speed return true end
	return false
end

function missionObject:setWindAt8000(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.mission.weather.wind["at8000"]["dir"] = dir self.mission.weather.wind["at8000"]["speed"] = speed return true end
	return false
end

function missionObject:setFogEnable(fog)
	if type(fog) == "boolean" then self.mission.weather.wind.enable_fog = fog return true end
	return false
end

function missionObject:setFogVisibility(fog)
	if type(fog) == "number" then self.mission.weather.wind.fog.visibility = fog return true end
	return false
end

function missionObject:setFogVisibility(fog)
	if type(fog) == "number" then self.mission.weather.wind.fog.visibility = fog return true end
	return false
end

function missionObject:setFogThickness(fog)
	if type(fog) == "number" then self.mission.weather.wind.fog.thickness = fog return true end
	return false
end

function missionObject:setAtmosphereType(atm)
	if type(atm) == "number" then self.mission.weather["atmosphere_type"] = atm return true end
	return false
end

function missionObject:setCloudsPreset(cloud)
	if type(cloud) == "string" then self.mission.weather.clouds.preset = cloud return true end
	return false
end

function missionObject:setCloudsDensity(cloud)
	if type(cloud) == "number" then self.mission.weather.clouds.density = cloud return true end
	return false
end

function missionObject:setCloudsIprecptns(cloud)
	if type(cloud) == "number" then self.mission.weather.clouds.iprecptns = cloud return true end
	return false
end

function missionObject:setCloudsThickness(cloud)
	if type(cloud) == "number" then self.mission.weather.clouds.thickness = cloud return true end
	return false
end

function missionObject:setCloudsBase(cloud)
	if type(cloud) == "number" then self.mission.weather.clouds.base = cloud return true end
	return false
end

function missionObject:setVisibility(vis)
	if type(vis) == "number" then self.mission.weather.visibility.distance = vis return true end
	return false
end

function missionObject:setWeatherName(name)
	if type(name) == "string" then self.mission.weather["name"] = name return true end
	return false
end

function missionObject:setDustEnable(dust)
	if type(dust) == "number" then self.mission.weather.enable_dust = dust return true end
	return false
end

function missionObject:setWeatherType(wtype)
	if type(wtype) == "number" then self.mission.weather.type_weather = wtype return true end
	return false
end
--[[
mission["weather"] = {}
mission["weather"]["season"] = {}
mission["weather"]["season"]["temperature"] = 20
mission["weather"]["modifiedTime"] = true
mission["weather"]["qnh"] = 760
mission["weather"]["groundTurbulence"] = 0
mission["weather"]["dust_density"] = 0
mission["weather"]["wind"] = {}
mission["weather"]["wind"]["at2000"] = {}
mission["weather"]["wind"]["at2000"]["dir"] = 0
mission["weather"]["wind"]["at2000"]["speed"] = 0
mission["weather"]["wind"]["atGround"] = {}
mission["weather"]["wind"]["atGround"]["dir"] = 358.9999630965
mission["weather"]["wind"]["atGround"]["speed"] = 2
mission["weather"]["wind"]["at8000"] = {}
mission["weather"]["wind"]["at8000"]["dir"] = 0
mission["weather"]["wind"]["at8000"]["speed"] = 0
mission["weather"]["enable_fog"] = false
mission["weather"]["fog"] = {}
mission["weather"]["fog"]["visibility"] = 0
mission["weather"]["fog"]["thickness"] = 0
mission["weather"]["cyclones"] = {}
mission["weather"]["atmosphere_type"] = 0
mission["weather"]["clouds"] = {}
mission["weather"]["clouds"]["preset"] = "Preset8"
mission["weather"]["clouds"]["density"] = 0
mission["weather"]["clouds"]["iprecptns"] = 0
mission["weather"]["clouds"]["thickness"] = 200
mission["weather"]["clouds"]["base"] = 5460
mission["weather"]["visibility"] = {}
mission["weather"]["visibility"]["distance"] = 80000
mission["weather"]["name"] = "Winter, clean sky"
mission["weather"]["enable_dust"] = false
mission["weather"]["type_weather"] = 0
]]--

function dme.basicSerialize(value)
    if type(value) == "number" then
        return tostring(value)
    elseif type(value) == "boolean" then
        return tostring(value)
    else
        return string.format("%q", value)
    end
end

function dme.serializeWithCycles(name, value, saved)
    local serialized = {}
    saved = saved or {}
    if type(value) == "number" or type(value) == "string" or type(value) == "boolean" or type(value) == "table" then
        serialized[#serialized+1] = name.." = "
        if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
            serialized[#serialized+1] = dme.basicSerialize(value).."\n"
        else
            if saved[value] then
                serialized[#serialized+1] = saved[value].."\n"
            else
                saved[value] = name
                serialized[#serialized+1] = "{}\n"
                for k, v in pairs(value) do
                    local fieldname = string.format("%s[%s]", name, dme.basicSerialize(k))
                    serialized[#serialized+1] = dme.serializeWithCycles(fieldname, v, saved)
                end
            end
        end
        return table.concat(serialized)
    else
        return ""
    end
end

function dme.sleep(n)
  if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end


----------------------------------------------------------------------------------------------------------------  execution


local newMission = dme.createInstance("C:\\source\\cold-war-production-v143.miz")

newMission:getWeatherFromTemplate("C:\\source\\weapon_templates.miz")

dme.loadWeaponTemplates("C:\\source\\weapon_templates.miz")

newMission:writeMissionTemplateToFile("C:\\DME\\cold-war-production-v143_export.miz")






























