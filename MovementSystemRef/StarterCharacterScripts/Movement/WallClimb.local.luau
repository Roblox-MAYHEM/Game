local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid")
local RootPart : BasePart = Character:WaitForChild("HumanoidRootPart")
local Climb = Humanoid:LoadAnimation(script:WaitForChild("Climb"))
local ClimbLeft = Humanoid:LoadAnimation(script:WaitForChild("ClimbLeft"))
local ClimbRight = Humanoid:LoadAnimation(script:WaitForChild("ClimbRight"))
local JumpoffAnimationOJSFLHSF = Humanoid:LoadAnimation(script:WaitForChild('JumpOff'))
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

ClimbLeft.Priority = Enum.AnimationPriority.Action3
ClimbRight.Priority = Enum.AnimationPriority.Action3
Climb.Priority = Enum.AnimationPriority.Action2

local Velocity
local DB = false
local climbCount = 0
local MAX_CLIMBS = 2
local SlideSpeed = 6
local HoldingSpace = false

local RAY_LENGTH = 2.5
local MIN_FACING_DOT = 0.6 
local MAX_NORMAL_Y = 0.2
local ClimbingEtime = 0

-- reset all the climbs
local function ResetClimbs()
	climbCount = 0
end

-- force the player to shove their face in the wall :fire: :fire:
local function FaceWall(normal)
	local lookCF = CFrame.lookAt(RootPart.Position, RootPart.Position + -normal)
	local _, y, _ = lookCF:ToOrientation()
	local targetCF = CFrame.new(RootPart.Position) * CFrame.Angles(0, y, 0)
	local tween = TweenService:Create(RootPart, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {  })
	Character:SetAttribute("ShiftRotate", false)
	Character.HumanoidRootPart.CFrame = targetCF * CFrame.new(0,0,0.5)
end

-- cleanup the velos
local function cleanupVelocity()
	if Velocity then
		Velocity:Destroy()
		Velocity = nil
	end
end

-- Stop the climb
local function Stop()
	cleanupVelocity()
	Climb:Stop()
	ClimbLeft:Stop()
	ClimbRight:Stop()
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	DB = false
	task.delay(0.25,function()
		Character:SetAttribute("ShiftRotate", true)
	end)
	if script.Parent:FindFirstChild("WallRunnable") then
		script.Parent.WallRunnable.Value = true
	end
	if script.Parent:FindFirstChild("Wallclimbing") then
		script.Parent.Wallclimbing.Value = false
	end
	script.Wallclimb:Stop()
	if ClimbingEtime < 2.5 then 
		ClimbingEtime = 0
		return
	end
	ClimbingEtime = 0
end

-- Jump back instead of a plain release
local function JumpBack()
	RootPart.AssemblyLinearVelocity = Vector3.zero
	game["Run Service"].PostSimulation:Wait()
	local Velocity = Instance.new('BodyVelocity',RootPart)
	Velocity.Velocity = RootPart.CFrame.LookVector * -80
	Velocity.MaxForce = Vector3.new(1,1,1) * 1000000000
	game.Debris:AddItem(Velocity,0.1)
end

--play animations depending on where the player is looking
local function PlaySideAnim()
	local Camera = workspace.CurrentCamera
	local relative = RootPart.CFrame:ToObjectSpace(Camera.CFrame)
	local _, y, _ = relative:ToOrientation()
	if y > math.rad(15) then
		if not ClimbRight.IsPlaying then
			ClimbLeft:Stop()
			ClimbRight:Play()
		end
	elseif y < -math.rad(15) then
		if not ClimbLeft.IsPlaying then
			ClimbRight:Stop()
			ClimbLeft:Play()
		end
	else
		ClimbLeft:Stop()
		ClimbRight:Stop()
	end
end
--check if the wall can be climbed
local function isClimbable(hitResult)
	if not hitResult then print('cant cuz hit not there') return false end
	local normal = hitResult.Normal
	local instance = hitResult.Instance
	if not instance or (instance:IsA("BasePart") and instance.CanCollide == false) then print('cant cuz part not correct loll') return false end
	if math.abs(normal.Y) > MAX_NORMAL_Y then print('cant cuz plr not turn')return false end
	local facingDot = RootPart.CFrame.LookVector:Dot(-normal)
	if facingDot < MIN_FACING_DOT then print('cant cuz uh cant idk why but cant for hte sake of cant so cant cuz no cant and ets cansfhuajafsd') return false end
	return true
end

