local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage 		= game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players 			= game:GetService("Players")

local Remotes 		= ReplicatedStorage.Events

local DataManager = require(ServerScriptService.Data.DataManager)
local LevelProgression = require(ReplicatedStorage.Data.LevelProgression)

local LevelSystem = {}

function LevelSystem.ExpForLvl(level : number)
	return math.round(math.pow(1.1, level-1)*10) * 10
end

function LevelSystem.ExpForWeaponLvl(level : number)
	return math.round(math.pow(1.5, level-1)) * 50
end

local get = DataManager.GetData
local set = DataManager.SetData
local tableInsert = DataManager.TableInsert

function LevelSystem.LevelUp(plr : Player)
	local level = get(plr, {"Level"}) + 1
	
	if LevelProgression[level] then
		tableInsert(plr, {"Crates"}, LevelProgression[level])
	end
	
	set(plr, {"Level"}, level)
	set(plr, {"ExpRequired"}, LevelSystem.ExpForLvl(level))
	set(plr, {"Exp"}, 0)
end

function LevelSystem.AddExp(plr : Player, amt : number, msg : string?)
	local exp = get(plr, {"Exp"})
	local level = get(plr, {"Level"})
	
	exp += amt
	
	while exp >= LevelSystem.ExpForLvl(level) do
		exp -= LevelSystem.ExpForLvl(level)
		LevelSystem.LevelUp(plr)
	end
	
	set(plr, {"Exp"}, exp)
	
	Remotes.ExpUpdated:FireClient(plr, amt, msg)
end

function LevelSystem.LevelWeaponUp(plr : Player, weapon : string)
	local level = get(plr, {"Inventory",weapon, "Level"}) + 1
	
	LevelSystem.AddExp(plr, 40, "Weapon level up to lvl ".. level)
	
	set(plr, {"Inventory",weapon, "Level"}, level)
	set(plr, {"Inventory",weapon, "ExpRequired"}, LevelSystem.ExpForWeaponLvl(level))
	set(plr, {"Inventory",weapon, "Exp"}, 0)
end

function LevelSystem.AddWeaponExp(plr : Player, weapon : string, amt : number)
	local exp = get(plr, {"Inventory",weapon, "Exp"})
	local level = get(plr, {"Inventory",weapon, "Level"})
	
	exp += amt
		
	while exp >= LevelSystem.ExpForWeaponLvl(level) do
		exp -= LevelSystem.ExpForWeaponLvl(level)
		LevelSystem.LevelWeaponUp(plr, weapon)
	end
	
	set(plr, {"Inventory",weapon, "Exp"}, exp)
end

function LevelSystem.AwardKill(Killer : Player, PlayerKilled : Player)
	LevelSystem.AddExp(Killer, 40, "Killed " .. PlayerKilled.Name)

	for _, w in get(Killer, {"Hotbar"}) do
		LevelSystem.AddWeaponExp(Killer, w, 30)
	end
end

function LevelSystem.AwardAssist(Assist : Player, PlayerKilled : Player)
	LevelSystem.AddExp(Assist, 10, "Assisted " .. PlayerKilled.Name)
end

return LevelSystem
