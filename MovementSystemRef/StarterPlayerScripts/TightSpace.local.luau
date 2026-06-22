local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Humanoid.RootPart
local OGRootJ = Root.RootJoint.C0

local Zone = require(game.ReplicatedStorage.Packages.Zone)

local function MAIN(TightModel)
	local Start = TightModel:WaitForChild("Start")
	local EndPart = TightModel:WaitForChild("End")
	local AnimFolder = TightModel:WaitForChild("Animations")
	
	if not Start or not EndPart then
		return
	end

	local Idle = Humanoid:LoadAnimation(AnimFolder.Idle)
	local Left = Humanoid:LoadAnimation(AnimFolder.Left)
	local Right = Humanoid:LoadAnimation(AnimFolder.Right)

	local StartZone = Zone.new(Start)
	local EndZone = Zone.new(EndPart)

	local function SetupPrompt(Prompt, FromPart, ToPart)
		if not Prompt then
			warn("Missing ProximityPrompt in:", FromPart.Name)
			return
		end

		Prompt.Triggered:Connect(function(promptPlayer)
			if promptPlayer ~= Player then return end
			Idle = Humanoid:LoadAnimation(AnimFolder.Idle)
			Left = Humanoid:LoadAnimation(AnimFolder.Left)
			Right = Humanoid:LoadAnimation(AnimFolder.Right)
			
			Prompt.Enabled = false

			for _ = 1, 3 do
				Root.RootJoint.C0 = OGRootJ
			end

			Root.Anchored = true
			Humanoid.AutoRotate = false
			Character:SetAttribute("ShiftRotate", false)
			
			local offsetX = (FromPart == Start) and 2 or -2
			local INITIAL_OFFSET = CFrame.new(offsetX, 0, 0)
			
			local Alpha = 0.1
			
			for i = Alpha,1,Alpha do
				local CF = FromPart.CFrame * CFrame.new(INITIAL_OFFSET.X, -FromPart.Size.Y/2, INITIAL_OFFSET.Z)
				local Lerp = Character:GetPivot():Lerp(CF, i)
				Character:PivotTo(Lerp)
				task.wait()
			end

			local MoveDirection = "N"
			local function UpdateMoveDirection()
				local TunnelCF = FromPart.CFrame
				local md = Humanoid.MoveDirection
				if md:Dot(TunnelCF.LookVector) >= 0.75 then
					MoveDirection = "W"
				elseif md:Dot(-TunnelCF.LookVector) >= 0.75 then
					MoveDirection = "S"
				elseif md:Dot(-TunnelCF.RightVector) >= 0.75 then
					MoveDirection = "A"
				elseif md:Dot(TunnelCF.RightVector) >= 0.75 then
					MoveDirection = "D"
				else
					MoveDirection = "N"
				end
			end

			local function Render(delta)
				Character.Values.TightSpace.Value = true
				Root.RootJoint.C0 = OGRootJ

				Start.ProximityPrompt.Enabled = false
				EndPart:FindFirstChildOfClass("ProximityPrompt").Enabled = false

				UpdateMoveDirection()

				local TunnelCF = FromPart.CFrame
				if MoveDirection == "N" then
					if not Idle.IsPlaying then Idle:Play() end
					Left:Stop()
					Right:Stop()
				elseif MoveDirection == "A" then
					if not Right.IsPlaying then Right:Play() end
					Idle:Stop()
					Left:Stop()
					Root.CFrame += TunnelCF.RightVector * -(6 * delta)
				elseif MoveDirection == "D" then
					if not Left.IsPlaying then Left:Play() end
					Idle:Stop()
					Right:Stop()
					Root.CFrame += TunnelCF.RightVector * (6 * delta)
				end
			end

			local RenderConnection
			local StartConn, EndConn
			local function EXIT(player, partHit)
				if player ~= Player then return end
				Start.ProximityPrompt.Enabled = true
				EndPart.ProximityPrompt.Enabled = true
				if RenderConnection then RenderConnection:Disconnect() end
				if StartConn then StartConn:Disconnect() end
				if EndConn then EndConn:Disconnect() end

				Character:PivotTo(
					partHit.CFrame * CFrame.new(0, (-partHit.Size.Y/2) + 0.5, 0)
				)

				Humanoid.AutoRotate = true
				Root.Anchored = false
				Character:SetAttribute("ShiftRotate", true)
				Character.Values.TightSpace.Value = false

				Idle:Stop()
				Left:Stop()
				Right:Stop()
				Idle:Destroy()
				Left:Destroy()
				Right:Destroy()
				Prompt.Enabled = true
			end

			RenderConnection = RunService.RenderStepped:Connect(Render)
			StartConn = StartZone.playerEntered:Connect(function(p) EXIT(p, Start) end)
			EndConn = EndZone.playerEntered:Connect(function(p) EXIT(p, EndPart) end)
		end)
	end
	
	SetupPrompt(Start:FindFirstChildOfClass("ProximityPrompt"), Start, EndPart)
	SetupPrompt(EndPart:FindFirstChildOfClass("ProximityPrompt"), EndPart, Start)
end

for _, TightModel in ipairs(CollectionService:GetTagged("TIGHTSPACE")) do
	task.defer(function() MAIN(TightModel) end)
end

CollectionService:GetInstanceAddedSignal("TIGHTSPACE"):Connect(function(model)
	MAIN(model)
end)

Player.CharacterRemoving:Connect(function()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Humanoid.RootPart
	
end)