-- star of the show(main function)
local function Start()
	--some other climbable stuff
	if script.Parent.Wallrunning.Value then print('cant cuz wall') return end
	if DB or climbCount >= MAX_CLIMBS then print('cant cuz w') return end
	DB = true
	HoldingSpace = true

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {Character,unpack(game.CollectionService:GetTagged("NODETECTION"))}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local result = workspace:Raycast(RootPart.Position, RootPart.CFrame.LookVector * RAY_LENGTH, params)
	if not result or not isClimbable(result) then
		DB = false
		return
	end
	-- setup the climb
	climbCount += 1

	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	cleanupVelocity()
	
	Velocity = Instance.new("BodyVelocity") 
	Velocity.MaxForce = Vector3.new(1,1,1) * 1e6
	Velocity.Parent = RootPart
	
	Humanoid.AutoRotate = false
	Climb:Play()
	
	local Momentum = math.clamp(Humanoid.WalkSpeed,4,38.5)
	script.Parent.Wallclimbing.Value = true
	FaceWall(result.Normal)
	repeat script:SetAttribute("Climbing",true) until script:GetAttribute("Climbing")
	
	local con2 = Climb:GetMarkerReachedSignal("Step"):Connect(function()
		script.Wallclimb:Play()
	end)
	
	-- main post simulation loop/event
	
	local conn
	conn = RunService.PostSimulation:Connect(function(dt)
		-- holy returns :sob:
		params.FilterDescendantsInstances = {Character,game.CollectionService:GetTagged("NODETECTION")}
		script.Parent.Vault:GetAttribute("Vaultable",false)
		if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then conn:Disconnect() return end
		if not HoldingSpace then return end
		if script:GetAttribute("Climbing") == false then conn:Disconnect() return end
		if not Velocity then return end
		
		local check = workspace:Raycast(RootPart.Position, RootPart.CFrame.LookVector * RAY_LENGTH, params)
		if not check or not isClimbable(check) then
			HoldingSpace = false
			return
		end
		
		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			conn:Disconnect()
			Climb:Stop()
			ClimbLeft:Stop()
			ClimbRight:Stop()
			climbCount = 0
			task.wait(0.1)
			return
		end
		
		script:SetAttribute("Climbing",true)
		Character:SetAttribute("ShiftRotate", false)
		PlaySideAnim()
		
		ClimbingEtime += 10 * dt
		
		if script.Parent.Boosting.Value then
			Stop()
			JumpBack()
			return
		end
		
		if Momentum <= 0 then
			Climb:AdjustSpeed(0)
			while Velocity do
				if script.Parent.Boosting.Value then
					JumpBack()
					break
				end
				local DownRayCheckx = workspace:Raycast(RootPart.Position, RootPart.CFrame.UpVector * -10, params)
				if DownRayCheckx then
					Momentum = 0
					SlideSpeed = 0
					break
				end
				Velocity.Velocity = Vector3.new(0, -SlideSpeed, 0)
				task.wait()
				SlideSpeed += (dt)
			end
			SlideSpeed = 0
			task.wait(0.1)
			return
		end

		Velocity.Velocity = RootPart.CFrame.UpVector * Momentum
		if not check.Instance:HasTag('INFClimb') then
			Momentum -= dt * 16
		end
		Climb:AdjustSpeed(math.clamp(Momentum / 12, 0.25, 1.1))
		script.Wallclimb.PlaybackSpeed = (math.clamp(Momentum / 12, 0.25, 1.1))
	end)
	
	-- finially when were done climing clean up everything and call the stop function
	
	while HoldingSpace and conn.Connected do
		task.wait()
	end
	if conn and conn.Connected then conn:Disconnect() end
	con2:Disconnect()
	ClimbLeft:Stop()
	ClimbRight:Stop()
	Character:SetAttribute("ShiftRotate", true)
	script:SetAttribute("Climbing",false)
	Stop()
	task.delay(1,function()
		script.Parent.Vault:GetAttribute("Vaultable",true)
	end)
end

-- inputs

UserInputService.InputBegan:Connect(function(k, p)
	if p then return end
	if k.KeyCode == Enum.KeyCode.Space and script.Parent.WallRunnable.Value then
		Start()
	end
end)

UserInputService.InputEnded:Connect(function(k)
	if k.KeyCode == Enum.KeyCode.Space then
		HoldingSpace = false
	end
end)

-- states

Humanoid.StateChanged:Connect(function(_, new)
	if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
		ResetClimbs()
	end
end)

-- attributes

script:GetAttributeChangedSignal("Climbable"):Connect(function()
	if script:GetAttribute('Climbable') == false then
		return 
	end
end)

-- manual climb

script.ManualTriggerClimb.Event:Connect(function()
	if Humanoid.RootPart.Anchored then
		repeat Humanoid.RootPart.Anchored = false until not Humanoid.RootPart.Anchored
	end
	print(Humanoid.RootPart.Anchored)
	for i = 1,3,1 do
		RunService.PostSimulation:Wait()
	end
	task.wait()
	Start()		
end)