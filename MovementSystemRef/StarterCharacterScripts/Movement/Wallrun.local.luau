local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

local Root = Humanoid.RootPart
local Head = Character:WaitForChild("Head")
local Animator = Humanoid:WaitForChild("Animator")

local LrunLeave = Humanoid:LoadAnimation(script.LRunLeave)
local RrunLeave = Humanoid:LoadAnimation(script.RRunLeave)

RrunLeave.Looped = false
LrunLeave.Looped = false

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local RecoveryWindow = 0
local RecoverTimer = 0
local WallJumpStrength = 50
local WallJumpForward = 12
local WallDistance = 3

local RayParams = RaycastParams.new()
RayParams.FilterDescendantsInstances = { Character }
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local Running = false
local WallNormal = nil
local HoldingSpace = false
local Vertical = 0

local Attachment = Instance.new("Attachment")
Attachment.Parent = Root

--create linear velocity

local LinearVel = Instance.new("LinearVelocity")
LinearVel.Attachment0 = Attachment
LinearVel.MaxForce = math.huge
LinearVel.RelativeTo = Enum.ActuatorRelativeTo.World
LinearVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
LinearVel.Enabled = false
LinearVel.Parent = Root

local LeftAnim = Humanoid:LoadAnimation(script.LRun)
local RightAnim = Humanoid:LoadAnimation(script.RRun)
local CurrentAnim = nil
local Wallruns = 0
local MAX_WALLRUNS = 3

LeftAnim.Priority = Enum.AnimationPriority.Action4
RightAnim.Priority = Enum.AnimationPriority.Action4
LrunLeave.Priority = Enum.AnimationPriority.Movement
RrunLeave.Priority = Enum.AnimationPriority.Movement

local function CheckWall(Direction, DeltaTime)
	local Offset = Root.AssemblyLinearVelocity * DeltaTime
	local Result = workspace:Raycast(Root.Position + Offset, Direction * WallDistance, RayParams)
	if Result and Result.Instance and Result.Instance.CanCollide then
		return Result.Normal
	end
end


UserInputService.InputBegan:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Space then
		HoldingSpace = true
	end
end)


UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Space then
		HoldingSpace = false
	end
end)

local LastDir

-- Walljump function

local function WallJump()
	if not Running or not WallNormal then
		return
	end
	script.Parent.Wallrunning.Value = false
	Character:SetAttribute("ShiftRotate", true)
	LinearVel.Enabled = false

	if CurrentAnim then
		if CurrentAnim == LeftAnim then
			LastDir = 1
		elseif CurrentAnim == RightAnim then
			LastDir = -1
		end
		CurrentAnim:Stop()
		CurrentAnim = nil
	end
	
	Running = false
	Humanoid.AutoRotate = true
	Character:SetAttribute("ShiftRotate", true)
	Vertical = 0

	local Forward = Root.CFrame.LookVector * WallJumpForward
	local PushDirection = Camera.CFrame.LookVector

	local JumpVelocity = Instance.new("BodyVelocity")
	JumpVelocity.Velocity = (PushDirection * WallJumpStrength) + Forward
	JumpVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
	JumpVelocity.Parent = Root

	game.Debris:AddItem(JumpVelocity, 0.1)
	
	if LastDir == 1 then
		LrunLeave:Play()
	elseif LastDir == -1 then
		RrunLeave:Play()
	end
	
	task.wait(0.15)
end

