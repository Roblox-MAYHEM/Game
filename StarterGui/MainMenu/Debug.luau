local module = {}

function module:Init()
	local DebugUI = script.Parent

	local Remotes = game:GetService("ReplicatedStorage").Events

	local panel = DebugUI.Panel 

	panel.AddXP.MouseButton1Click:Connect(function()
		Remotes.AddExp:FireServer(40)
	end)

	panel.Reset.MouseButton1Click:Connect(function()
		Remotes.ResetAll:FireServer()
	end)
	
	panel.AddShotgunXP.MouseButton1Click:Connect(function()
		Remotes.AddWeaponExp:FireServer("DBShotgun", 40)
	end)
	
	panel.ResetShotgunLvl.MouseButton1Click:Connect(function()
		Remotes.ResetWeaponLvl:FireServer("DBShotgun")
	end)
	
	panel.AddCrate.MouseButton1Click:Connect(function()
		local res = Remotes.AddCrate:FireServer("StarterCrate")
	end)

	panel.StockInventory.MouseButton1Click:Connect(function()
		Remotes.StockInventory:FireServer()
	end)
	
	panel.ClearInventory.MouseButton1Click:Connect(function()
		Remotes.ClearInventory:FireServer()
	end)
end

return module
