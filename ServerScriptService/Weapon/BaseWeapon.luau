local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeaponAssets = ReplicatedStorage.Assets.Weapons
local ConfigModule = WeaponAssets.Data.Config
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

local function reparent(instance: Instance?, parent: Instance?)
	if instance and instance.Parent and parent then
		instance.Parent = parent
	end
end

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

local Context = {}

local function init(self)
	self.Config = assert(ConfigData[self.Name], `Missing Config for {self.Name}`)
end

function BaseWeapon.new(opts)
	local self = setmetatable({
		WeaponModel = opts.WeaponModel:Clone(),
		Name = opts.Name,
		Player = opts.Player,
		Character = opts.Player.Character or opts.Player.CharacterAdded:Wait(),
		Projectile = opts.Projectile or Context.Projectile,
		_trove = Trove.new(),
	}, BaseWeapon)

	self._trove:Add(self.WeaponModel)
	self.WeaponModel.Parent = opts.Player.Hotbar
	self.WeaponModel:AddTag("Weapon")
	init(self)

	return self
end

function BaseWeapon.SetContext(context)
	Context = context or {}
end

function BaseWeapon.ReloadConfig()
	ConfigData = requireFresh(ConfigModule)
end

function BaseWeapon.GetConfig(name: string)
	return ConfigData[name]
end

BaseWeapon.ReloadConfig()

function BaseWeapon:_CanUse()
	local character = self.Player and self.Player.Character
	return not self.Destroyed
		and self.Player
		and self.Player:GetAttribute("Deployed") == true
		and character
		and character == self.Character
		and character:IsDescendantOf(game)
		and self.WeaponModel
end

function BaseWeapon:_Equip()
	if not self:_CanUse() then
		self.Equipped = false
		return false
	end

	reparent(self.WeaponModel, self.Character)

	local RightArm = self.Character:FindFirstChild("Right Arm")
	local Grip = RightArm and RightArm:FindFirstChild("Grip")
	local Primary = self.WeaponModel:FindFirstChild("Handle") or self.WeaponModel:FindFirstChild("Primary")

	if Grip and Primary then
		local HandleAttach = Primary:FindFirstChild("HandleAttachment")
		Grip.Part1 = Primary
		Grip.C1 = self.Config.Equip.JOINT_C1 or (HandleAttach and HandleAttach.CFrame) or CFrame.new()
	end

	self.Equipped = true
	return true
end

function BaseWeapon:_Unequip()
	if self.Destroyed then return end
	self.Equipped = false
	if not self.Character then return end

	local RightArm = self.Character:FindFirstChild("Right Arm")
	local Grip = RightArm and RightArm:FindFirstChild("Grip")

	if Grip then
		Grip.Part1 = nil
	end

	reparent(self.WeaponModel, self.Player:FindFirstChild("Hotbar"))

end

function BaseWeapon:Destroy()
	if self.Destroyed then return end

	self:Unequip(true)
	self.Destroyed = true
	self._trove:Destroy()
end

return BaseWeapon
