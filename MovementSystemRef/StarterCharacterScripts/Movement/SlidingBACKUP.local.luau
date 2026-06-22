local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local char = script.Parent.Parent
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local hrp : BasePart = char:WaitForChild("HumanoidRootPart")

local PlayUpBoostAnim = false

local UpBoost = humanoid:LoadAnimation(script.UpBoost)
UpBoost.Looped = false
UpBoost.Priority = Enum.AnimationPriority.Action2

local ProneIdle = humanoid:LoadAnimation(script.ProneIdle)
local ProneWalk = humanoid:LoadAnimation(script.ProneWalk)

local UP_RAY_LENGTH = 4

local StartAnim
local keybind = Enum.KeyCode.C
local canSlide = true
local isSliding = false
local slide, playAnim
local Connection
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {char}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local rootJoint = hrp:FindFirstChild("RootJoint")
local baseC1 = nil
if rootJoint and rootJoint:IsA("Motor6D") then
	baseC1 = rootJoint.C1
end

local function getRampRay(dt)
	if dt == nil then return nil end
	local hrpPosplus = humanoid.RootPart.AssemblyLinearVelocity * dt
	return workspace:Raycast(hrp.Position + hrpPosplus, Vector3.new(0,-10,0), rayParams)
end

local function getGroundRay()
	return workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * -2, rayParams)
end

local function calcPitchFromNormal(normal)
	local ok, val = pcall(function()
		return math.asin(normal:Cross(hrp.CFrame.RightVector).Y)
	end)
	if ok and val then
		return math.clamp(val, math.rad(-45), math.rad(45))
	end
	return 0
end

local LastNormal = Vector3.zero

local function alignToRamp(normal, interp)
	if not rootJoint or not baseC1 then return end
	local pitch = calcPitchFromNormal(normal)
	local target = baseC1 * CFrame.Angles(pitch, 0, 0)
	rootJoint.C1 = rootJoint.C1:Lerp(target, interp or 0.25)
	--humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
end

local function Prone()
	StartAnim:Stop()
	if playAnim then
		playAnim:Stop()
	end
	ProneIdle:Play()
	local Velocity = Instance.new('BodyVelocity',humanoid.RootPart)
	Velocity.MaxForce = Vector3.new(1,0,1) * 10000000
	Velocity.Velocity = Vector3.zero
	
	local conn
	conn = game["Run Service"].RenderStepped:Connect(function()
		local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
		if not upRay then
			print('noupray')
			ProneIdle:Stop()
			ProneWalk:Stop()
			Velocity:Destroy()
			conn:Disconnect()
			return
		else
			local md = humanoid.MoveDirection
			if md:Dot(humanoid.RootPart.CFrame.LookVector) >= 0.75 then
				Velocity.Velocity = humanoid.RootPart.CFrame.LookVector * 15
				if ProneWalk.IsPlaying == false then
					ProneWalk:Play(nil,nil,1)
					ProneIdle:Stop()
				end
			elseif md:Dot(-humanoid.RootPart.CFrame.LookVector) >= 0.75 then
				Velocity.Velocity = humanoid.RootPart.CFrame.LookVector * -15
				if ProneWalk.IsPlaying == false then
					ProneWalk:Play(nil,nil,-1)
					ProneIdle:Stop()
				end
			else
				Velocity.Velocity = Vector3.zero
				if ProneIdle.IsPlaying == false then
					ProneWalk:Stop()
					ProneIdle:Play()
				end
			end
		end
	end)
	
end

