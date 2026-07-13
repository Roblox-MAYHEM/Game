local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Player = game:GetService("Players").LocalPlayer

local WeaponSystem = script.Parent
local WeaponData = ReplicatedStorage.Assets.Weapons.Data

local SoundController = require(StarterPlayer.Libraries.SoundController)
local AnimationController = require(StarterPlayer.Libraries.AnimationController)
local Effects = require(WeaponSystem.Modules.Effects)
local Trove = require(ReplicatedStorage.Packages.Trove)

local function requireFresh(Module: ModuleScript)
	if not RunService:IsStudio() then
		return require(Module)
	end

	local Clone = Module:Clone()
	Clone.Name = Module.Name .. "_HotReload"
	Clone.Parent = Module.Parent

	local Result = require(Clone)
	Clone:Destroy()
	return Result
end

local ConfigData
local AnimationsData = require(WeaponData.Animations)

local function reparent(instance: Instance?, parent: Instance?)
	if instance and instance.Parent and parent then
		instance.Parent = parent
	end
end

local function setOpacity(model: Instance, opacity: number)
	if not model then return end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = opacity
		end
	end
end

local function disableEmitters(model: Instance)
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("Trail") or object:IsA("ParticleEmitter") or object:IsA("Beam") then
			object.Enabled = false
		end
	end
end

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

function BaseWeapon:_KeybindSetup()
	self.Keybinds = {
		[Enum.UserInputState.Begin] = {},
		[Enum.UserInputState.End] = {},
	}

	for InputState, binds in pairs(self.Binds) do
		for Input, Callback in pairs(binds) do
			self.Keybinds[InputState][Input] = self[Callback]
		end
	end
end

function BaseWeapon:_Callback(Input: InputObject)
	local InputType = if Input.UserInputType == Enum.UserInputType.Keyboard then Input.KeyCode else Input.UserInputType
	local Callback = self.Keybinds[Input.UserInputState][InputType]
	if Callback then
		Callback(self)
	end
end

function BaseWeapon:_init()
	self._trove = Trove.new()
	self.vWeapon = self._trove:Add(self.wWeapon:Clone())
	self.vWeapon.Parent = Player.vHotbar

	disableEmitters(self.vWeapon)
	disableEmitters(self.wWeapon)

	self.WeaponModel = { self.vWeapon }
	self.Effects = Effects.new(self.WeaponModel)

	self.Config = assert(ConfigData[self.Name], `Missing Config for {self.Name}`)
	self.Animations = assert(AnimationsData[self.Name], `Missing Animations for {self.Name}`)

	self.Sounds = {}
	local weaponSounds = WeaponData.Sounds:FindFirstChild(self.Name)
	local soundSources = weaponSounds and weaponSounds:GetChildren() or {}
	for _, source in soundSources do
		if source:IsA("Sound") and not rawget(self.Sounds, source.Name) then
			self.Sounds[source.Name] = self._trove:Add(SoundController.new(source, nil, source.Name))
		end
	end

	local Animations = {}
	for Name, Data in self.Animations do
		local Animation
		if #Data == 3 then
			Animation = AnimationController.new(Data[1], Data[2], Data[3])
		else
			Animation = AnimationController.new(Data[1], Data[3], Data[4], Data[2])
		end
		Animations[Name] = self._trove:Add(Animation)
	end
	self.Animations = Animations

	for _, Name in self.Behaviors do
		local Behavior = require(script.Parent.Behaviors:WaitForChild(Name))
		Behavior.__init(self)
		for Key, Value in Behavior do
			self[Key] = Value
		end
	end

	self:_KeybindSetup()
end

function BaseWeapon.ReloadConfig()
	ConfigData = requireFresh(WeaponData.Config)
end

BaseWeapon.ReloadConfig()

function BaseWeapon:NewActionToken()
	self.ActionGeneration += 1
	return self.ActionGeneration
end

