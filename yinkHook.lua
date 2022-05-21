local yinkSlotBlocker = {}
local StB = { ["true"]=true, ["false"]=false , ["0"] = false, ["1"] = true}

local function split(pString, pPattern) --string.split
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

function yinkSlotBlocker.allowChangeSlot(pid, sid )
	
	local unitID = split(sid,"_")[1]

	local n = DCS.getUnitProperty(unitID, DCS.UNIT_NAME)
	local t = DCS.getUnitProperty(unitID, DCS.UNIT_TYPE)
	local c = DCS.getUnitProperty(unitID, DCS.UNIT_COALITION)
	local gT = DCS.getUnitProperty(unitID, DCS.UNIT_GROUPCATEGORY)
	local playerLives,lifeLimit	
	
	local playerLivesAirplane,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('"..pid.."'..'_lives_airplane'); ")
	local playerLivesHelicopter,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('"..pid.."'..'_lives_helicopter'); ")
	local lifeLimitAirplane,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('lifeLimit_airplane'); ")
	local lifeLimitHelicopter,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('lifeLimit_helicopter'); ")
	
	local unitExemption,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('"..t.."'); ")
	if StB[unitExemption] then
		return true
	end
	
	if gT == "plane" then
		playerLives = playerLivesAirplane
		lifeLimit = lifeLimitAirplane
		net.send_chat_to("Fixed Wing Lives left: "..tostring(lifeLimit - playerLives), pid)
	elseif gT == "helicopter" then
		playerLives = playerLivesHelicopter
		lifeLimit = lifeLimitHelicopter
		net.send_chat_to("Helicopter Lives left: "..tostring(lifeLimit - playerLives), pid)
	end
	
	if tonumber(playerLives) >= tonumber(lifeLimit) then
		return false
	end
	
	return true
end

function yinkSlotBlocker.onPlayerTryChangeSlot(pilotID, side, slotID)
	local allow = yinkSlotBlocker.allowChangeSlot(pilotID,slotID)
	if not allow then return false end
end

function yinkSlotBlocker.onGameEvent(eventName, ...)
	if eventName ~= "crash" then return end
	
	local allow = yinkSlotBlocker.allowChangeSlot(arg[1],arg[2])
	if not allow then
		net.force_player_slot(arg[1],0,'')
	end
end

function yinkSlotBlocker.onPlayerTrySendChat(pid, msg, all)
	
	local side
	
	if net.get_player_info(pid, 'side') == 0 and pid == 1 then
		return ""
	end
	
	if msg == "-test" then
		for k, v in next, net.get_player_list( ) do
			net.send_chat_to(tostring(v), pid)
		end
	end
	
	if msg == "-bail" then
		local playerName = net.get_player_info(pid , 'name')
		local _status,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('bail', 1); ")
		local _status,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..playerName.."_bail".."', 1); ")
		return "bailing out!"
	end
	
	if split(msg," ")[1] == "-reset" then
	
		local lifeLimitAirplane,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('lifeLimit_airplane'); ")
		local lifeLimitHelicopter,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('lifeLimit_helicopter'); ")
	
		if split(msg," ")[2] == "blue" then
			net.send_chat_to('resetting blue lives', pid)
			for k, v in next, net.get_player_list() do
				side = net.get_player_info(v , 'side')
				if tonumber(side) == 2 then
					local playerLivesAirplane,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_airplane',0); ")
					local playerLivesHelicopter,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_helicopter',0); ")
				end
			end
			return ""
		elseif split(msg," ")[2] == "red" then
			net.send_chat_to('resetting red lives', pid)
			for k, v in next, net.get_player_list() do
				side = net.get_player_info(v , 'side')
				if tonumber(side) == 1 then
					local playerLivesAirplane,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_airplane',0); ")
					local playerLivesHelicopter,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_helicopter',0); ")
				end
			end
			return ""		
		elseif split(msg," ")[2] == "spectators" then
			net.send_chat_to('resetting spectator lives', pid)
			for k, v in next, net.get_player_list() do
				side = net.get_player_info(v , 'side')
				if tonumber(side) == 0 then
					local playerLivesAirplane,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_airplane',0); ")
					local playerLivesHelicopter,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('"..v.."'..'_lives_helicopter',0); ")
				end
			end
			return ""
		end
	end	
	
end

DCS.setUserCallbacks(yinkSlotBlocker)
