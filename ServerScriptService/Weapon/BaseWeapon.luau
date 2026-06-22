local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Events
local WeaponAssets = ReplicatedStorage.Assets.Weapons
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

local function LoadChildren(Parent: Instance): {}
	local Table = {}
	for _, Module in ipairs(Parent:GetChildren()) do
		if Module:IsA("ModuleScript") and not Module.Name:find("_HotReload") then
			Table[Module.Name] = requireFresh(Module)
		end
	end
	return Table
end

local function reparent(instance: Instance?, parent: Instance?)
	if instance and instance.Parent and parent then
		instance.Parent = parent
	end
end

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

local Context = {}

local function init(self)
	for DataType, Module in pairs(LoadChildren(WeaponAssets.Data)) do
		self[DataType] = Module[self.Name]
	end
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

	self.Connection = self._trove:Connect(Remotes.WeaponEvent.OnServerEvent, function(player, Callback, ...)
		if Callback == "Shoot" then return end

		if player == self.Player and self:_CanUse() and self[Callback] then
			self[Callback](self, ...)
		end
	end)

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

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function BaseWeapon:Destroy()
	if self.Destroyed then return end

	self:_Unequip()
	self.Destroyed = true
	self._trove:Destroy()
end

return BaseWeapon
