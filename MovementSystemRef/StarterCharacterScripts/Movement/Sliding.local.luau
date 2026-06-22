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

local DownRamp = humanoid:LoadAnimation(script.DownRamp)

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
local connacon

local rootJoint = hrp:FindFirstChild("RootJoint")
local baseC1 = nil
if rootJoint and rootJoint:IsA("Motor6D") then
	baseC1 = rootJoint.C1
end

-- simple helper funcs

local function getRampRay(dt)
	if dt == nil then return nil end
	local hrpPosplus = humanoid.RootPart.AssemblyLinearVelocity * dt
	return workspace:Raycast(hrp.Position + hrpPosplus, Vector3.new(0,-10,0), rayParams)
end

local function getGroundRay()
	return workspace:Raycast(hrp.Position, Vector3.new(0,-6.5,0), rayParams)
end

local function calcPitchFromNormal(normal)
	local ok, val = pcall(function()
		return math.asin(normal:Cross(hrp.CFrame.RightVector).Y)
	end)
	if ok and val then
		return val --math.clamp(val, math.rad(-60), math.rad(60))
	end
	return 0
end

local LastNormal = Vector3.zero

-- allign to the ramp so you dont float while sliding down a ramp
local function alignToRamp(normal, interp)
	if not rootJoint or not baseC1 then return end
	local pitch = calcPitchFromNormal(normal)
	local target = baseC1 * CFrame.Angles(pitch, 0, 0)
	rootJoint.C1 = rootJoint.C1:Lerp(target, interp or 0.25)
end

