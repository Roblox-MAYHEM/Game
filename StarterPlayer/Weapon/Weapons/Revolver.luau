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
			[Enum.UserInputType.MouseButton2]	=	"FanFire",
			[Enum.KeyCode.R] 					= 	"Reload",
		},
	[Enum.UserInputState.End] =
		{
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

function Weapon:FanFire()
	-- Don't fan fire if already shooting, reloading, or aiming
	if self.States.TriggerHeld or self.States.Reloading or self.States.Aiming then return end
	if self.Ammo.Value <= 0 then return end

	self.States.TriggerHeld = true
	self.States.Fanning = true

	task.spawn(function()
		-- We use a faster fire rate and force UpdateSpread to recognize fanning
		local fanRate = self.ShootInfo.FAN_FIRE_RATE or 0.1 

		while self.States.TriggerHeld and self.Ammo.Value > 0 do
			-- Call the base _ShootOnce with the faster cooldown
			local success = self:_ShootOnce(fanRate)

			if not success then break end

			-- Optional: Add extra kick/recoil per fan shot
			self.ViewModel:AdjustSpring("recoil", self.ShootInfo.RECOIL * 1.5)
		end

		self.States.TriggerHeld = false
		self.States.Fanning = false
		self:UpdateSpread() -- Reset spread visual
	end)
end

function Weapon:StopFanFire()
	self.States.TriggerHeld = false
	self.States.Fanning = false
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