local function startSlide()
	if script.Parent.Parent.Values.TightRope.Value or script.Parent.Parent.Values.TightSpace.Value then return end
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then return end
	if not canSlide or isSliding then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	canSlide = false
	isSliding = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
	char:SetAttribute("ShiftRotate",false)
	script.Parent.SlidingValue.Value = true

	StartAnim = humanoid:LoadAnimation(script.Start)
	StartAnim.Looped = false
	StartAnim.Priority = Enum.AnimationPriority.Action
	StartAnim:Play(nil,nil,1)

	Connection = StartAnim.Stopped:Connect(function()
		playAnim = humanoid:LoadAnimation(script.Loop)
		playAnim.Looped = true
		playAnim:Play()
	end)

	slide = Instance.new("BodyVelocity")
	slide.MaxForce = Vector3.new(1,0,1) * 60000
	slide.Velocity = hrp.CFrame.LookVector * (100 * (humanoid.WalkSpeed / 20))
	slide.Parent = hrp

	local decayRate = 0.95

	task.spawn(function()
		local ray = getRampRay()
		task.spawn(function()
			while isSliding and slide do
				char:SetAttribute("ShiftRotate",true)
				if script.Parent.Parent.Values.TightSpace.Value then
					isSliding = false
					if playAnim then playAnim:Stop() end
					if slide then slide:Destroy() end
					char:SetAttribute("ShiftRotate",true)
					Prone()
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
					canSlide = true
					return
				end
				local dt = game["Run Service"].PreSimulation:Wait()
				print(dt)
				ray = getRampRay(dt)
			end
		end)

		task.spawn(function()
			while isSliding and slide do
				if script.Parent.Parent.Values.TightSpace.Value then return end
				if ray then alignToRamp(ray.Normal,0.1) end
				game["Run Service"].PreSimulation:Wait()
			end
		end)

		local SlideBoostUpDB = false
		local MAmount = 1
		
		while isSliding and slide do
			game["Run Service"].PostSimulation:Wait()
			MAmount += 0.0001

			if script.Parent.Parent.Values.TightSpace.Value then
				isSliding = false
				if playAnim then playAnim:Stop() end
				if slide then slide:Destroy() end
				char:SetAttribute("ShiftRotate",true)
				Prone()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
				canSlide = true
				return
			end

			if ray then
				local pitchDeg = math.deg(calcPitchFromNormal(ray.Normal))
				
				if pitchDeg < -5 then
					local forward = hrp.CFrame.LookVector
					local n = ray.Normal
					local projected = (forward - forward:Dot(n) * n).Unit
					
					slide.Velocity = (projected * slide.Velocity.Magnitude) * MAmount
					slide.MaxForce = Vector3.new(1,1,1) * 60000
				elseif pitchDeg > 5 then
					slide.Velocity *= 0.5
					slide.MaxForce = Vector3.new(1,1,1) * 60000
				else
					slide.Velocity *= decayRate
					slide.MaxForce = Vector3.new(1,0,1) * 60000
				end
			else
				slide.Velocity *= decayRate
				if rootJoint and baseC1 then
					rootJoint.C1 = rootJoint.C1:Lerp(baseC1,0.15)
				end
			end

			if not SlideBoostUpDB then
				local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
				if upRay then
					SlideBoostUpDB = true
					if PlayUpBoostAnim then UpBoost:Play() end
					slide.Velocity = hrp.CFrame.LookVector * (100 * (humanoid.WalkSpeed / 20))
					task.delay(1.5,function() SlideBoostUpDB = false end)
				end
			end

			if slide.Velocity.Magnitude <= 4 then
				break
			end
		end

		if isSliding then
			isSliding = false
			if playAnim then playAnim:Stop() end
			if slide then slide:Destroy() end

			if rootJoint and baseC1 then
				local start = tick()
				local dur = 0.25
				while tick() - start < dur do
					rootJoint.C1 = rootJoint.C1:Lerp(baseC1,0.25)
					task.wait()
				end
				rootJoint.C1 = baseC1
			end

			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
			char:SetAttribute("ShiftRotate",true)

			local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
			if upRay then Prone() end

			task.wait(0.5)
			canSlide = true
		end
	end)
end

local function stopSlide()
	if not isSliding then return end
	isSliding = false

	if playAnim then playAnim:Stop() end
	if StartAnim then StartAnim:Stop() end
	if slide then slide:Destroy() end
	char:SetAttribute("ShiftRotate",true)

	
	local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
	if upRay then
		Prone()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
		canSlide = true
		return
	end
	
	if rootJoint and baseC1 then
		local start = tick()
		local dur = 0.25
		while tick() - start < dur do
			rootJoint.C1 = rootJoint.C1:Lerp(baseC1, 0.25)
			task.wait()
		end
		rootJoint.C1 = baseC1
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	task.wait(0.5)
	canSlide = true

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end


RunService.Heartbeat:Connect(function()
	if not isSliding then
		if playAnim then playAnim:Stop() end
		if StartAnim then StartAnim:Stop() end
	end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == keybind then
		startSlide()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == keybind then
		stopSlide()
	end
end)
