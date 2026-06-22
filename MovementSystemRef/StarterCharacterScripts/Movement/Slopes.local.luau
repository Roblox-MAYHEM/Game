local RunService = game:GetService("RunService")
local char = script.Parent.Parent
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local hrp: BasePart = char:WaitForChild("HumanoidRootPart")

local isSliding = false
local slide
local steepSlopeThreshold = 43
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {char}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local rootJoint = hrp:FindFirstChild("RootJoint")
local baseC1 = rootJoint and rootJoint:IsA("Motor6D") and rootJoint.C1 or nil

local DownRamp = humanoid:LoadAnimation(script.DownRamp)

local decayRate = 0.94
local minSpeed = 4

-- same helper funcs from slide

local function getRampRay()
	return workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), rayParams)
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

local function alignToRamp(normal, interp)
	if not rootJoint or not baseC1 then return end
	local pitch = calcPitchFromNormal(normal)
	rootJoint.C1 = rootJoint.C1:Lerp(baseC1 * CFrame.Angles(pitch, 0, 0), interp or 0.25)
end

-- start slide func

local function startSlide()
	if isSliding then return end
	isSliding = true
	hrp.Position = hrp.Position + Vector3.new(0,2,0)

	DownRamp:Play()
	slide = Instance.new("BodyVelocity")
	slide.MaxForce = Vector3.new(1,1,1) * 60000
	slide.Velocity = Vector3.zero
	slide.Parent = hrp

	task.spawn(function()
		local pitchDeg = 0
		local m = 1
		
		-- allignment + slide loop

		while isSliding and slide do
			local ray = getRampRay()
			if ray then
				pitchDeg = math.deg(calcPitchFromNormal(ray.Normal))
				alignToRamp(ray.Normal, 0.1)

				local forward = hrp.CFrame.LookVector
				local n = ray.Normal
				local projected = (forward - forward:Dot(n) * n).Unit
				local mag = 50

				if pitchDeg > steepSlopeThreshold then
					slide.Velocity = projected * -mag * m
				elseif pitchDeg < -5 then
					slide.Velocity = projected * mag * m
				else
					slide.Velocity *= decayRate
				end
			else
				slide.Velocity *= decayRate
			end

			if slide.Velocity.Magnitude <= minSpeed then
				break
			end

			RunService.PostSimulation:Wait()
		end

		isSliding = false
		if DownRamp.IsPlaying then DownRamp:Stop() end
		if slide then slide:Destroy() end
		if rootJoint and baseC1 then
			rootJoint.C1 = baseC1
		end
	end)
end

local retuv = false

-- main hb loop

RunService.Heartbeat:Connect(function()
	if retuv then return end
	if script.Parent.SlidingValue.Value then return end
	if not isSliding then
		local ray = getRampRay()
		if ray then
			local pitchDeg = math.deg(calcPitchFromNormal(ray.Normal))
			if pitchDeg > steepSlopeThreshold then
				retuv = true
				wait(0.5)
				if script.Parent.SlidingValue.Value then return end
				local rayx = getRampRay()
				if not rayx then retuv = false return end
				local pitch2 = math.deg(calcPitchFromNormal(rayx.Normal))
				retuv = false
				if pitch2 > steepSlopeThreshold then
					startSlide()
				end
			end
		end
	end
end)
