local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HealTotem = script.HealLocation.Value


return {
	Play = function(origin : Vector3, radius : number, duration : number)
		local m = HealTotem:Clone()
		m.Parent = workspace
		m:PivotTo(CFrame.new(origin))
	end,
}