-- main presim loop lol
RunService.PreSimulation:Connect(function(DeltaTime)
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then return end
	RayParams.FilterDescendantsInstances = {Character,unpack(game.CollectionService:GetTagged("NODETECTION"))}
	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		LinearVel.Enabled = false

		if CurrentAnim then
			CurrentAnim:Stop()
			CurrentAnim = nil
		end

		Running = false
		RecoverTimer = 0
		Vertical = 0
		Wallruns = 0
		script.Parent.Wallrunning.Value = false
		return
	end
	if not Running and Wallruns >= MAX_WALLRUNS then return end
	script.Parent.Vault:GetAttribute("Vaultable",false)
	-- check for walls
	local RightWall = CheckWall(Root.CFrame.RightVector, DeltaTime)
	local LeftWall = CheckWall(-Root.CFrame.RightVector, DeltaTime)
	local WallHit = RightWall or LeftWall
	
	-- get the correct offset vector
	
	local frontoffsetmultiplyF = 2
	
	if RightWall then
		frontoffsetmultiplyF = -frontoffsetmultiplyF
	end
	
	local FrontHit = workspace:Raycast(Root.Position, (Root.CFrame.LookVector * 1.65) + (Root.CFrame.RightVector * frontoffsetmultiplyF), RayParams)
	
	-- detect if wall infront so you dont bump into a wall
	
	if FrontHit and FrontHit.Instance and FrontHit.Instance.CanCollide then
		--check if already climbing
		if not script.Parent.WallClimb:GetAttribute('Climbing') and Running then
			Humanoid.RootPart.Anchored = true
			task.wait()
			Humanoid.RootPart.Anchored = false
			--manual trigger wallclimb
			script.Parent.WallClimb.ManualTriggerClimb:Fire()
		end
		--setup for stopping the wallrun
		LinearVel.Enabled = false
		if CurrentAnim then
			CurrentAnim:Stop()
			CurrentAnim = nil
		end
		Running = false
		Humanoid.AutoRotate = true
		Character:SetAttribute("ShiftRotate", true)
		Vertical = 0
		script.Parent.Wallrunning.Value = false
		return
	end
	
	-- gud gud wallrun
	if WallHit and HoldingSpace then
		--disable shiftrotate so you stick to the wall
		Character:SetAttribute("ShiftRotate", false)
		
		--find the camera orientation Y relative to the root
		
		local Camera = workspace.CurrentCamera
		local relative = Root.CFrame:ToObjectSpace(Camera.CFrame)
		local _, y, _ = relative:ToOrientation()
		
		RecoverTimer = 0

		if not Running then
			Running = true
			WallNormal = WallHit
			Vertical = 32

			Humanoid.AutoRotate = false
			script.Parent.WallClimb:SetAttribute("Climbable",false)
			Character:SetAttribute("ShiftRotate", false)
			
			-- play anims
			if RightWall then
				CurrentAnim = RightAnim
			elseif LeftWall then
				CurrentAnim = LeftAnim
			end

			if CurrentAnim then
				CurrentAnim:Play()
			end

			LinearVel.Enabled = true
		end
		
		script.Parent.Wallrunning.Value = true
		
		Vertical -= 18 * DeltaTime
		
		--lwk the curved wallrun stuff
		local Look = Root.CFrame.LookVector
		local WallDir = (Look - Look:Dot(WallHit) * WallHit).Unit
		
		LinearVel.VectorVelocity = WallDir * Humanoid.WalkSpeed + Vector3.new(0, Vertical, 0)
		
		--making the palyer STICK to the wall
		
		local Forward
		local Up = Vector3.new(0, 1, 0)
		
		local Right = WallDir:Cross(Up).Unit
		Forward = Up:Cross(Right).Unit
		
		local TargetCFrame = CFrame.fromMatrix(Root.Position, Right, Up)
		Root.CFrame = Root.CFrame:Lerp(TargetCFrame, DeltaTime * 10)
		Character:SetAttribute("ShiftRotate", false)
	else
		if Running then
			-- reset stuff
			RecoverTimer += DeltaTime
			if RecoverTimer >= RecoveryWindow then
				LinearVel.Enabled = false

				if CurrentAnim then
					if CurrentAnim == LeftAnim then
						LastDir = 1
					elseif CurrentAnim == RightAnim then
						LastDir = -1
					end
					CurrentAnim:Stop()
					CurrentAnim = nil
				end

				Running = false
				Humanoid.AutoRotate = true
				Character:SetAttribute("ShiftRotate", true)
				Vertical = 0
				RecoverTimer = 0
				script.Parent.Wallrunning.Value = false
			end
		end
	end
end)

--inputs

UserInputService.InputEnded:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Space then
		if Running then
			WallJump()
		end
		HoldingSpace = false
		task.delay(0.5,function()
			script.Parent.Vault:GetAttribute("Vaultable",true)
		end)
		script.Parent.WallClimb:SetAttribute("Climbable",true)
	end
end)

-- air detection i guess

Humanoid:GetPropertyChangedSignal('FloorMaterial'):Connect(function()
	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		LrunLeave:Stop()
		RrunLeave:Stop()
		RightAnim:Stop()
		LeftAnim:Stop()
	end
end)

-- wallrun attribute or wtv

script.Parent.Wallrunning.Changed:Connect(function(Value)
	if not Value then return end
	Wallruns += 1
	task.delay(0.5,function()
		script.Parent.Vault:SetAttribute("Vaultable",true)
	end)
	script.Parent.WallClimb:SetAttribute("Climbable",true)
	Character:SetAttribute("ShiftRotate", true)
end)