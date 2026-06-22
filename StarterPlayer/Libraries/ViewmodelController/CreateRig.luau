local valid = {}

valid[Enum.HumanoidRigType.R6] = {
	"Left Arm", "Right Arm", "Head",
	"Torso", "Left Shoulder", "Right Shoulder", "Neck", "Humanoid", "Animator"
}

d = {} --Throwaway
for i, v in ipairs(valid[Enum.HumanoidRigType.R6]) do
	d[v] = true
end
valid[Enum.HumanoidRigType.R6] = d --Converts entries of valid into keys for booleans

local function createRig(realCharacter)
	local last = realCharacter.Archivable
	realCharacter.Archivable = true
		
	local character = realCharacter:Clone()
	character.Parent = workspace.Camera
	local humanoid = character:WaitForChild("Humanoid")
	
	local lookup = valid[humanoid.RigType]
	for i, v in pairs(lookup) do
		while (not character:FindFirstChild(i, true)) do
			character.DescendantAdded:Wait()
		end
	end
	
	lookup["Body Colors"] = character:FindFirstChild("Body Colors")
	lookup["Shirt"] = character:FindFirstChild("Shirt")
	
	local des = character:GetDescendants()
	for i = 1, #des do
		if (not lookup[des[i].Name] and not des[i]:IsA("CharacterMesh")) then
			des[i]:Destroy()
		elseif (des[i]:IsA("BasePart")) then
			des[i].CanCollide = false
			des[i].Anchored = false
			
			if (des[i].Name == "Right Arm" or des[i].Name == "Left Arm" ) then
				des[i].Size = Vector3.new(0.6,3,0.6)
				
				if lookup["Body Colors"] then
					des[i].Color = lookup["Body Colors"].HeadColor3
				end
				
				if lookup["Shirt"] then
					local sleeves = Instance.new("Decal")
					sleeves.Texture = lookup["Shirt"].ShirtTemplate
					sleeves.Face = Enum.NormalId.Front
					sleeves.Parent = des[i]
				end
			end
		end
	end
	
	character.Head.Anchored = true
	character.Head.Transparency = 1
	character.Torso.Transparency = 1
	
	character.Torso["Left Shoulder"].C1 = CFrame.new(.5, 0, 0) * CFrame.fromEulerAngles(0, math.rad(-90), 0)
	character.Torso["Right Shoulder"].C1 = CFrame.new(-.5, 0, 0) * CFrame.fromEulerAngles(0, math.rad(90), 0)
	
	character.Torso["Left Shoulder"].C0 = CFrame.new(-1, 0.5, 0) * CFrame.fromEulerAngles(0, math.rad(-90), 0)
	character.Torso["Right Shoulder"].C0 = CFrame.new(1, 0.5, 0) * CFrame.fromEulerAngles(0, math.rad(90), 0)
	
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	character.Name = "viewModel"
	
	realCharacter.Archivable = last
	
	--reset for reuse
	lookup["Body Colors"] = nil
	lookup["Shirt"] = nil
	return character
end

return createRig
