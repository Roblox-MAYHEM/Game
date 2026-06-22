local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local scoped, doCleanup = Fusion.scoped, Fusion.doCleanup
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

local indicator = script:WaitForChild("Indicator") :: Frame

-- constants (not props)
local TIME_AFTER_EXPIRES = 5
local FADE_TIME = 0.3
local FADE_TI = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function getCentreCF(object: Instance): CFrame
	local instanceCF = object.CFrame
	local pos = instanceCF.Position
	local lookAt = instanceCF.LookVector * Vector3.new(1, 0, 1)
	return CFrame.new(pos, pos + lookAt)
end

local function calculateAngle(centre: CFrame, point: Vector3): number
	local damageDir = centre:PointToObjectSpace(point)
	local theta = math.atan2(damageDir.Z, damageDir.X)
	return math.deg(theta) + 90
end

return function(
	scope: Fusion.Scope,
	props: { origin: UsedAs<Vector3> }
): Instance
	local camera = workspace.CurrentCamera
	
	local angle = scope:Value(0)

	local alphaGoal = scope:Value(0)
	local alpha = scope:Tween(alphaGoal, FADE_TI)

	-- template clone + hydrate
	local root = indicator:Clone()
	root.Name = "dmgMarker"

	local img = root:WaitForChild("DamageIndicatorImage") :: ImageLabel

	scope:Hydrate(root) {
		Visible = true,
		Rotation = angle,
	}

	scope:Hydrate(img) {
		ImageTransparency = alpha,
	}

	-- follow camera/origin every frame
	local conn = RunService.Heartbeat:Connect(function()
		local origin = peek(props.origin)
		angle:set(calculateAngle(getCentreCF(camera), origin))
	end)
	table.insert(scope, conn)

	-- lifetime then fade then destroy
	task.spawn(function()
		task.wait(TIME_AFTER_EXPIRES)
		alphaGoal:set(1)
		task.wait(FADE_TIME)
		root:Destroy()
	end)

	return root
end