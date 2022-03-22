local yinkSlotBlocker = {}





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

	local playerLives,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('"..pid.."'); ")
	local lifeLimit,_error  = net.dostring_in('server', " return trigger.misc.getUserFlag('lifeLimit'); ")
	
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

DCS.setUserCallbacks(yinkSlotBlocker)
