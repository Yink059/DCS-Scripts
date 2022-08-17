--dynamic mission editor

--mission object

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
	instance:setObjectParams()
	dme.instances[missionName] = instance
	return instance
end

function missionObject:setObjectParams()
	return self
end

function missionObject:readObjectParams(filename)
	return
end

function missionObject:writeObjectParams(filename)
	return
end

function returnMissionTemplate(filename)
	local f = io.open(filename,"r")
	local s = "dme_" .. f:read("*all")
	loadstring(s)()
	local missionTemplate = dme_mission
	return missionTemplate
end

function missionObject:getWeatherFromTemplate(filename)
	return
end
----------------------------------------------------------------------------------------------------------------  date definitions

function missionObject:setDay(day)
	if type(day) == "number" then self.date["Day"] = day return true end
	return false
end

function missionObject:setMonth(month)
	if type(month) == "number" then self.date["Month"] = month return true end
	return false
end

function missionObject:setYear(year)
	if type(year) == "number" then self.date["Year"] = year return true end
	return false
end


----------------------------------------------------------------------------------------------------------------  time definitions

function missionObject:setTime(time)
	if type(time) == "number" then self.start_time = time return true end
	return false
end

----------------------------------------------------------------------------------------------------------------  weather definitions

function missionObject:setTemperature(temp)
	if type(temp) == "number" then self.weather.season.temperature = temp return true end
	return false
end

function missionObject:setQNH(qnh)
	if type(qnh) == "number" then self.weather.qnh = qnh return true end
	return false
end

function missionObject:setGroundTurbulence(gt)
	if type(gt) == "number" then self.weather.groundTurbulence = gt return true end
	return false
end

function missionObject:setDustDensity(dd)
	if type(dd) == "number" then self.weather.dust_density = dd return true end
	return false
end

function missionObject:setWindAt2000(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.weather.wind["at2000"]["dir"] = dir self.weather.wind["at2000"]["speed"] = speed return true end
	return false
end

function missionObject:setWindAtGround(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.weather.wind["atGround"]["dir"] = dir self.weather.wind["atGround"]["speed"] = speed return true end
	return false
end

function missionObject:setWindAt8000(dir,speed)
	if type(dir) == "number" and type(speed) == "number" then self.weather.wind["at8000"]["dir"] = dir self.weather.wind["at8000"]["speed"] = speed return true end
	return false
end

function missionObject:setFogEnable(fog)
	if type(fog) == "boolean" self.weather.wind.enable_fog = fog return true end
	return false
end

function missionObject:setFogVisibility(fog)
	if type(fog) == "number" self.weather.wind.fog.visibility = fog return true end
	return false
end

function missionObject:setFogVisibility(fog)
	if type(fog) == "number" self.weather.wind.fog.visibility = fog return true end
	return false
end

function missionObject:setFogThickness(fog)
	if type(fog) == "number" self.weather.wind.fog.thickness = fog return true end
	return false
end

function missionObject:setAtmosphereType(atm)
	if type(atm) == "number" self.weather.["atmosphere_type"] = atm return true end
	return false
end

function missionObject:setCloudsPreset(cloud)
	if type(cloud) == "string" self.weather.clouds.preset = cloud return true end
	return false
end

function missionObject:setCloudsDensity(cloud)
	if type(cloud) == "number" self.weather.clouds.density = cloud return true end
	return false
end

function missionObject:setCloudsIprecptns(cloud)
	if type(cloud) == "number" self.weather.clouds.iprecptns = cloud return true end
	return false
end

function missionObject:setCloudsThickness(cloud)
	if type(cloud) == "number" self.weather.clouds.thickness = cloud return true end
	return false
end

function missionObject:setCloudsBase(cloud)
	if type(cloud) == "number" self.weather.clouds.base = cloud return true end
	return false
end

function missionObject:setVisibility(vis)
	if type(vis) == "number" self.weather.visibility.distance = vis return true end
	return false
end

function missionObject:setWeatherName(name)
	if type(name) == "string" self.weather["name"] = name return true end
	return false
end

function missionObject:setDustEnable(dust)
	if type(dust) == "number" self.weather.enable_dust = dust return true end
	return false
end

function missionObject:setWeatherType(wtype)
	if type(wtype) == "number" self.weather.type_weather = wtype return true end
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


































