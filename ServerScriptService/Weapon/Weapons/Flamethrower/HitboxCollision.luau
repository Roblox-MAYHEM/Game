local HitboxCollision = {}

local CastParams = OverlapParams.new()
CastParams.FilterType = Enum.RaycastFilterType.Exclude

function HitboxCollision.GetCollisionsInBoundingBox(Origin : CFrame, Size : Vector3, IgnoreList : {Humanoid})
	CastParams.FilterDescendantsInstances = IgnoreList
	local results = workspace:GetPartBoundsInBox(Origin, Size, CastParams)
		
	local humList = {}		

	for _, v in pairs(results) do
		local hum = v.Parent:FindFirstChild("Humanoid")
		if hum then
			table.insert(humList, hum)
		end
	end
	
	return humList
end

function HitboxCollision.GetCollisionsInPart(Part : BasePart, IgnoreHumans : {Humanoid})
	local IgnoreList = {}
	
	if IgnoreHumans then
		local IgnoreList = {}
		for i, v in ipairs(IgnoreHumans) do
			if v:isA("Humanoid") then
				IgnoreList[i] = v.Parent
			end
		end
	end
		
	CastParams.FilterDescendantsInstances = IgnoreList
	local results = workspace:GetPartsInPart(Part, CastParams)
	local humList = {}		

	for _, v in pairs(results) do
		local hum = v.Parent:FindFirstChild("Humanoid")
		if hum and not table.find(humList, hum) then
			table.insert(humList, hum)
		end
	end
		
	return humList
end

return HitboxCollision
