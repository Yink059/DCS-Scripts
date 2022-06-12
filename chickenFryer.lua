
--[[
	slot blocker for coalition control airfield/farps
		naming convention+
		user flag on capture event
		
	persistence
		template files for airbase defenses
		all units saved/reloaded on mission end/start
		seperate template files for dynamic spawning on capture condition
			airfield control ^^^^^^

	airfield control functions - recapture immmediately?
		make sure only defence units spawn back in
]]--

currentDir = lfs.writedir() .. "longbow/"

local defenseNameTemplate 	= "_defense_template.txt"
local blueDefensesDir		= currentDir .. "blue_defense_templates/"
local redDefensesDir		= currentDir .. "red_defense_templates/"
local defenseFileTable 		= { redDefensesDir , blueDefensesDir}

--[[
local f	= currentDir .. "slot.txt"
local file 		= assert(io.open(f,"r"))
local slotText	= file:read("*all")
file:close()
]]--

local yss = {} --yink save system

------------------------------------------------------------------------------------------------------------------------ Util and misc functions


local function split(pString, pPattern) --string.split
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
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

local function debugT(v)
	trigger.action.outText(tostring(v),10)
end

function yss.mapMarkup(_,time) --for airbases

	local AB 		= world.getAirbases()
	local color		= {}
	local red		= {1, 0, 0, 0.2}
	local blue		= {0, 0, 1, 0.2}
	local black		= {0,0,0,0.7}
	local neut		= {0.9, 0.9, 0.9, 0.2}
	local v			= {}
	local c			= 0
	markCounter		= 0
	
	--for k, v in next, AB do --delete markers
		--trigger.action.removeMark(k)
	--end
	for k, v in next, AB do
	
		c = v:getCoalition()
		
		if c == 1 then
			color = red
		elseif c == 2 then
			color = blue
		else
			color = neut
		end
		if v:getName() ~= "Soganlug" and v:getName() ~= "Vaziani" and v:getName() ~= "Krasnodar-Pashkovsky" then
			trigger.action.circleToAll(-1, k, v:getPoint() , 3500, color, color, 1, true, tostring(k).."_".. v:getName())
			--debugT(tostring(k).." "..tostring(v:getName()))
			trigger.action.setMarkupColor(k , black )
			trigger.action.setMarkupColorFill(k , color )
		end
	end
	return time + 15
end



------------------------------------------------------------------------------------------------------------------------ airfield control

yss.airfields = {}

function yss.saveAirfields()
	local airfields = {}

	for k, v in next, world.getAirbases() do
			airfields[v:getName()] = v:getCoalition()
		end
	end	
	
	return airfields
end


function yss.airfieldSwing(airfieldName)

	local oldController = yss.airfields[airfieldName]
	local airfield = Airbase.getByName(airfieldName)
	
	if oldController ~= airfield:getCoalition() then
		return true
	end
	
	return false
end


local airfieldEventHandler = {}

function airfieldEventHandler:onEvent(event)

	if world.event.S_EVENT_BASE_CAPTURED == event.id then
		local spawnDefenses = yss.airfieldSwing(event.place:getName())
			
		if spawnDefenses then
			local coa = event.initiator:getCoalition()
			local fileName = defenseFileTable[coa] .. event.place:getName() .. defenseNameTemplate
			
			yss.spawnGroupsFromFile(coa, fileName)
		end		
		yss.airfields = yss.saveAirfields()
	end
	
end
world.addEventHandler(airfieldEventHandler)

------------------------------------------------------------------------------------------------------------------------ Persistent Unit save functions

function yss.save_group_info(g, role) --save group info to table from group; return string for writing
	
	local groupString = g:getName() .. "`"
	local units = g:getUnits()
	
	for k, v in ipairs(units) do
		groupString = groupString .. yss.save_unit_info(v,nil)
		groupString = groupString .. "|"
	end
	groupString = groupString .. "\n"
	
	return groupString
	
end

function yss.save_unit_info(t, role) --save  unit info to table from unit; return string for writing

	local unit = {}
	local unitString = ''
	-- name, type, x, y, heading, dead
	unit[1] = t:getName() -- name
	unit[2] = t:getTypeName()	-- type
	unit[3] = t:getPoint().x
	unit[4] = t:getPoint().z
	unit[5] = math.atan2(t:getPosition().x.z, t:getPosition().x.x)+2*math.pi -- heading

	for i=1,5 do
		if unit[i] ~= nil then
			unitString = unitString .. tostring(unit[i]) .. ','
		end
	end
	
	return unitString

end

function yss.writeGroupsToFile(coa, file) -- collect strings and write to specified file
	
	local groups = coalition.getGroups(coa , Group.Category.GROUND)
	
	local saveString = ""
	
	for k, group in next, groups do
		saveString = saveString .. yss.save_group_info(group,nil)
	end
	
	local f = assert(io.open(file,"w"))
	f:write(saveString)
	f:close()
	
end

function yss.spawnGroupsFromFile(coa, file)

	local c = coa
	
	local f = io.open(file,"r")
	spawnString	= f:read("*all") --read
	f:close()
	
	local groups = split(spawnString,"\n")
	local groupSplit = {}
	local groupName = ""
	local groupList = {}
	local unitList = {}
	local group = {}
	local unit = {}
	local unitCount = {}
	
	for k, groupV in next, groups do -- for each group in the file
	
		groupSplit = split(groupV,'`')
		groupName = groupSplit[1]
		groupList = split(groupSplit[2],"|")
		group = {}	
		unitCount = #groupList
		
		if coa == 1 then
			group["country"] 	= country.id.RUSSIA
		elseif coa == 2 then
			group["country"] 	= country.id.USA
		end
		group["category"]	= 2
		group["name"] 		= groupName
		group["task"] 		= "Ground Nothing"
		group["units"]		= {}
		
		for i = 1, unitCount do
			unitList = split(groupList[i],",")
			group["units"][i] = {}
			group["units"][i]["name"] 		= unitList[1]				
			group["units"][i]["type"]		= unitList[2]
			group["units"][i]["x"] 			= tonumber(unitList[3])
			group["units"][i]["y"]			= tonumber(unitList[4])
			group["units"][i]["heading"]	= tonumber(unitList[5])
		end
		
		coalition.addGroup(group["country"],group["category"],group)
	end
	
end



------------------------------------------------------------------------------------------------------------------------ Execution


local testFile = currentDir .. 'test.txt'

--yss.writeGroupsToFile(1, testFile)
--yss.spawnGroupsFromFile(1,testFile)