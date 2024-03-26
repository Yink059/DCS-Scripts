
local miz_export_path = lfs.writedir() .. "Alpen/mission.json"
local miz = {}

local function basicSerialize(value)
	if type(value) == "number" then
		return tostring(value)
	elseif type(value) == "boolean" then
		return tostring(value)
	else
		return string.format("%q", value)
	end
end

local function serializeWithCycles(name, value, saved)
	local serialized = {}
	saved = saved or {}
	if type(value) == "number" or type(value) == "string" or type(value) == "boolean" or type(value) == "table" then
		serialized[#serialized + 1] = name .. " = "
		if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
			serialized[#serialized + 1] = dme.basicSerialize(value) .. "\n"
		else
			if saved[value] then
				serialized[#serialized + 1] = saved[value] .. "\n"
			else
				saved[value] = name
				serialized[#serialized + 1] = "{}\n"
				for k, v in pairs(value) do
					local fieldname = string.format("%s[%s]", name, dme.basicSerialize(k))
					serialized[#serialized + 1] = dme.serializeWithCycles(fieldname, v, saved)
				end
			end
		end
		return table.concat(serialized)
	else
		return ""
	end
end

function miz.onMissionLoadBegin()
    local f = io.open(miz_export_path, "w")
    local missionTable = DCS.getCurrentMission()
    local json = net.lua2json(missionTable)
    f:write(json)
    f:close()
end

DCS.setUserCallbacks(miz)