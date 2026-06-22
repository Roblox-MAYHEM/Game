--[[ Movement Controller ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Events = ReplicatedStorage.Events
local Bindables = StarterPlayer.Bindables
local Packages = ReplicatedStorage.Packages

local Signal = require(Packages.Signal)

local BaseState = require(script.Parent:WaitForChild("BaseState"))
local CastModule = require(script.Parent:WaitForChild("RaycastModule"))
local Frame = require(script.Parent:WaitForChild("Frame"))
local Runtime = require(script.Parent:WaitForChild("Runtime"))
local StateMachine = require(script.Parent:WaitForChild("StateMachine"))
local Transitions = require(script.Parent:WaitForChild("Transitions"))

local ConfigModule = BaseState.GetConfigModule()
local MovementConfig = BaseState.GetConfig()
local StatesFolder = script.Parent:WaitForChild("States")
local Controls = require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local CONFIG_REVISION_ATTRIBUTE = "DevConfigRevision"
local CONTROLLERS = {
	"GroundController",
	"AirController",
	"ClimbController",
	"WallRunSensor",
	"GroundSensor",
}

local Movement = {
	state = "Idle",
	PreviousState = "Idle",
	States = {},

	Landed = Signal.new("Landed"),
	SpreadChanged = Signal.new("SpreadChanged"),

	BaseGravity = workspace.Gravity,
	BaseFriction = 1.4,
	BaseOffset = 2,

	Config = MovementConfig.Movement,
	CurrentSpread = 0,
	EquipLoad = 1,
	Priority = 1,
}

function Movement:_ApplyConfig(config)
	MovementConfig = config
	self.Config = MovementConfig.Movement or {}

	for stateName, state in pairs(self.States) do
		state.Config = (MovementConfig.States and MovementConfig.States[stateName]) or {}
		if stateName == "Jumping" then
			state.MaxAirJumps = state.Config.DoubleJumps or 0
		end
	end
end

function Movement:_LoadStates(trove, props)
	for _, module in StatesFolder:GetChildren() do
		if not module:IsA("ModuleScript") then continue end

		self.States[module.Name] = require(module).new({
			Trove = trove,
			fsm = self,
			Context = props,
			Cast = CastModule,
			name = module.Name,
		})
	end
end

function Movement:_GetCharacterControllers(cm)
	for _, name in ipairs(CONTROLLERS) do
		self[name] = cm:WaitForChild(name, 5)
		if not self[name] then return false end
	end
	return true
end

function Movement:_BindEvents(trove, props)
	trove:Add(props.RoundReplica:OnSet({ "movement" }, function(enabled)
		self:SetEnabled(enabled)
	end))

	trove:Connect(RunService.RenderStepped, function(dt)
		self:Update(dt)
	end)

	for signalName, phase in pairs({ InputBegan = "OnBegan", InputEnded = "OnEnded" }) do
		trove:Connect(UserInputService[signalName], function(input, gameProcessed)
			self:ProcessInputPhase(phase, input, gameProcessed)
		end)
	end

	trove:Connect(Bindables.TimeChanged.Event, function()
		workspace.Gravity = self.BaseGravity
	end)

	trove:Connect(Events.Knockback.OnClientEvent, function(packet)
		self:ApplyKnockback(packet)
	end)

	if not RunService:IsStudio() then return end

	local queued = false
	trove:Connect(ConfigModule:GetAttributeChangedSignal(CONFIG_REVISION_ATTRIBUTE), function()
		if queued then return end
		queued = true
		task.delay(0.1, function()
			queued = false
			self:_ApplyConfig(BaseState.ReloadConfig())
		end)
	end)
end

function Movement:Init(props)
	local trove = props.Trove:Extend()
	self.trove = trove
	self.Ready = false

	local character = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local cm = character:WaitForChild("ControllerManager", 10)

	if not humanoid or not hrp or not cm then
		warn("[Movement] Character controller setup missing; movement disabled for this character.")
		return
	end

	self.Character = character
	self.Humanoid = humanoid
	self.HRP = hrp
	self.CM = cm

	if not self:_GetCharacterControllers(cm) then
		warn("[Movement] Controller children missing; movement disabled for this character.")
		return
	end

	CastModule:Init()

	self.FrameTracker = Frame.new(self, Controls, CastModule)
	self.Frame = self.FrameTracker.Data
	self.Runtime = Runtime.new(self)
	self.StateMachine = StateMachine.new(self, Transitions)
	self.ViewModel = props.ViewModel

	local phys = hrp.CurrentPhysicalProperties
	self._basePhysProps = phys
	self.BaseVolume = hrp.Mass / phys.Density
	self.BaseMass = hrp.Mass

	self.Groundtime = 0
	self.GroundController.FrictionWeight = 100
	self.GroundController.Friction = self.BaseFriction
	self.GroundController.GroundOffset = self.BaseOffset
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	task.wait()

	self:_LoadStates(trove, props)
	self:_BindEvents(trove, props)

	self.Ready = true
	self:SetEnabled(props.RoundReplica.Data.movement)
end

local function numberOrNil(value)
	return if typeof(value) == "number" then value else nil
end

function Movement:ApplyKnockback(packet)
	if not self.Ready or not self.HRP or not self.StateMachine then return end

	local data = {}

	if typeof(packet) == "Vector3" then
		data.Velocity = packet / math.max(self.HRP.AssemblyMass, 0.001)
	elseif typeof(packet) == "table" then
		if typeof(packet.Velocity) == "Vector3" then
			data.Velocity = packet.Velocity
		elseif typeof(packet.Impulse) == "Vector3" then
			data.Velocity = packet.Impulse / math.max(self.HRP.AssemblyMass, 0.001)
		else
			return
		end

		data.Duration = numberOrNil(packet.Duration)
		data.WallDaze = packet.WallDaze == true
		data.DazeDuration = numberOrNil(packet.DazeDuration)
		data.WallSpeedMin = numberOrNil(packet.WallSpeedMin)
		data.Source = packet.Source
	else
		return
	end

	if data.Velocity.Magnitude <= 0.001 then return end

	self.StateMachine:Change("Knockback", data)
end

function Movement:SetEnabled(enabled)
	if not self.Ready or not self.CM then return end

	self.CM.MovingDirection = Vector3.zero

	if enabled then
		self:HandleStateChange("Idle")
	else
		self.CM.BaseMoveSpeed = 0
		self:HandleStateChange("Disabled")
	end
end

function Movement:Update(dt)
	if not self.Ready or not self.Humanoid or not self.CM or not self.HRP then return end
	
	self.FrameTracker:Update(dt)
	self.Runtime:UpdateFacing()

	self.Groundtime = self:IsGrounded() and (self.Groundtime + dt) or 0
	self.StateMachine:Update()

	local current = self.States[self.state]
	if current then current:OnUpdate(dt) end

	self.Runtime:UpdateTilt()
	self.Runtime:UpdateSpread()
end

function Movement:ProcessInputPhase(...) return self.StateMachine:ProcessInputPhase(...) end
function Movement:HandleStateChange(...) return self.StateMachine:Change(...) end
function Movement:HasBufferedKey(...) return self.StateMachine:HasBufferedKey(...) end
function Movement:SetEquipLoad(...) return self.Runtime:SetEquipLoad(...) end
function Movement:GetSpread() return self.CurrentSpread end
function Movement:SetDoubleJumps(...) return self.Runtime:SetDoubleJumps(...) end
function Movement:IsGrounded() return self.Ready and self.Frame.Grounded end

function Movement:IsIdle()
	return self.Ready
		and self.Humanoid
		and not self.Frame.SlopeSliding
		and self.Frame.MoveVelocity.Magnitude <= 0.3
		and self.Humanoid.MoveDirection.Magnitude <= 0.2
end

function Movement:Destroy()
	if self.trove then self.trove:Destroy() end
end

return Movement
