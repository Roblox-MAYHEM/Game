local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Player = game:GetService("Players").LocalPlayer

local WeaponSystem = script.Parent
local WeaponAssets = ReplicatedStorage.Assets.Weapons

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

local function LoadChildren(parent: Instance): {[string]: any}
	local result = {}

	for _, child in ipairs(parent:GetChildren()) do
		if child.Name:find("_HotReload") then continue end

		if child:IsA("Folder") then result[child.Name] = LoadChildren(child)
		elseif child:IsA("ModuleScript") then result[child.Name] = requireFresh(child)
		else result[child.Name] = child end
	end

	return result
end

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

	local NameValue = Instance.new("StringValue")
	NameValue.Name = "Name"
	NameValue.Value = self.Name
	NameValue.Parent = self.wWeapon

	for DataType, Module in pairs(LoadChildren(WeaponAssets.Data)) do
		self[DataType] = Module[self.Name]
	end

	if self.Sounds then
		local Sounds = {}
		for Name, SoundData in self.Sounds do
			Sounds[Name] = self._trove:Add(SoundController.new(SoundData, nil, Name))
		end
		self.Sounds = Sounds
	end

	if self.Animations then
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
	end

	for _, Name in self.Behaviors do
		local Behavior = require(script.Parent.Behaviors:WaitForChild(Name))
		Behavior.__init(self)
		for Key, Value in Behavior do
			self[Key] = Value
		end
	end

	self:_KeybindSetup()
end

function BaseWeapon.new(opts)
	local context = opts.Context or {}
	local Character = context.Character or (context.Player or Player).Character or (context.Player or Player).CharacterAdded:Wait()

	return setmetatable({
		Player = context.Player or Player,
		Character = Character,
		HRP = Character:WaitForChild("HumanoidRootPart"),
		ViewModel = context.ViewModel,
		Movement = context.Movement,
		Camera = context.Camera,
		Physics = context.Physics,
		PlayerEffects = context.PlayerEffects,
		Projectile = context.Projectile,

		Name = opts.Name,
		wWeapon = opts.WeaponModel,
		Binds = opts.Binds or {},
		Behaviors = opts.Behaviors or {},
		States = {
			Equipped = false,
			Equipping = false,
		},
		Enabled = true,
	}, BaseWeapon)
end

function BaseWeapon:SetEnable(val: boolean)
	self.Enabled = val
end

function BaseWeapon:_CanEquip()
	return not self.Destroyed
		and self.Character
		and self.Character:IsDescendantOf(game)
		and self.HRP
		and self.HRP:IsDescendantOf(self.Character)
		and self.ViewModel
		and self.ViewModel.IsAlive
		and self.ViewModel:IsAlive()
		and self.Movement
		and self.Movement.Ready
		and self.Movement.SetWeight
		and self.wWeapon
		and self.vWeapon
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
	reparent(self.wWeapon, Player:FindFirstChild("Hotbar"))
	reparent(self.vWeapon, Player:FindFirstChild("vHotbar"))

	if self.ViewModel and self.ViewModel.IsAlive and self.ViewModel:IsAlive() then
		self.ViewModel:Unequip()
	end

	if self.Effects then
		self.Effects:RemoveAll()
	end

	self._trove:Remove(self.KeyBegan)
	self._trove:Remove(self.KeyEnded)
	self._trove:Remove(self.CamState)

	if self.Movement then
		self.Movement:SetWeight(1)
	end
end

function BaseWeapon:Destroy()
	if self.Destroyed then return end

	self.Destroyed = true
	self:_Unequip()
	self._trove:Destroy()
end

return BaseWeapon
