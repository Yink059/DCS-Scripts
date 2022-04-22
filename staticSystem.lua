--[[
Static export system
By Yink
naming convention - x_nn_ii(_m
x = red (r) or blue (b)
ni = group number
ii = number in group
(_m = optional metadata
trigger.action.outText(tostring(staticObj[i]),10)
]]--
currentDir = "C:/Users/brand/Documents/MoF/Files/"

local blue_fileDynamic	= currentDir .. "blue_statics.txt"
local blue_fileStatic	= currentDir .. "blue_statics_init.txt"

local red_fileDynamic	= currentDir .. "red_statics.txt"
local red_fileStatic	= currentDir .. "red_statics_init.txt"

local redFile			= currentDir .. "redPlayers.txt"
local blueFile 			= currentDir .. "bluePlayers.txt"

local redUnits			= currentDir .. "redUnits.txt"
local blueUnits			= currentDir .. "blueUnits.txt"

local afC		= currentDir .. "airfieldControl.txt"
groupCounter 	= 0
markCounter		= 0

--[[
local f	= currentDir .. "slot.txt"
local file 		= assert(io.open(f,"r"))
local slotText	= file:read("*all")
file:close()
]]--

local logiAmount = 20

------------------------------------------------------------------------------------------------------------------------ Init & Misc Functions

function debugT(v)
	trigger.action.outText(tostring(v),10)
end

--[[ --for putting ammo/fuel statics on farps
do
	local old_onEvent = world.onEvent
	world.onEvent = function(event)
		if (world.event.S_EVENT_BASE_CAPTURED == event.id) then		

			if event.place:getTypeName() == "FARP" then
				
				local xOffset = -75 * math.cos(math.atan2(event.place:getPosition().x.z, event.place:getPosition().x.x)+2*math.pi)
				local yOffset = 75 * math.sin(math.atan2(event.place:getPosition().x.z, event.place:getPosition().x.x)+2*math.pi)--math.random(-75,75)
				

				
				local staticObj = {}
				staticObj["name"] = event.place:getName().. "_ammo"
				staticObj["type"] = "FARP Ammo Dump Coating"
				staticObj["x"] = event.place:getPoint().x + xOffset + 7
				staticObj["y"] = event.place:getPoint().z + yOffset + 7
				staticObj["heading"] = math.random(1,360)
					
				local c = event.initiator:getCoalition()
				
				if c == 2 then
					coalition.addStaticObject(country.id.USA, staticObj)
				elseif c == 1 then
					coalition.addStaticObject(country.id.RUSSIA, staticObj)
				end
				
				staticObj["name"] = event.place:getName().. "_fuel"
				staticObj["type"] = "FARP Fuel Depot"
				staticObj["x"] = event.place:getPoint().x + xOffset - 7
				staticObj["y"] = event.place:getPoint().z + yOffset - 7
				staticObj["heading"] = math.random(1,360)
					
					
				if c == 2 then
					coalition.addStaticObject(country.id.USA, staticObj)
				elseif c == 1 then
					coalition.addStaticObject(country.id.RUSSIA, staticObj)
				end
				
			end
		end
		if (world.event.S_EVENT_BIRTH == event.id) then
			trigger.action.outTextForGroup(event.initiator:getGroup():getID() , slotText, 30, true)
		end
		return old_onEvent(event)
	end
end
]]--

function mapMarkup(_,time) --for airbases

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

function mapMarkupStatics(_,time) --for strategic sites

	local staticsR	= createStatics(red_fileDynamic, nil, nil)
	local groupsR	= {}
	local logiR		= 0
	local staticsB	= createStatics(blue_fileDynamic, nil, nil)
	local groupsB	= {}
	local markers	= {}
	local pass		= false
	local logiB		= 0
	local color		= {}
	local red		= {1, 0, 0, 0.2}
	local blue		= {0, 0, 1, 0.2}
	local neut		= {0.9, 0.9, 0.9, 0.2}
	local gelb		= {1.0,1.0, 0, 0.7}
	local v			= {}
	local c			= 0
	markCounter		= 0		
	
	for k, v in next, staticsR do --create tables of static groups
		if groupsR[string.sub(v["name"],1,4)] == nil then
			groupsR[string.sub(v["name"],1,4)] = {}
			groupsR[string.sub(v["name"],1,4)]["val"] = 0
			for k2, v2 in next, staticsR do
				if string.sub(v2["name"],1,4) == string.sub(v["name"],1,4) then
					if tonumber(string.sub(v2["name"],9,10)) > 0 then
						table.insert(groupsR[string.sub(v["name"],1,4)], v2)
						groupsR[string.sub(v["name"],1,4)]["val"] = groupsR[string.sub(v["name"],1,4)]["val"] + tonumber(string.sub(v2["name"],9,10))
					end
				end
			end
		end
	end
	
	for k, v in next, staticsB do --create tables of static groups
		if groupsB[string.sub(v["name"],1,4)] == nil then
			groupsB[string.sub(v["name"],1,4)] = {}
			groupsB[string.sub(v["name"],1,4)]["val"] = 0
			for k2, v2 in next, staticsB do
				if string.sub(v2["name"],1,4) == string.sub(v["name"],1,4) then
					if tonumber(string.sub(v2["name"],9,10)) > 0 then
						table.insert(groupsB[string.sub(v["name"],1,4)], v2)
						groupsB[string.sub(v["name"],1,4)]["val"] = groupsB[string.sub(v["name"],1,4)]["val"] + tonumber(string.sub(v2["name"],9,10))
					end
				end
			end
		end
	end

	--[[
	for i = 1, 99 do --set all markers from 101 to 199 to neutral color
		trigger.action.setMarkupColor(i+100 , gelb )
		trigger.action.setMarkupColorFill(i+100 , neut )
	end
	]]--
	markCounter = 0	
	for k, v in next, groupsB do --create circles and/or set color if they exist.
		if v["val"] > 0 then
			local s = v[1]
			markCounter	= markCounter + 1
			local markC	= tonumber(string.sub(s["name"],3,4))
			color = blue
			vec3 = StaticObject.getByName(s["name"]):getPoint()
			table.insert(markers, markC+100)
			trigger.action.circleToAll(-1, markC+100, vec3 , 2750, color, color, 1, true,s["name"])
			trigger.action.setMarkupColor(markC+100 , gelb )
			trigger.action.setMarkupColorFill(markC+100 , color )
		end
	end
	
	markCounter = 0
	for k, v in next, groupsR do --create circles and/or set color if they exist.
		if v ~= nil then
			local s = v[1]
			markCounter	= markCounter + 1
			local markC	= tonumber(string.sub(s["name"],3,4))
			color = red
			local vec3 = StaticObject.getByName(s["name"]):getPoint()
			table.insert(markers, markC+200)
			trigger.action.circleToAll(-1, markC+200, vec3 , 2750, color, color, 1, true,s["name"])
			trigger.action.setMarkupColor(markC+200 , gelb )
			trigger.action.setMarkupColorFill(markC+200 , color )
		end
	end
	
	for k, v in next, world.getMarkPanels() do
		pass = true
		for k2, v2 in next, markers do
			if v.idx == v2 then
				pass = false
			end
		end
		if v.idx >= 101 and v.idx <= 299 and pass then
			trigger.action.setMarkupColorFill(v.idx , neut )
		end
	end
	
	
	return time + 15
end
------------------------------------------------------------------------------------------------------------------------ Static Save Function Definitions

function save_static_info(t, role) --save static info to table from unit; return that table

	local staticObj = {}
	-- name, type, x, y, heading, dead
	staticObj[1] = t:getName() -- name
	staticObj[2] = t:getTypeName()	-- type
	staticObj[3] = t:getPoint().x -- x
	staticObj[4] = t:getPoint().z -- y
	staticObj[5] = math.deg(math.atan2(t:getPosition().x.z, t:getPosition().x.x)+2*math.pi) -- heading
	staticObj[6] = "true"
	
	if role == "strat" then
		staticObj[7] = string.sub(t:getName(),9,10) -- logistic value
	end
	
	for i = 1, #staticObj, 1 do
		break--trigger.action.outText(tostring(staticObj[i]),10) --debug
	end

	return staticObj

end

function file_write (f, init, staticGroups, side_iter, role)	--write unit/static data to file via newline delineated groups, with init logic for metadata storage
	if #side_iter > 0 then
		for i = 1, #side_iter, 1 do
			for n = 1, #staticGroups[side_iter[i]], 1 do			
				
				t = save_static_info(staticGroups[side_iter[i]][n], role) --object definition
				
				--pull metadata from x_xx_01 if init
				--[[
				if init then
					if string.sub(t[1],6,7) == "01" then
						logisticPoints 		= ((tonumber(string.sub(t[1],9,9))) * 10) + (tonumber(string.sub(t[1],10,10)))
						siteName			= string.sub(t[1],12,#t[1])
						trigger.action.outText(siteName,10)
					end
				end
				]]--deprecated
				
				for k, v in next, t do --step through staticObject table and save to file
					f:write(t[k],"") -- seperate object values
					if k < #t then -- if iterator less than current table length
						f:write(",") -- seperate object values	
					end
				end
				if n<#staticGroups[side_iter[i]] then -- if iterator less than current table length
					f:write("|") -- seperate objects
				end
			end
			if init then
				init = init
				--f:write("%" ,"," , tostring(logisticPoints), ",", siteName)-- metadata, deprecated
			end
			f:write("\n") -- next group
		end
		f:write("EOF")
	end
end

function fileProcess(side,fileDynamic,fileStatic,fileStaticEnable, pat) --write the files, input is statics and iterators and file locations
	
	local c = 0
	if side == "blue" then
		c = 2
	elseif side == "red" then
		c = 1
	end
	
	staticTable = coalition.getStaticObjects(c)
	staticGroups = {}
	side_iter = {}
	
	if #staticTable >= 1 then --append statics to group list
		for i = 1, #staticTable, 1 do
			local currentGroup = string.sub(staticTable[i]:getName(),1,4)
			if string.sub(currentGroup,1,2) == pat then
				if staticGroups[currentGroup] == nil then --create nested list if not present
					staticGroups[currentGroup] = {}
					table.insert(side_iter, currentGroup)
				end
				table.insert(staticGroups[currentGroup], staticTable[i]) --append static to group list
			end
		end
	end
	
	role = ""
	if pat == "b_" or pat == "r_" then
		role = "strat"
	end
	
	
	if fileStaticEnable then
		local fileInit = io.open(fileStatic,"r") -- init file with meta data
		if fileInit == nil then			
			local fileInit = assert(io.open(fileStatic,"w")):close()
		end
		local writeUnitInitFile = (fileInit:read("*all") == "")--boolean to check if init file is empty
		fileInit:close()
		
		if writeUnitInitFile then 
			local fileInit = assert(io.open(fileStatic,"w"))
			file_write(fileInit, true, staticGroups, side_iter, role)
			fileInit:close()
		end
	end
	
	local fileLive = assert(io.open(fileDynamic,"w")):close()
	local fileLive = assert(io.open(fileDynamic,"w"))
	
	file_write(fileLive, false, staticGroups, side_iter, role)
	fileLive:close()
	
end

------------------------------------------------------------------------------------------------------------------------ Static Load Function Definitions

function split(pString, pPattern) --string.split
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

function createStatics(f, c, o) --create static from table, global

	local file = assert(io.open(f,"r"))
	

	t = {}
	local line = file:read("*l")
		
	if line ~= "" or line ~= "EOF" then --iterate through each line of file
		table.insert(t, line)
		while line ~= "EOF" do
			line = file:read("*l")
			if line ~= "EOF" then
				table.insert(t, line)
			end
		end
	end
	file:close()
	
	objectTable = {}
	
	if t ~= {} then
		for l, b in next, t do
			--trigger.action.outText(tostring(b),10)
			local staticList = {}
			local tempObject = {}
			local siteTable = split(b,"[|]") --parse whole string into object strings
			for k, v in next, siteTable do -- parse each string into object table
				tempObject = split(v,"[,]") --split object table into object list
				objectTable[string.sub(tempObject[1],1,#tempObject[1])] = tempObject --save object to object table indexed under group convention
			end
		end	
		
		local finalObjectTable = {} --table to be returned, table of (static creation definition tables)
		
				
		for k, v in next, objectTable do --
			local staticObj = {}
			staticObj["name"] = v[1] --go though the values and assign to static creation table accordingly
			staticObj["type"] = v[2]
			staticObj["x"] = tonumber(v[3])
			staticObj["y"] = tonumber(v[4])
			staticObj["heading"] = math.rad(tonumber(v[5]))
			if o == "spawnD" then
				staticObj["dead"] = false
			end
	
			table.insert(finalObjectTable, staticObj)
			
			if o == "spawnN" or o == "spawnD" then --create if we want
				if c == "blue" then
					coalition.addStaticObject(country.id.USA, staticObj)
				elseif c == "red" then
					coalition.addStaticObject(country.id.RUSSIA, staticObj)
				end
			end
		end
		return finalObjectTable --ability to export static information if you dont want to spawn them
	end
end

--[[
function loadStart (f, c, o) --file input
	
	local file = assert(io.open(f,"r"))
	t = {}
	local line = file:read("*l")
	
	if line ~= "" then
		table.insert(t, line)
		while line ~= "EOF" do
			line = file:read("*l")
			if line ~= "EOF" then
				table.insert(t, line)
			end
		end
		
	end
	file:close()
	createStatics(siteTable, c, o)
	
end
]]--

function createStaticGroupsFromPointList (templateFile,groupNamePat,spawnLocationFile,airfieldControl,c,o)
	
	
	aF = io.open(airfieldControl,"r")
	redAB 	= split(aF:read("*l"),",") --read red
	blueAB	= split(aF:read("*l"),",")	--read blue
	aF:close()
	
	originPoint = {}
	
	templateTable 		= createStatics(templateFile, nil, nil) --create list of object definition tables
	spawnLocationTable	= createStatics(spawnLocationFile, nil, nil) --get object tables for the origin point for template spawning
	templateDefTable 	= {}
	tempTemplateTable = {}

	
	for k, v in next, templateTable do --define the origin for template group object 01
		if string.sub(v["name"],6,7) == "01" then
			originPoint[1] = v["x"]
			originPoint[2] = v["y"]
		end
	end
	
	for k, v in next, templateTable do --modify x and y of each object in table to be offsets of the origin
	
		v["x"] = v["x"] - originPoint[1]
		v["y"] = v["y"] - originPoint[2]
	end
	
	
	for afKey, afValue in next, redAB do
		for sltKey, sltValue in next, spawnLocationTable do
			if string.sub(sltValue["name"],6,#sltValue["name"]) == afValue then --if coalition has the airfield
			tempTemplateTable = createStatics(templateFile, nil, nil) --create new object table to modify
				for tempTableKey, tempObject in next, tempTemplateTable do
					
					tempObject["x"] =  sltValue["x"] + templateTable[tempTableKey]["x"]--spawn location table x coordinate + offset value for currently selected 
					tempObject["y"] =  sltValue["y"] + templateTable[tempTableKey]["y"]--offset
					
					tempObject["name"] = tempObject["name"] .. afValue
					
					coalition.addStaticObject(country.id.RUSSIA, tempObject)
				end
				
			end
		end
	end
	
	for afKey, afValue in next, blueAB do
		for sltKey, sltValue in next, spawnLocationTable do
			if string.sub(sltValue["name"],6,#sltValue["name"]) == afValue then --if coalition has the airfield
			tempTemplateTable = createStatics(templateFile, nil, nil)
				for tempTableKey, tempObject in next, tempTemplateTable do
					
					tempObject["x"] =  sltValue["x"] + templateTable[tempTableKey]["x"]--offset
					tempObject["y"] =  sltValue["y"] + templateTable[tempTableKey]["y"]--offset
					
					tempObject["name"] = tempObject["name"] .. afValue
					
					coalition.addStaticObject(country.id.USA, tempObject)
				end
				
			end
		end
	end
	
end



--[[ todo

change file locations
trigger.action.outText(tostring(staticObj[i]),10)
]]--


------------------------------------------------------------------------------------------------------------------------ Unit Functions

--[[
function tankerDespawn(_,time)

	local aF 		= io.open(afC,"r")
	local redAB 	= split(aF:read("*l"),",") --read red
	local blueAB	= split(aF:read("*l"),",")	--read blue
	aF:close()
	local redG		= coalition.getGroups(1 , 0)
	local redT		= {}
	local blueG		= coalition.getGroups(2 , 0)
	local blueT		= {}
	local AB 		= ""
	
	for k, v in next, redG do
		if split(v:getName(),"_")[2] == "Tanker" then
			table.insert(redT,v)
		end
	end
	
	for k, v in next, blueG do
		if split(v:getName(),"_")[2] == "Tanker" then
			table.insert(blueT,v)
		end
	end
	
	for k, v in next, blueAB do
		for k2, v2 in next, redT do
			if split(v2:getName(),"_")[1] == v then
				trigger.action.deactivateGroup(v2)
			end
		end	
	end
	
	for k, v in next, redAB do
		for k2, v2 in next, blueT do
			if split(v2:getName(),"_")[1] == v then
				trigger.action.deactivateGroup(v2)
			end
		end	
	end
	
	return time+5	
end
]]--

function getGroup(n)
	
	local group 		= {}
	local g 			= Group.getByName(n) --get group
	local u 			= g:getUnits()
	group["country"] 	= g:getUnits()[1]:getCountry() --get country enumerator
	group["category"] 	= g:getCategory()
	group["name"] 		= g:getName() .. "_" .. tostring(groupCounter)
	group["task"] 		= "Ground Nothing"
	group["units"]		= {}
	
	for k, v in next, u do
		local unit = {}
		unit["name"] 		= v:getName() .. "_" .. tostring(k) .. "_" .. tostring(math.random(100,9999999))
		unit["type"] 		= v:getTypeName()
		unit["x"]			= tonumber(v:getPoint().x) - tonumber(u[1]:getPoint().x) --must modify coordinate in spawn script, this centers the group around the map origin (0,0)
		unit["y"]			= tonumber(v:getPoint().z) - tonumber(u[1]:getPoint().z)
		unit["heading"] 	= math.random(1,360)
		group["units"][k] 	= unit
	end
	groupCounter = groupCounter + 1
	
	
	return group
end


function createGroup(g) -- for statics
	coalition.addGroup(g["country"],g["category"],g)
	return nil
end

function createGroups(gN ,sF, afc)

	local c = Group.getByName(gN):getUnits()[1]:getCoalition()
	
	aF = io.open(afc,"r")
	redAB 	= split(aF:read("*l"),",") --read red
	blueAB	= split(aF:read("*l"),",")	--read blue
	AB = ""
	
	if 		c == 1 then
		AB = redAB
	elseif 	c == 2 then
		AB = blueAB
	end
	
	aF:close()
	
	spawnPoints = createStatics(sF, nil, nil)
	
	for l, b in next, AB do
		for k, v in next, spawnPoints do
			if (string.sub(v["name"],1,2)) == string.sub(gN,1,2) then
				if string.sub(v["name"],6,#v["name"]) == b then
					g = getGroup(gN)
					for iter, unit in next, g["units"] do
						unit["x"] = unit["x"] + v["x"]
						unit["y"] = unit["y"] + v["y"]
					end
					createGroup(g)
				end
			end		
		end
	end
	trigger.action.deactivateGroup(Group.getByName(gN))
end





------------------------------------------------------------------------------------------------------------------------ Extra Functions

function airfieldControl(f, time)
	
	if true then --create airfield master file init
		
		local aF 					= io.open(f,"r")
		
		curRedAB		= split(aF:read("*l"),",")
		curBlueAB		= split(aF:read("*l"),",")
		
		aF:close()
		
		local neutAirbases	= coalition.getAirbases(0)
		local redAirbases	= coalition.getAirbases(1)
		local blueAirbases	= coalition.getAirbases(2)
		
		local aF					= io.open(f,"w")
		
		aF:write(",")
		for k, v in next, redAirbases do
			aF:write(tostring(v:getName()),",")
			ctld.activatePickupZone("r_"..v:getName())
			ctld.deactivatePickupZone("b_"..v:getName())
		end

		for k, v in next, curRedAB do
			for k2, v2 in next, neutAirbases do
				if v == v2:getName() and v2:getCoalition() == 3 then
					break
				end
			end
			
		end
		aF:write("\n")
		aF:write(",")
		for k, v in next, blueAirbases do
			aF:write(tostring(v:getName()),",")
			ctld.activatePickupZone("b_"..v:getName())
			ctld.deactivatePickupZone("r_"..v:getName())
		end

		for k, v in next, curBlueAB do
			for k2, v2 in next, neutAirbases do
				if v == v2:getName() and v2:getCoalition() == 3 then
					break
					--aF:write(tostring(v2:getName()),",")
				end
			end
		end
		
		aF:close()
	end
	return time + 7
end

------------------------------------------------------------------------------------------------------------------------ Execution functions


function saveStaticsStrategic(_, time) --save statics to file
	fileProcess( --save blue statics to file
		"blue",
		blue_fileDynamic,
		blue_fileStatic,
		false,
		"b_"
	)
	
	fileProcess( --save red statics to file
		"red",				--coalition to query
		red_fileDynamic,	--file to be modified
		red_fileStatic, 	--master file to be created
		false,				--set to true to check for master file creation, will skip if master file has any data or this value is false
		"r_" 				--first two characters for filter
	)
	return time + 5
end

function loadStrategicStatics(fD,fS,c)
	
	local lD 	= createStatics(fD, nil, nil)
	local lS 	= createStatics(fS, nil, nil)
	local t		= {}
	
	for k, v in next, lS do
		v["dead"] = true
	end
	
	for k, v in next, lS do
		for k2, v2 in next, lD do
			if v2["name"] == v["name"] then
				v["dead"] = false
			end			
		end
	end
	local totalValue = 0
	local trueValue = 0
	
	for k, v in next, lS do
		if c == "blue" then
			totalValue = totalValue + tonumber(string.sub(v["name"],9,10))
			coalition.addStaticObject(country.id.USA, v)
			if v["dead"] == false then
				trueValue = trueValue + tonumber(string.sub(v["name"],9,10))
			end
		elseif c == "red" then
			totalValue = totalValue + tonumber(string.sub(v["name"],9,10))
			coalition.addStaticObject(country.id.RUSSIA, v)
			if v["dead"] == false then
				trueValue = trueValue + tonumber(string.sub(v["name"],9,10))
			end
		end
	end
	
	trueValue = logiAmount * (trueValue/totalValue)
	return trueValue
end

function createAirfieldUnits(args, time)
	
	asT		= currentDir .. "airfieldStaticDef.txt"
	asS		= currentDir .. "airfieldStaticSpawns.txt"
	afC		= currentDir .. "airfieldControl.txt"
	grpP	= ""
	createStaticGroupsFromPointList(asT,grpP,asS,afC,nil,nil) --create airfield statics
	
	createGroups("ar00_b" ,currentDir .. "SAM Defense Master.txt", afC) --blue airfield radar
	
	createGroups("ag00_b" ,currentDir .. "SAM Defense Master.txt", afC) --blue airfield sharad
	
	createGroups("ar00_r" ,currentDir .. "SAM Defense Master.txt", afC) --red airfield radar
	
	createGroups("ag00_r" ,currentDir .. "SAM Defense Master.txt", afC) --red airfield shorad
	
	createGroups("fg00_r" ,currentDir .. "SAM Defense Master.txt", afC) --red farp shorad
	
	createGroups("fg00_b" ,currentDir .. "SAM Defense Master.txt", afC) --blue farp shorad
	
	
	return nil

end


------------------------------------------------------------------------------------------------------------------------ Unit save functions

function save_group_info(g, role) --save group info to table from group; return string for writing
	
	local groupString = g:getName() .. "`"
	local units = g:getUnits()
	
	for k, v in next, units do
		groupString = groupString .. save_unit_info(v,nil)
		groupString = groupString .. "|"
	end
	groupString = groupString .. "\n"
	
	return groupString
	
end

function save_unit_info(t, role) --save  unit info to table from unit; return string for writing

	local unit = {}
	local unitString = ''
	-- name, type, x, y, heading, dead
	unit[1] = t:getName() -- name
	unit[2] = t:getTypeName()	-- type
	unit[3] = t:getPoint()
	unit[4] = t:getCoalition()
	unit[5] = math.deg(math.atan2(t:getPosition().x.z, t:getPosition().x.x)+2*math.pi) -- heading

	for i=1,5 do
		unitString = unitString .. unit[i] .. ','
	end
	
	return unitString

end

function writeGroupsToFile(coalition, file) -- collect strings and write to specified file
	
	local groups = coalition.getGroups(coalition , Group.Category.GROUND)
	
	local saveString = ""
	
	for k, group in next, groups do
		saveString = saveString + save_group_info(group,nil)
	end
	
	local f = assert(io.open(file,"w"))
	f:write(saveString)
	f:close()
	
end

function spawnGroupsFromFile(coalition, file)

	local c = coalition
	
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
		
		if coalition == 1 then
			group["country"] 	= country.id.RUSSIA
		elseif coalition == 2 then
			group["country"] 	= country.id.USA
		end
		group["category"]	= 2
		group["name"] 		= groupName
		group["task"] 		= "Ground Nothing"
		group["units"]		= {}
		
		for i = 1, unitCount do
			unitList = split(unitV,",")
			group["units"][i] = {}
			group["units"][i]["name"] 		= unitList[1]				
			group["units"][i]["type"]		= unitList[2]
			group["units"][i]["x"] 			= unitList[3].x
			group["units"][i]["y"]			= unitList[3].z
			group["units"][i]["heading"]	= unitList[4]
		end
		
		coalition.addGroup(group["country"],group["category"],group)
	end
	
end




------------------------------------------------------------------------------------------------------------------------ Function Scheduling

--[[
fileTest = assert(io.open(red_fileDynamic,"r"))
local bool = fileTest:read("*l")
fileTest:close()

if bool ~= nil or bool ~= "EOF" then	
	local redLogi = loadStrategicStatics(red_fileDynamic,red_fileStatic,"red")
	trigger.action.setUserFlag("redLogi", math.floor(redLogi) )
end

fileTest = assert(io.open(blue_fileDynamic,"r"))
local bool = fileTest:read("*l")
fileTest:close()

if bool ~= nil or bool ~= "EOF" then	
	local blueLogi = loadStrategicStatics(blue_fileDynamic,blue_fileStatic,"blue")
	trigger.action.setUserFlag("blueLogi", math.floor(blueLogi) )
end

timer.scheduleFunction(saveStaticsStrategic, {}, timer.getTime() + 5)

timer.scheduleFunction(createAirfieldUnits, temp, timer.getTime() + 4)

timer.scheduleFunction(mapMarkup, {}, timer.getTime()+2)

timer.scheduleFunction(airfieldControl, afC, timer.getTime() + 10)

timer.scheduleFunction(mapMarkupStatics, {}, timer.getTime()+16)


--timer.scheduleFunction(tankerDespawn, {}, timer.getTime()+30)
]]--



------------------------------------------------------------------------------------------------------------------------ EOF
--loadStaticsStrategic(temp, "red", "spawnN")
--loadStaticsStrategic(currentDir .. "airfieldStaticDef.txt", "blue", "spawnN")
--[[
	fileProcess( --save red statics to file
		"red",				--coalition to query
		temp,			--file to be modified
		red_fileStatic, 	--master file to be created
		false,				--set to true to check for master file creation, will skip if master file has any data or this value is false
		"as" 				--first two characters for filter
	)
]]--
