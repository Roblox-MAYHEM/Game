local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Character = script.Parent.Parent
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local RootPart = Humanoid and Humanoid.RootPart
local DB = false
local LeanValue = 0
local LeanSpeed = 0.85
local LeanDirection = -1
local Limit = 0.7
local MOVEMENTFOLDER = script.Parent.Parent:WaitForChild('Movement')

local Anim = Humanoid:LoadAnimation(script.TightropeWalkAnimation)
Anim:AdjustSpeed(1.4)
-- A or D to contrl your lean 
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.A then
		LeanDirection = -1
	elseif input.KeyCode == Enum.KeyCode.D then
		LeanDirection = 1
	end
end)

-- star of the show HELL YEAH
RunService.RenderStepped:Connect(function(dt)
	--task.synchronize()
	--Holy Returns #3
	if not script:GetAttribute("CanDo") then return end
	if MOVEMENTFOLDER.Wallrunning.Value
		or MOVEMENTFOLDER.WallClimb:GetAttribute("Climbing")
		or script.Parent.Parent.RagdollTrigger.Value 
		or script.Parent.Parent.Values.TightSpace.Value
		or MOVEMENTFOLDER.LedgeClimb:GetAttribute("CLIMBINGLEDGE") then
		return
	end
	if DB or not RootPart or not Humanoid then return end
	-- raycast in 4D
	local Param = RaycastParams.new()
	Param.FilterDescendantsInstances = {Character}
	Param.FilterType = Enum.RaycastFilterType.Exclude
	local DirR = RootPart.CFrame.RightVector * 2.3 + Vector3.new(0, -5, 0)
	local DirL = -RootPart.CFrame.RightVector * 2.3 + Vector3.new(0, -5, 0)
	local DirD = -RootPart.CFrame.UpVector * 4
	local DirF = RootPart.CFrame.LookVector * 2
--	task.desynchronize()
	local RayLHit = workspace:Raycast(RootPart.Position,DirL,Param)
	local RayRHit = workspace:Raycast(RootPart.Position,DirR,Param)
	local RayDHit = workspace:Raycast(RootPart.Position,DirD,Param)
	

	local cast = workspace:Raycast(RootPart.Position,DirF,Param)
	if cast ~= nil then return end
	
	--task.synchronize()
	local TightRope = not RayRHit and not RayLHit and Humanoid.FloorMaterial ~= Enum.Material.Air and RayDHit
	-- detect if tightrope
	--(basically if not right and not left but yes down and yes forward and not hum floor material == air)
	if TightRope then
		DB = true
		RootPart.Anchored = true
		
		Character:SetAttribute('ShiftRotate',false)
		local Cam = workspace.CurrentCamera
		local LeanVal2 = LeanValue
		-- cam tilt
		local tiltconn = game["Run Service"].RenderStepped:Connect(function()
			local CFl = Cam.CFrame * CFrame.Angles(0,0,math.rad((LeanValue) * -60))
			
			local isFirstPerson = (Cam.CFrame.Position - Character.Head.Position).Magnitude < 1.4
			local Alpha = 0.2
			
			if isFirstPerson then
				Alpha = 0.4
			end
			
			local CamOffset = Vector3.new(0,0,0)
			
			if isFirstPerson then
				CamOffset = Vector3.new(0,0,0)
			end
			Cam.CFrame = Cam.CFrame:Lerp(CFl,Alpha)
		end)
		
		--pre sim ACTUAL loop
		
		repeat
			if script.Parent.Parent:FindFirstChild('Values') and script.Parent.Parent:FindFirstChild('Values'):FindFirstChild("TightRope") then
				script.Parent.Parent.Values.TightRope.Value = true
			end
			dt = RunService.PreSimulation:Wait()
			if Anim.IsPlaying == false then
				Anim:Play()
			end
			if not script:GetAttribute("CanDo") then break end
			if MOVEMENTFOLDER.Wallrunning.Value or MOVEMENTFOLDER.WallClimb:GetAttribute("Climbing") or script.Parent.Parent.Values.TightSpace.Value or MOVEMENTFOLDER.LedgeClimb:GetAttribute("CLIMBINGLEDGE") then
				break
			end
			-- get camera Y
			local _, y = workspace.CurrentCamera.CFrame:ToOrientation()
			-- find lean value
			LeanValue = LeanValue + LeanDirection * LeanSpeed * dt * (0.6 + (math.abs(LeanValue) / Limit))
			LeanValue = math.clamp(LeanValue, -Limit, Limit)
			
			if math.abs(LeanValue) == Limit then
				-- fall to the underground(undertale reference)
				break
			end
		--	task.desynchronize()
			-- check if still tightrope
			RayLHit = workspace:Raycast(RootPart.Position, DirL, Param)
			RayRHit = workspace:Raycast(RootPart.Position, DirR, Param)
		--	task.synchronize()
			TightRope = not RayRHit and not RayLHit and Humanoid.FloorMaterial ~= Enum.Material.Air
			
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0,0,-(9 * dt))
			RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0,y,-(LeanValue))
		until not TightRope
		--setup to quit
		print('wtoowtotw')
		RootPart.Anchored = false
		Character:SetAttribute('ShiftRotate',true)
		if math.abs(LeanValue) == Limit then
			if not script.Parent:GetAttribute('CanDo') then
				script.RemoteEvent:FireServer(true)				
			end
		end
		LeanValue = 0
		Anim:Stop()
		tiltconn:Disconnect()
		task.wait(0.1)
		if script.Parent.Parent:FindFirstChild('Values') and script.Parent.Parent:FindFirstChild('Values'):FindFirstChild("TightRope") then
			script.Parent.Parent.Values.TightRope.Value = false
		end
		DB = false
	end
end)
