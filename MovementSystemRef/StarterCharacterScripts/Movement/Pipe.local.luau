--copied form rope and changed logic lol

local Character = script.Parent.Parent
local Humanoid = Character:FindFirstChildOfClass('Humanoid')
local HRP = Humanoid.RootPart
local Head :BasePart = Character:WaitForChild('Head')

local Anim = Humanoid:LoadAnimation(script.IdleAnim)
local UpAnim = Humanoid:LoadAnimation(script.Up)
local DownAnim = Humanoid:LoadAnimation(script.Down)
local UpHoldAnim = Humanoid:LoadAnimation(script.UpHold)

local LeftArm = Character:FindFirstChild("Left Arm")
local RightArm = Character:FindFirstChild("Right Arm")
local LeftMotor = Character.Torso:FindFirstChild("Left Shoulder") 
local RightMotor = Character.Torso:FindFirstChild("Right Shoulder")

local RPara = RaycastParams.new()
RPara.FilterDescendantsInstances = {Character}
RPara.FilterType = Enum.RaycastFilterType.Exclude

--allign the player's HRP to the relative Y
--so you dont just pres space on the up and land down
local function AlignToPipeY(pipeCF, hrpCF)
	local relativeY = hrpCF.Y - pipeCF.Y
	return CFrame.new(pipeCF.X, pipeCF.Y + relativeY, pipeCF.Z)
end

--getpipe(identical to getrope)
local function GetPipe()
	local ClosestDist = math.huge
	local ClosestPipe = nil

	for _, Pipe: BasePart in game.CollectionService:GetTagged("Pipe") do
		local PipePos = Pipe.Position
		local Dist = (PipePos - Character:GetPivot().Position).Magnitude
		if Dist < ClosestDist and Dist < 10 then
			ClosestDist = Dist
			ClosestPipe = Pipe
		end
	end

	if ClosestDist <= 10 then
		return ClosestPipe
	end
end

--movement direction to move along the pipe
local MoveDirection = "N"

local function UpdateMoveDirection()
	local md = Humanoid.MoveDirection
	if md:Dot(Humanoid.RootPart.CFrame.LookVector) >= 0.75 then
		MoveDirection = "W"
	elseif md:Dot(-Humanoid.RootPart.CFrame.LookVector) >= 0.75 then
		MoveDirection = "S"
	elseif md:Dot(-Humanoid.RootPart.CFrame.RightVector) >= 0.75 then
		MoveDirection = "A"
	elseif md:Dot(Humanoid.RootPart.CFrame.RightVector) >= 0.75 then
		MoveDirection = "D"
	else
		MoveDirection = "N"
	end
end

local DB = false

--main stufff
game.UserInputService.JumpRequest:Connect(function()
	if DB then return end
	--if Humanoid:GetState() == Enum.HumanoidStateType.Jumping then return end
	if Humanoid.FloorMaterial == Enum.Material.Air then
		--getpipe
		local Pipe = GetPipe()
		print(Pipe)
		if Pipe == nil then return end
		
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {Character}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		--raycast to see if hte player and the pipe
		--are infront of eachother with no obstacles
		local rayResult = workspace:Raycast(Humanoid.RootPart.Position, (Pipe.Position - Humanoid.RootPart.Position).Unit * 1000000, rayParams)
		
		if rayResult == nil then
			return
		end
		
		if rayResult.Instance ~= Pipe then
			return
		end
		
		HRP.Anchored = true
		Character:SetAttribute("ShiftRotate",false)
		DB = true
		Anim:Play()
		
		--movement loop
		local conn = game["Run Service"].PreSimulation:Connect(function(DT)
			script.Parent.TightRope:SetAttribute("CanDo",false)
			Character:SetAttribute("ShiftRotate",false)
			UpdateMoveDirection()
			local pipeCF = Pipe.CFrame
			local targetPos = AlignToPipeY(pipeCF, HRP.CFrame)
			local Look = HRP.CFrame.LookVector * 0.5
			
			local Cast = workspace:Raycast(HRP.Position + Vector3.new(0,2,0),Look,RPara)
			local Cast2 = workspace:Raycast(HRP.Position + Vector3.new(0, -3, 0),Look,RPara)
			
			--stop anim local func
			local function STOPANIM()
				if Cast == nil then
					if UpHoldAnim.IsPlaying == false then
						UpHoldAnim:Play()
					end
					Anim:Stop()
				else
					UpHoldAnim:Stop()
					if Anim.IsPlaying == false then
						Anim:Play()
					end
				end
				UpAnim:Stop()
				DownAnim:Stop()
				print('stp')
			end
			
			--movement(pretty ez code)
			if MoveDirection == "W" then
				if Cast then
					if UpAnim.IsPlaying == false then
						UpAnim:Play()
					end
					Anim:Stop()
					DownAnim:Stop()
					UpHoldAnim:Stop()
					targetPos = targetPos * CFrame.new(0,18 * DT,0)
				else
					STOPANIM()
				end
			elseif MoveDirection == "S" then
				if Cast2 then
					if DownAnim.IsPlaying == false then
						DownAnim:Play()
					end
					Anim:Stop()
					UpAnim:Stop()
					UpHoldAnim:Stop()
					targetPos = targetPos * CFrame.new(0,-40 * DT,0)
				else
					STOPANIM()
				end
			else
				STOPANIM()
			end
			HRP.CFrame = HRP.CFrame:Lerp((targetPos * CFrame.Angles(0, math.rad(-90), 0)) * CFrame.new(0,0,1), 0.5)
		end)
		--jumpoff
		game.UserInputService.JumpRequest:Wait()
		
		HRP.Anchored = false
		conn:Disconnect()
		Anim:Stop()
		UpAnim:Stop()
		DownAnim:Stop()
		UpHoldAnim:Stop()

		--boost

		local BodyVelocity = Instance.new("BodyVelocity",HRP)
		BodyVelocity.Velocity = workspace.Camera.CFrame.LookVector * 100
		BodyVelocity.MaxForce = Vector3.new(1,1,1) * 100000
		game.Debris:AddItem(BodyVelocity,0.1)
		
		--setup quit
		
		Character:SetAttribute("ShiftRotate",true)
		task.delay(0.1,function()
			script.Parent.TightRope:SetAttribute('CanDo',true)
		end)
		task.wait(3)
		DB = false
	end
end)