function BaseWeapon:IsActionCurrent(token)
	return not self.Destroyed and self.ActionGeneration == token
end

function BaseWeapon:CancelActions()
	self.ActionGeneration += 1
end

function BaseWeapon.new(opts)
	local context = opts.Context or {}
	local player = context.Player or Player
	local character = context.Character or player.Character or player.CharacterAdded:Wait()

	return setmetatable({
		Player = player,
		Character = character,
		HRP = character:WaitForChild("HumanoidRootPart"),
		ViewModel = context.ViewModel,
		Movement = context.Movement,
		Camera = context.Camera,
		PlayerEffects = context.PlayerEffects,
		Projectile = context.Projectile,

		Name = opts.Name,
		wWeapon = opts.WeaponModel,
		Binds = opts.Binds or {},
		Behaviors = opts.Behaviors or {},
		Enabled = true,
		ActionGeneration = 0,
	}, BaseWeapon)
end

function BaseWeapon:SetEnable(val: boolean)
	self.Enabled = val
end

function BaseWeapon:_CanEquip()
	return not self.Destroyed
		and self.Character:IsDescendantOf(game)
		and self.ViewModel:IsAlive()
		and self.Movement.Ready
end

function BaseWeapon:ToggleView(isFirstPerson: boolean)
	if self.Destroyed or not self.ViewModel or not self.ViewModel:IsAlive() then return end

	self.Effects:RemoveAll()
	self.WeaponModel[1] = isFirstPerson and self.vWeapon or self.wWeapon

	setOpacity(self.wWeapon, isFirstPerson and 1 or 0)
	setOpacity(self.ViewModel.ViewModel, isFirstPerson and 0 or 1)
	setOpacity(self.vWeapon, isFirstPerson and 0 or 1)
end

function BaseWeapon:_Equip()
	if not self:_CanEquip() then
		return false
	end
	self:CancelActions()

	reparent(self.wWeapon, self.Character)
	self.Movement:SetWeight(self.Config.EQUIP_LOAD)

	local ADS = self.Config.AimDownSights
	local equipped = self.ViewModel:Equip(self.vWeapon, {
		JOINT_C1 = self.Config.Equip.JOINT_C1,
		CAMERA_OFFSET = self.Config.Equip.CAM_OFFSET,
		TILT_HOLD = self.Config.Equip.TILT,
		SCALE = self.Config.Equip.SCALE,
		BOB_MOD = ADS and ADS.BOB_MOD,
		TILT_AIMED = ADS and ADS.TILT,
		CAN_AIM = ADS ~= nil,
	})

	if not equipped then
		reparent(self.wWeapon, Player:FindFirstChild("Hotbar"))
		return false
	end

	self.KeyBegan = self._trove:Connect(UserInputService.InputBegan, function(Input, GameProcessed)
		if not GameProcessed and self.Enabled then
			self:_Callback(Input)
		end
	end)

	self.KeyEnded = self._trove:Connect(UserInputService.InputEnded, function(Input, GameProcessed)
		if not GameProcessed and self.Enabled then
			self:_Callback(Input)
		end
	end)

	self.ViewModel:SetSwayState(self.Config.Equip.CAN_SWAY)
	return true
end

function BaseWeapon:_Unequip()
	self:CancelActions()
	reparent(self.wWeapon, Player:FindFirstChild("Hotbar"))
	reparent(self.vWeapon, Player:FindFirstChild("vHotbar"))

	if self.ViewModel:IsAlive() then
		self.ViewModel:Unequip()
	end

	self.Effects:RemoveAll()

	self._trove:Remove(self.KeyBegan)
	self._trove:Remove(self.KeyEnded)
	self.Movement:SetWeight(1)
end

function BaseWeapon:Destroy()
	if self.Destroyed then return end

	self:Unequip(true)
	self.Destroyed = true
	self._trove:Destroy()
end

return BaseWeapon
