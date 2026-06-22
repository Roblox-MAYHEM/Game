local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Remotes           = ReplicatedStorage:WaitForChild("Events")
local Utils             = ReplicatedStorage:WaitForChild("Utils")

local DebugVisualize   = require(Utils.DebugVisualize)
local DamageHandler     = require(script.Parent.DamageHandler)

local function getHumanoid(part)
	local character = part.Parent
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

return function(hitPosition: Vector3, sender: Player, healInfo, ignoreHumanoids: {Humanoid}?)
	-- 1. Visuals
	Remotes.ReplicateEffect:FireAllClients(
		"HealEffect", 
		hitPosition, 
		healInfo.RADIUS, 
		healInfo.DURATION
	)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local filterList = {}
	if ignoreHumanoids then
		for _, hum in ipairs(ignoreHumanoids) do
			if hum.Parent then table.insert(filterList, hum.Parent) end
		end
	end
	params.FilterDescendantsInstances = filterList

	-- Heal loop
	task.spawn(function()
		local endTime = os.clock() + (healInfo.DURATION or 0)

		while os.clock() < endTime do
			-- Spatial Query
			local results = workspace:GetPartBoundsInRadius(hitPosition, healInfo.RADIUS, params)
			local hitThisTick = {} -- Dictionary for O(1) lookup

			for _, part in ipairs(results) do
				local humanoid = getHumanoid(part)

				-- Only heal if we haven't touched this humanoid THIS tick
				if humanoid and not hitThisTick[humanoid] then
					hitThisTick[humanoid] = true

					-- Apply Healing
					DamageHandler.HealHumanoid(humanoid, sender, healInfo.AMOUNT)

					if RunService:IsStudio() then
						DebugVisualize.point(humanoid.Parent.PrimaryPart.Position, Color3.new(0, 1, 0))
					end
				end
			end

			task.wait(healInfo.DELTA or 1)
		end
	end)
end