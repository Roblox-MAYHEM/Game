local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local DataFolder = script.Parent:WaitForChild("Data")
local ConfigModule = DataFolder:WaitForChild("Config")

local AnimationController = require(StarterPlayer.Libraries.AnimationController)
local CastModule = require(script.Parent:WaitForChild("RaycastModule"))
local Controls = require(Player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local function requireFresh(module: ModuleScript)
	if not RunService:IsStudio() then return require(module) end

	local clone = module:Clone()
	clone.Name = module.Name .. "_HotReload"
	clone.Parent = module.Parent
	local result = require(clone)
	clone:Destroy()
	return result
end

local function loadData()
	local data = {}
	for _, child in ipairs(DataFolder:GetChildren()) do
		if child:IsA("ModuleScript") and not child.Name:find("_HotReload") then
			data[child.Name] = requireFresh(child)
		end
	end
	return data
end

local function assetId(id)
	local value = tostring(id)
	return value:match("^%d+$") and ("rbxassetid://" .. value) or value
end

local function loadAnimations(data, humanoid, trove)
	local animations = {}
	for name, info in pairs(data or {}) do
		if info.HumanoidState then
			animations[name] = {
				Play = function() humanoid:ChangeState(Enum.HumanoidStateType[info.HumanoidState]) end,
				Stop = function() end,
			}
		else
			local track = if #info == 3
				then AnimationController.new(info[1], info[2], info[3])
				else AnimationController.new(info[1], info[3], info[4], info[2])
			animations[name] = trove:Add(track)
		end
	end
	return animations
end

local function loadSounds(data, character, trove)
	local sounds = {}
	for name, info in pairs(data or {}) do
		local source = typeof(info) == "table" and info or { Id = info }
		local sound = trove:Add(Instance.new("Sound"))
		sound.Name = name
		sound.SoundId = assetId(source.Id or source[1])
		sound.Volume = source.Volume or source[2] or 1
		sound.Looped = source.Looped or false
		sound.Parent = character
		sounds[name] = sound
	end
	return sounds
end

local MovementData = loadData()

export type opts = {
	fsm: any,
	Trove: any,
	Character: Model?,
	Context: any?,
	Cast: any?,
	name: string?,
}

local BaseState = {}
BaseState.__index = BaseState

function BaseState.GetConfig() return MovementData.Config end
function BaseState.GetConfigModule() return ConfigModule end
function BaseState.ReloadConfig()
	MovementData.Config = requireFresh(ConfigModule)
	return MovementData.Config
end

function BaseState.new(opts: opts)
	local character = opts.Character or Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local context = opts.Context or {}
	local fsm = opts.fsm
	local name = opts.name or "Base"

	if fsm and not fsm.Animations then fsm.Animations = loadAnimations(MovementData.Animations, humanoid, opts.Trove) end
	if fsm and not fsm.Sounds then fsm.Sounds = loadSounds(MovementData.Sounds, character, opts.Trove) end

	return setmetatable({
		Player = Player,
		Character = character,
		Humanoid = humanoid,
		HRP = character:WaitForChild("HumanoidRootPart"),
		fsm = fsm,
		trove = opts.Trove:Extend(),

		Physics = context.Physics,
		Animations = fsm and fsm.Animations or {},
		Sounds = fsm and fsm.Sounds or {},
		Cast = opts.Cast or CastModule,
		Controls = Controls,
		Camera = context.Camera,
		ViewModel = context.ViewModel,

		Name = name,
		Config = (MovementData.Config.States and MovementData.Config.States[name]) or {},
		Memory = {},
	}, BaseState)
end

function BaseState:CanEnter(_fromState: string?) return false end
function BaseState:OnEnter() end
function BaseState:OnUpdate(_dt: number) end
function BaseState:OnExit(_nextState: string?) end
function BaseState:GetSpread() return 0 end

return BaseState
