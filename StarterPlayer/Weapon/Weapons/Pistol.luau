--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Weapons will perform certain weapon-specific moves.
Also fires events to server.
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")

local WeaponSystem 		= script.Parent.Parent
local Libraries 	= Client.Libraries
local Remotes 		= ReplicatedStorage.Events
local Bindables		= Client.Bindables
local WeaponAssets 	= ReplicatedStorage.Assets.Weapons

local Fusion = require(Client.Packages.Fusion)
local peek = Fusion.peek

local BaseWeapon = require(WeaponSystem.BaseWeapon)

-- Weapon Class
local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] =
		{
			[Enum.UserInputType.MouseButton1]	=	"Shoot", --[Input] : Behavior
			[Enum.UserInputType.MouseButton2] 	= 	"EnterADS",
			[Enum.KeyCode.R] 					= 	"Reload",
			[Enum.KeyCode.T] 					= 	"_ClearDebug",
		},
	[Enum.UserInputState.End] =
		{
			[Enum.UserInputType.MouseButton1]   =   "StopShooting",
			[Enum.UserInputType.MouseButton2]	=	"ExitADS",
		}
}

function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
		Behaviors = {"Ranged"},
	})
	setmetatable(self, Weapon)
	self:_init()

	self.States = {
		Equipped = false,
		Equipping = false,
		Aiming = false,
		Shooting = false,
		Reloading = false,
	}

	return self
end

function Weapon:Equip()	
	if not self:_Equip() then return end --calls weapon base

	self.States.Equipping = true
	if self.Animations.Equip then
		self.Animations.Equip:Play()
		self.Animations.Equip.Stopped:Wait()
	else
		task.wait(self.Config.Equip.TIME)
	end

	if not self.States.Equipping then return end
	self.States.Equipping = false
	self.States.Equipped = true

	if self.Ammo.Value <= 0 then
		self:_HandleAutoReload()
	end

	self.Animations.Idle:Play()
end

function Weapon:Unequip()
	self:_Unequip() --calls weapon base

	self.States.Equipping = false
	self.States.Equipped = false
	for _, v in pairs(self.Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end

end

return Weapon
