--comments are almost as same as the pipe script meh
local Character = script.Parent.Parent
local Humanoid = Character:FindFirstChildOfClass('Humanoid')
local Rootpart = Humanoid.RootPart
local Anim = Humanoid:LoadAnimation(script.RopeAnim)
local LeftArm = Character:FindFirstChild("Left Arm")
local RightArm = Character:FindFirstChild("Right Arm")
local LeftMotor = Character.Torso:FindFirstChild("Left Shoulder") 
local RightMotor = Character.Torso:FindFirstChild("Right Shoulder")

local function GetRope()
	local ClosestDist = math.huge
	local ClosestRope = nil
	
	--task.desynchronize()
	
	for _, Rope: Model in game.CollectionService:GetTagged("RopeModel") do
		local RopePos = Rope.DownPart.Position
		local Dist = (RopePos - Character:GetPivot().Position).Magnitude
		if Dist < ClosestDist then
			ClosestRope = Rope
			ClosestDist = Dist
		end
	end
	
	--task.synchronize()

	if ClosestDist <= 10 then
		return ClosestRope
	end
end

local DB = false

game.UserInputService.JumpRequest:Connect(function()
	print('yo')
	if DB then return end
	if Humanoid:GetState() == Enum.HumanoidStateType.Jumping then return end
	if Humanoid.FloorMaterial == Enum.Material.Air then
		local Rope = GetRope()
		print(Rope)
		if Rope == nil then return end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {Character}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local rayResult = workspace:Raycast(Rootpart.Position, (Rope:GetPivot().Position - Rootpart.Position).Unit * 1000000, rayParams)
		if rayResult == nil then
			return
		end
		if rayResult.Instance ~= Rope then
			return
		end
		print('anchor')
		Rootpart.Anchored = true
		Character:SetAttribute("ShiftRotate",false)
		DB = true
		Anim:Play()

		local conn = game["Run Service"].PreSimulation:Connect(function()
			print("FRAME")
			local RopePos = Rope.DownPart.CFrame
			Rootpart.CFrame = Rootpart.CFrame:Lerp((RopePos * CFrame.new(0,3,-1)) * CFrame.Angles(0,math.rad(180),0),0.5)
		end)
		print('wow')
		game.UserInputService.JumpRequest:Wait()
		print('woiw')
		Rootpart.Anchored = false
		conn:Disconnect()
		Anim:Stop()
		local BodyVelocity = Instance.new("BodyVelocity",Rootpart)
		BodyVelocity.Velocity = workspace.Camera.CFrame.LookVector * 100
		BodyVelocity.MaxForce = Vector3.new(1,1,1) * 100000

		game.Debris:AddItem(BodyVelocity,0.1)

		Character:SetAttribute("ShiftRotate",true)
		task.wait(0.1)
		DB = false
	end
end)