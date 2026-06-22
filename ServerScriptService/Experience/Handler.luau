local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Remotes = RS.Events

local DataManager = require(SSS.Data.DataManager)
local LevelSystem = require(SS.Libraries.LevelSystem)

local ExpHandler = {}

function ExpHandler:Init(Properties)

	--// command prompt features. Can move to separate area in future
	Remotes.SetLevel.OnServerEvent:Connect(function(plr : Player, level : number)
		DataManager.SetData(plr, {"Level"}, level)
		DataManager.SetData(plr, {"ExpRequired"}, LevelSystem.ExpForLvl(level))
		DataManager.SetData(plr, {"Exp"}, 0)
		
	end)
	
	Remotes.ResetAll.OnServerEvent:Connect(DataManager.ClearData)

	Remotes.AddExp.OnServerEvent:Connect(function(plr : Player, amt : number, msg : string)
		LevelSystem.AddExp(plr, amt, msg)
	end)
	
	Remotes.AddWeaponExp.OnServerEvent:Connect(function(plr : Player, weapon : string, amt : number)
		LevelSystem.AddWeaponExp(plr, weapon, amt)
	end)
	
	Remotes.ResetWeaponLvl.OnServerEvent:Connect(function(plr : Player, weapon : string)
		DataManager.SetData(plr, {"Inventory",weapon, "Level"}, 0)
		DataManager.SetData(plr, {"Inventory",weapon, "ExpRequired"}, LevelSystem.ExpForLvl(0))
		DataManager.SetData(plr, {"Inventory",weapon, "Exp"}, 0)
	end)
	
	Remotes.StockInventory.OnServerEvent:Connect(function(plr : Player)
		local list = {}
		for i,v in pairs(require(RS.Assets.Weapons.List)) do
			list[v] = {
				Level = 1,
				Exp = 0,
				ExpRequired = 100,
			}
		end
		DataManager.SetData(plr, {"Inventory"}, list)
	end)
	
	Remotes.ClearInventory.OnServerEvent:Connect(function(plr : Player)
		DataManager.SetData(plr, {"Inventory"}, {})
	end)
end

return ExpHandler
