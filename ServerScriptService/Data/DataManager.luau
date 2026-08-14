--[[
	TODO: add promises to prevent data loading race conditions
]]

local RP = game:GetService("ReplicatedStorage")
local DataManager = {}

local Template = require(script.Parent.Template)
local DeepCopy = require(RP.Utils.DeepCopy)

--Store profiles from profilestore
DataManager.Profiles = {}
DataManager.DataReplica = {}

export type path = {string} | string | nil

local function parsePath(p : path)
	if typeof(p) == "string" then
		p = string.split(p, ".")
	elseif p == nil then
		p = {}
	end
	return p
end

local function getParent(data, p)
	for k = 1, #p-1 do
		data = data[p[k]]
	end
	return data
end

function DataManager.GetData(plr : Player, p : path)
	local profile = DataManager.Profiles[plr]
	if profile then
		p = parsePath(p)
		
		if #p == 0 then return profile.Data end
		return getParent(profile.Data, p)[p[#p]]
	end
end

function DataManager.ClearData(plr : Player)
	local profile = DataManager.Profiles[plr]
	local replica = DataManager.DataReplica[plr]

	if profile and replica then 
		local newData = DeepCopy(Template)
		profile.Data = newData
		
		for key in pairs(replica.Data) do
			replica.Data[key] = nil
		end

		-- Fill with new data
		for key, value in pairs(newData) do
			replica:Set({key}, value)
		end
	end
end

function DataManager.SetData(plr : Player, p : path, v)
	local profile = DataManager.Profiles[plr]
	local replica = DataManager.DataReplica[plr]
	if profile and replica then
		p = parsePath(p)
		
		local data = getParent(profile.Data, p)
		
		data[p[#p]] = v --for last elem
		replica:Set(p, v)
	end
end

function DataManager.TableInsert(plr : Player, p : string | {string}, v)
	local profile = DataManager.Profiles[plr]
	local replica = DataManager.DataReplica[plr]
	
	if profile and replica then
		p = parsePath(p)
		local data = getParent(profile.Data, p)
		
		table.insert(data[p[#p]], v)
		replica:TableInsert(p,v)
	end
end

function DataManager.TableRemove(plr : Player, p : string | {string}, elem)
	local profile = DataManager.Profiles[plr]
	local replica = DataManager.DataReplica[plr]

	if profile and replica then
		p = parsePath(p)
		local data = getParent(profile.Data, p)

		local idx = table.find(data[p[#p]],elem)
		if idx then
			table.remove(data[p[#p]], idx)
			replica:TableRemove(p,idx)
		end		
	end
end


return DataManager