--prone if under a block and you burn out sliding
local function Prone()
	StartAnim:Stop()
	if connacon then
		connacon:Disconnect()
	end
	if playAnim then
		playAnim:Stop()
	end
	ProneIdle:Play()
	local Velocity = Instance.new('BodyVelocity',humanoid.RootPart)
	Velocity.MaxForce = Vector3.new(1,0,1) * 10000000
	Velocity.Velocity = Vector3.zero

	local conn
	conn = game["Run Service"].RenderStepped:Connect(function()
		char:SetAttribute("ShiftRotate",true)
		local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
		if not upRay then
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

-- Ease In in sine
-- fovProgress variable used in func startslide
local fovProgress = 0

local function EaseOutQuart(x : number) : number
	return 1 - math.pow(1 - x, 4);
end

-- im not even gonna explain this over-engineered abomination of a slide that much
local function startSlide()
	-- holy returns: Origins
	if script.Parent.Parent.Values.TightRope.Value or script.Parent.Parent.Values.TightSpace.Value then return end
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then return end
	if not canSlide or isSliding then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end
	
	--setup 
	
	canSlide = false
	isSliding = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
	char:SetAttribute("ShiftRotate",false)
	script.Parent.SlidingValue.Value = true
	
	--anims 
	
	StartAnim = humanoid:LoadAnimation(script.Start)
	StartAnim.Looped = false
	StartAnim.Priority = Enum.AnimationPriority.Action
	StartAnim:Play(nil,nil,1)
	
	Connection = StartAnim.Stopped:Connect(function()
		playAnim = humanoid:LoadAnimation(script.Loop)
		playAnim.Looped = true
		playAnim:Play()
	end)
	
	--face to the camera
	
	local _, xgy = workspace.CurrentCamera.CFrame:ToOrientation()

	humanoid.RootPart.CFrame = CFrame.new(humanoid.RootPart.Position) * CFrame.Angles(0, xgy, 0)
	
	--velo
	
	slide = Instance.new("BodyVelocity")
	slide.MaxForce = Vector3.new(1,0,1) * 60000
	slide.Velocity = hrp.CFrame.LookVector * (100 * (humanoid.WalkSpeed / 20))
	slide.Parent = hrp
	
	local decayRate = 0.95
	
	-- slide stability loop

	connacon = game["Run Service"].RenderStepped:Connect(function()
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		char:SetAttribute("ShiftRotate",false)
	end)
	local pitchDeg = 0
	
	-- ramp code that i spent a stupid amount of time on
	task.spawn(function()
		--get ramp ray
		local ray = getRampRay()

		task.spawn(function()
			--ray loop
			while isSliding and slide do
				char:SetAttribute("ShiftRotate",true)
				--yo hes in a tight space so hes stop slidin
				if script.Parent.Parent.Values.TightSpace.Value then
					isSliding = false
					if playAnim then playAnim:Stop() end
					if slide then slide:Destroy() end
					char:SetAttribute("ShiftRotate",true)
					fovProgress = 0
					--Prone()
					--idk if ts func is supposed to be activated here gng, most prob not
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
					canSlide = true
					if connacon then
						connacon:Disconnect()
					end
					return
				end
				local dt = game["Run Service"].PreSimulation:Wait()
				humanoid.WalkSpeed = 0
				humanoid.AutoRotate = false
				char:SetAttribute("ShiftRotate",false)
				local _, y = workspace.CurrentCamera.CFrame:ToOrientation()

				humanoid.RootPart.CFrame = humanoid.RootPart.CFrame:Lerp(
					CFrame.new(humanoid.RootPart.Position) * CFrame.Angles(0, y, 0),
					dt * 5 * 3
				)

				ray = getRampRay(dt)
			end
		end)

		task.spawn(function()
			--allign loop
			while isSliding and slide do
				if script.Parent.Parent.Values.TightSpace.Value then return end
				if ray then alignToRamp(ray.Normal,0.25) end
				game["Run Service"].PreSimulation:Wait()
			end
		end)

		local SlideBoostUpDB = true
		local MAmount = 1
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
		char:SetAttribute("ShiftRotate",false)
		--slide loop
		while isSliding and slide do
			-- Increase/Decrease M/Multiplier Amount
			local dt = game["Run Service"].PostSimulation:Wait()
			if pitchDeg > 5 then
				MAmount -= 1.2 * dt
			else
				MAmount += 1.2 * dt
			end
			
			MAmount = math.clamp(MAmount,-10,10)
			
			-- FOV and Speedlines
			
			if pitchDeg > 5 or pitchDeg < -5 then
				local camera = workspace.CurrentCamera

				fovProgress += dt * 0.1
				fovProgress = math.clamp(fovProgress,0,0.6)
				local eased = EaseOutQuart(fovProgress)
				local targetFOV = 70 + (eased * 60)

				camera.FieldOfView = math.clamp(camera.FieldOfView + (targetFOV - camera.FieldOfView) * (dt * 10),70,105)
			end
			
			--[[print({
				EASE = eased,
				MA = MAmount,
				FOV = camera.FieldOfView,
				FOVPROGRESS = fovProgress,
				FOVTarget = targetFOV,
			})]]
			
			-- slide backwards WEEE
			if MAmount < 0 then
				if playAnim then playAnim:Stop() end
				playAnim = DownRamp
				playAnim.Looped = true
				if not playAnim.IsPlaying then playAnim:Play() end
			end
			
			-- return, return.
			
			if script.Parent.Parent.Values.TightSpace.Value then
				isSliding = false
				if playAnim then playAnim:Stop() end
				if slide then slide:Destroy() end
				char:SetAttribute("ShiftRotate",true)
				Prone()
				script.Parent.SlidingValue.Value = false
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
				canSlide = true
				return
			end
			
			-- adjust velo to slide down the ramp
			
			if ray then
				pitchDeg = math.deg(calcPitchFromNormal(ray.Normal))

				if pitchDeg < -5 then
					local forward = hrp.CFrame.LookVector
					local n = ray.Normal
					local projected = (forward - forward:Dot(n) * n).Unit

					local Magni = 50

					local GRay = getGroundRay()
					if GRay then
						slide.Velocity = (projected * Magni) * MAmount
					else
						slide.Velocity = (projected + Vector3.new(0,-1,0) * Magni) * MAmount
					end
					slide.MaxForce = Vector3.new(1,1,1) * 60000
				elseif pitchDeg > 5 then -- else slide backwards
					if MAmount > 4 then
						MAmount = 4
					end
					local forward = hrp.CFrame.LookVector
					local n = ray.Normal
					local projected = (forward - forward:Dot(n) * n).Unit

					local Magni = 50

					local GRay = getGroundRay()
					if GRay then
						slide.Velocity = (projected * Magni) * MAmount
					end
					slide.MaxForce = Vector3.new(1,1,1) * 60000
				else
					slide.Velocity *= decayRate
					slide.MaxForce = Vector3.new(1,0,1) * 60000
				end
			else -- else decay
				slide.Velocity *= decayRate
				slide.MaxForce = Vector3.new(1,0,1) * 60000
				if rootJoint and baseC1 then
					rootJoint.C1 = rootJoint.C1:Lerp(baseC1,0.15)
				end
			end

			if not SlideBoostUpDB then
				local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
				if upRay then
					SlideBoostUpDB = true
					if PlayUpBoostAnim then UpBoost:Play() end
					slide.Velocity = hrp.CFrame.LookVector * (100)
					task.delay(1.5,function() SlideBoostUpDB = false end)
				end
			end

			if math.abs(slide.Velocity.Magnitude) <= 4 and pitchDeg < 5 then -- else quit
				if connacon then
					connacon:Disconnect()
				end
				break
			end
		end
		
		-- return setup
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
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
			if connacon then
				connacon:Disconnect()
			end
			script.Parent.SlidingValue.Value = false
			char:SetAttribute("ShiftRotate",true)
			humanoid.WalkSpeed = 8
			humanoid.AutoRotate = true
			char:SetAttribute("ShiftRotate",true)
			fovProgress = 0
			local upRay = workspace:Raycast(hrp.Position, hrp.CFrame.UpVector * UP_RAY_LENGTH, rayParams)
			if upRay then Prone() end

			task.wait(0.5)
			canSlide = true
		end
	end)
end

--stop the slide
local function stopSlide()
	if not isSliding then return end
	isSliding = false

	if playAnim then playAnim:Stop() end
	if StartAnim then StartAnim:Stop() end
	if slide then slide:Destroy() end
	char:SetAttribute("ShiftRotate",true)
	fovProgress = 0

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
	if connacon then
		connacon:Disconnect()
	end
	humanoid.WalkSpeed = 8
	humanoid.AutoRotate = true
	char:SetAttribute("ShiftRotate",true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	script.Parent.SlidingValue.Value = false
	task.wait(0.5)
	canSlide = true

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

-- animation stability loop

RunService.Heartbeat:Connect(function()
	if not isSliding then
		if playAnim then playAnim:Stop() end
		if StartAnim then StartAnim:Stop() end
	end
end)

-- inputs

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
