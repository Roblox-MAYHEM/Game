--VAULTING TROUGEH THE SKY
local Humanoid = script.Parent.Parent:FindFirstChildOfClass("Humanoid")
local Anim = Humanoid:LoadAnimation(script.Vault)
local Mantle = Humanoid:LoadAnimation(script.Mantle)
local Spring = Humanoid:LoadAnimation(script.Spring)

local UIS = game:GetService("UserInputService")

local Vaulting = false
local TooLongInAir = false
local TimeSinceInAir = tick()
local InAir = false

Anim.Looped = false
Mantle.Looped = false
Spring.Looped = false

Anim.Priority = Enum.AnimationPriority.Movement
Mantle.Priority = Enum.AnimationPriority.Movement
Spring.Priority = Enum.AnimationPriority.Action
-- air(scrapped i think)
Humanoid:GetPropertyChangedSignal('FloorMaterial'):Connect(function()
	InAir = (Humanoid.FloorMaterial == Enum.Material.Air)
	if InAir then
		TimeSinceInAir = tick()
	else
		TooLongInAir = false
	end
end)

-- time in air(scrapped)

game["Run Service"].RenderStepped:Connect(function()
	if InAir then
		task.wait()
		local Time = tick() - TimeSinceInAir
		if Time >= 0.6 then
			TooLongInAir = true
		else
			TooLongInAir = false
		end
	end
end)

-- backup code dont touch

--[[UIS.JumpRequest:Connect(function()
	if Vaulting then return end
	if Humanoid.FloorMaterial == Enum.Material.Air then return end
	if Humanoid.WalkSpeed ~= 35 or Humanoid.MoveDirection.Magnitude < 0.1 then return end
	
	local Params = RaycastParams.new()
	Params.RespectCanCollide = true
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Humanoid.Parent}

	local Raycast = workspace:Raycast(Humanoid.RootPart.Position + Vector3.new(0, -3, 0), Humanoid.RootPart.CFrame.LookVector * 10, Params)
	local HeadRaycast = workspace:Raycast(Humanoid.Parent.Head.Position, Humanoid.Parent.Head.CFrame.LookVector * 10, Params)

	if not HeadRaycast and Raycast then
		Vaulting = true
		Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		Raycast.Instance.CanCollide = false
		local Velocity = Instance.new('BodyVelocity',Humanoid.RootPart)
		Velocity.Velocity = (Humanoid.RootPart.CFrame.LookVector) * 60--(Humanoid.RootPart.CFrame.LookVector + (Humanoid.RootPart.CFrame.UpVector * 0.4)) * 40
		Velocity.MaxForce = Vector3.new(1,1,1) * 10000000
		game.Debris:AddItem(Velocity,0.1)
		
		Anim:Play()
		local JumpConnection
			
		JumpConnection = UIS.InputBegan:Once(function(Input)
			if Input.KeyCode ~= Enum.KeyCode.Space then return end
			Anim:Stop()
			Velocity:Destroy()
			Spring:Play()
			local Velocity = Instance.new('BodyVelocity',Humanoid.RootPart)
			Velocity.Velocity = (Humanoid.RootPart.CFrame.LookVector* 0.4 + (Humanoid.RootPart.CFrame.UpVector * 0.75)) * 100
			Velocity.MaxForce = Vector3.new(1,1,1) * 10000000
			game.Debris:AddItem(Velocity,0.1)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			Vaulting = false
			JumpConnection:Disconnect()
		end)
		task.delay(0.3,function()
			JumpConnection:Disconnect()
		end)
		Anim.Stopped:Wait()
		JumpConnection:Disconnect()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		Vaulting = false
		Raycast.Instance.CanCollide = true
	else
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)]]


local camanim = require("./CameraMovement")

UIS.JumpRequest:Connect(function()
	-- holy returns #2
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then return end
	if Vaulting then return end
	if script.Parent.Wallrunning.Value then return end
	if script:GetAttribute("Vaultable") == false then return end
	if InAir then return end
	if Humanoid.WalkSpeed < 28 or Humanoid.MoveDirection.Magnitude < 0.1 then return end
	
	local Params = RaycastParams.new()
	Params.RespectCanCollide = true
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Humanoid.Parent,game.CollectionService:GetTagged("NODETECTION")}
	local Distance = 10
	
	local PastCastD = (Humanoid.RootPart.CFrame.LookVector * Distance) + (Humanoid.RootPart.CFrame.UpVector * -2)
	
	local Raycast2cloose = workspace:Raycast(Humanoid.RootPart.Position + Vector3.new(0, 0.1, 0), Humanoid.RootPart.CFrame.LookVector * 3, Params)
	
	local Raycast = workspace:Raycast(Humanoid.RootPart.Position + Vector3.new(0, -0.6, 0), Humanoid.RootPart.CFrame.LookVector * Distance, Params)
	local HeadRaycast = workspace:Raycast(Humanoid.Parent.Head.Position + Vector3.new(0,1,0), Humanoid.Parent.Head.CFrame.LookVector * Distance, Params)
	local PastRaycast = workspace:Raycast(Humanoid.Parent.Head.Position + Vector3.new(0,1,0), PastCastD , Params)
	--check if the part is vaultable(the head ray passes but the body ray detects)
	if not HeadRaycast and Raycast then
		camanim:BopDOWN(8,false)
		script.VaultSFX:Play()
		Vaulting = true
		Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		--Raycast.Instance.CanCollide = false
		
		local Canim
		
		local MultiplyAmount = 0.5
		--change of anims
		if PastRaycast then
			Mantle:Play()
			Canim = Mantle
		else
			Canim = Anim
			Anim:Play()
		end
		--if ray too close then back up a little to not bump
		if Raycast2cloose then
			local VelocityBack = Instance.new('BodyVelocity',Humanoid.RootPart)
			VelocityBack.Velocity = (-Humanoid.RootPart.CFrame.LookVector) * 50
			VelocityBack.MaxForce = Vector3.new(1,1,1) * 10000000
			game.Debris:AddItem(VelocityBack,0.01)

			task.wait(0.01)

			if VelocityBack then
				VelocityBack:Destroy()
			end
		end
		-- velocitys
		local Velocity = Instance.new('BodyVelocity',Humanoid.RootPart)
		Velocity.Velocity = (Humanoid.RootPart.CFrame.LookVector * 0.5 + (Humanoid.RootPart.CFrame.UpVector * 0.425)) * 75
		Velocity.MaxForce = Vector3.new(1,1,1) * 10000000
		game.Debris:AddItem(Velocity,0.1)
		
		task.delay(0.3,function()
			-- vault jump
			if not game.UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
			Anim:Stop()
			Velocity:Destroy()
			script.Jump:Play()
			Spring:Play()
			local Velocity = Instance.new('BodyVelocity',Humanoid.RootPart)
			Velocity.Velocity = (Humanoid.RootPart.CFrame.LookVector* 0.4 + (Humanoid.RootPart.CFrame.UpVector * 0.5)) * 100
			Velocity.MaxForce = Vector3.new(1,1,1) * 10000000
			game.Debris:AddItem(Velocity,0.1)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			Vaulting = false
			task.wait(0.65)
			Spring:Stop(0.3)
		end)
		--end
		Canim.Stopped:Wait()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		Vaulting = false
	else
		--Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)