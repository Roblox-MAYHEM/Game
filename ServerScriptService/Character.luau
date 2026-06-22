local module = {}

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Bindables = game:GetService("ServerStorage").Bindables

local TARGET_GROUP = "Players"
local RAGDOLLED_ATTRIBUTE = "Ragdolled"

local playersConn = {}

---------------------------------------------------------------------
-- Collision Group Helpers
---------------------------------------------------------------------

local function ensureCollisionGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(TARGET_GROUP)
	end)
end

local function applyCollisionGroupToCharacter(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = TARGET_GROUP
		end
	end

	character.DescendantAdded:Connect(function(child)
		if child:IsA("BasePart") then
			child.CollisionGroup = TARGET_GROUP
		end
	end)
end

---------------------------------------------------------------------
-- Mass Helpers
---------------------------------------------------------------------

local function applyMasslessToHumanoidAssembly(character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local connectedParts = humanoidRootPart:GetConnectedParts(true)
	table.insert(connectedParts, humanoidRootPart)

	for _, part in ipairs(connectedParts) do
		if part:IsA("BasePart") then
			part.Massless = (part ~= humanoidRootPart)
		end
	end
end

---------------------------------------------------------------------
-- Controller Helpers
---------------------------------------------------------------------

local function setupControllerManager(character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local controllerManager = Instance.new("ControllerManager")
	controllerManager.Name = "ControllerManager"
	controllerManager.Parent = character
	controllerManager.RootPart = humanoidRootPart
	controllerManager.BaseMoveSpeed = 25
	controllerManager.FacingDirection = humanoidRootPart.CFrame.LookVector

	return controllerManager
end

local function setupGroundSensor()
	local groundSensor = Instance.new("ControllerPartSensor")
	groundSensor.Name = "GroundSensor"
	groundSensor.SensorMode = Enum.SensorMode.Floor
	groundSensor.UpdateType = Enum.SensorUpdateType.Manual
	return groundSensor
end

local function setupWallRunSensor()
	local wallRunSensor = Instance.new("ControllerPartSensor")
	wallRunSensor.Name = "WallRunSensor"
	wallRunSensor.SensorMode = Enum.SensorMode.Ladder
	wallRunSensor.SearchDistance = 4
	return wallRunSensor
end

local function setupControllers()
	local groundController = Instance.new("GroundController")
	groundController.Name = "GroundController"
	groundController.GroundOffset = 2
	groundController.BalanceRigidityEnabled = true

	local airController = Instance.new("AirController")
	airController.Name = "AirController"
	airController.MaintainLinearMomentum = true
	airController.MaintainAngularMomentum = false
	airController.BalanceRigidityEnabled = true

	local climbController = Instance.new("ClimbController")
	climbController.Name = "ClimbController"
	climbController.BalanceRigidityEnabled = true

	return groundController, airController, climbController
end

---------------------------------------------------------------------
-- Ragdoll Helpers
---------------------------------------------------------------------

local function stopCharacterControllers(character: Model)
	local controllerManager = character:FindFirstChild("ControllerManager")
	if controllerManager then
		controllerManager:Destroy()
	end
end

local function makeBallSocketFromMotor(motor: Motor6D)
	local part0 = motor.Part0
	local part1 = motor.Part1
	if not part0 or not part1 then
		return
	end

	local att0 = Instance.new("Attachment")
	att0.Name = motor.Name .. "_RagdollAttachment0"
	att0.CFrame = motor.C0
	att0.Parent = part0

	local att1 = Instance.new("Attachment")
	att1.Name = motor.Name .. "_RagdollAttachment1"
	att1.CFrame = motor.C1
	att1.Parent = part1

	local socket = Instance.new("BallSocketConstraint")
	socket.Name = motor.Name .. "_RagdollConstraint"
	socket.Attachment0 = att0
	socket.Attachment1 = att1

	socket.LimitsEnabled = true
	socket.UpperAngle = 45
	socket.TwistLimitsEnabled = true
	socket.TwistLowerAngle = -45
	socket.TwistUpperAngle = 45

	socket.Parent = part0
end

local function ragdollCharacter(character: Model)
	if character:GetAttribute(RAGDOLLED_ATTRIBUTE) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	character:SetAttribute(RAGDOLLED_ATTRIBUTE, true)
	
	humanoid.RequiresNeck = false

	stopCharacterControllers(character)

	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Massless = false
			obj.CanCollide = obj.Name ~= "HumanoidRootPart"
			pcall(function()
				obj:SetNetworkOwner(nil)
			end)
		end
	end

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("Motor6D") then
			makeBallSocketFromMotor(obj)

			obj.Enabled = false
		end
	end
end

---------------------------------------------------------------------
-- Main initialize
---------------------------------------------------------------------

local function onCharacterAdded(character: Model, player : Player)
	character:SetAttribute(RAGDOLLED_ATTRIBUTE, false)
	applyCollisionGroupToCharacter(character)

	local Highlight = Instance.new("Highlight")
	Highlight.OutlineColor = player.TeamColor.Color
	Highlight.FillTransparency = 1
	Highlight.Parent = character

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.EvaluateStateMachine = false
	humanoid.BreakJointsOnDeath = false

	local hrp = character:WaitForChild("HumanoidRootPart")
	local p = hrp.CurrentPhysicalProperties
	hrp.CustomPhysicalProperties = PhysicalProperties.new(p.Density, p.Friction, 0, 100, 100)

	local groundSensor = setupGroundSensor()
	local wallRunSensor = setupWallRunSensor()
	local groundController, airController, climbController = setupControllers()
	local controllerManager = setupControllerManager(character)

	groundController.Parent = controllerManager
	airController.Parent = controllerManager
	climbController.Parent = controllerManager
	groundSensor.Parent = controllerManager
	wallRunSensor.Parent = controllerManager
	controllerManager.GroundSensor = groundSensor
	controllerManager.ClimbSensor = wallRunSensor

	applyMasslessToHumanoidAssembly(character)

	character.DescendantAdded:Connect(function(child)
		if child:IsA("BasePart") then
			task.defer(function()
				if character.Parent and not character:GetAttribute(RAGDOLLED_ATTRIBUTE) then
					applyMasslessToHumanoidAssembly(character)
				end
			end)
		end
	end)
end

local function onPlayerAdded(player: Player)
	playersConn[player] = player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end)

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

function module:Init()
	ensureCollisionGroup()
	
	Bindables.PlayerKilled.Event:Connect(function(playerKilled: Player, killer: Player)
		local character = playerKilled.Character
		if character then
			ragdollCharacter(character)
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if playersConn[player] then
			playersConn[player]:Disconnect()
			playersConn[player] = nil
		end
	end)
end

function module:Ragdoll(character: Model)
	ragdollCharacter(character)
end

return module
