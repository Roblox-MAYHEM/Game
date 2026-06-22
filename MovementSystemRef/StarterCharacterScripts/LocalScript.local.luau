game.ReplicatedStorage:WaitForChild('GetClientPosition').OnClientInvoke = function()
	return script.Parent.HumanoidRootPart.CFrame
end