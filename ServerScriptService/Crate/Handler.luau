local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Events

local DataManager = require(ServerScriptService.Data.DataManager)
local LevelSystem = require(ServerStorage.Libraries.LevelSystem)
local CrateData = require(ReplicatedStorage.Assets.Crates.Data)

local CrateService = {}

local DUPLICATE_EXP = 20

local function getRandomRarity(content)
	local totalWeight = 0
	for _, data in pairs(content) do
		totalWeight += data.CHANCE
	end

	local rand = math.random() * totalWeight
	local current = 0

	for rarity, data in pairs(content) do
		current += data.CHANCE
		if rand <= current then
			return rarity
		end
	end
end

local function getRandomWeaponFromCrate(crateName)
	local crate = CrateData[crateName]
	
	local content = crate.CONTENT
	local rarity = getRandomRarity(content)
	if not rarity then return nil end

	local rewards = content[rarity].REWARDS
	if not rewards or #rewards == 0 then return nil end

	local weapon = rewards[math.random(1, #rewards)]
	return weapon
end

function CrateService.Roll(plr: Player, crateName: string) : (string, string)
	local inventory = DataManager.GetData(plr, {"Inventory"})
	local res
	
	local weapon = getRandomWeaponFromCrate(crateName)
	if not weapon then return end

	if inventory[weapon] ~= nil then
		LevelSystem.AddExp(plr, DUPLICATE_EXP, "Duplicate ".. weapon)
		res = "duplicate"
	else
		--TODO: create a writeLib for this
		DataManager.SetData(plr, {"Inventory", weapon}, {
			Level = 1,
			Exp = 0,
			ExpRequired = 100,
		})
		res = "new"
	end
	
	DataManager.TableRemove(plr, {"Crates"}, crateName)
	
	return res, weapon
end

function CrateService.OpenCrate(plr : Player, crateName : string) : (string?, string?)
	local crates = DataManager.GetData(plr, {"Crates"})
	
	if not table.find(crates, crateName) then return false end
	
	return CrateService.Roll(plr, crateName)
end

function CrateService:Init(Properties)
	
	Remotes.AddCrate.OnServerEvent:Connect(function(plr : Player, ...)
		DataManager.TableInsert(plr, {"Crates"}, ...)
	end)
	Remotes.OpenCrate.OnServerInvoke = CrateService.OpenCrate
end

return CrateService
