--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Weapons will perform certain weapon-specific moves.
Also fires events to server.
]]


local RunService		= game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")

local WeaponSystem 		= script.Parent.Parent
local Libraries 	= Client.Libraries
local Remotes 		= ReplicatedStorage.Events
local Bindables		= Client.Bindables
local WeaponAssets 	= ReplicatedStorage.Assets.Weapons
local Packages = ReplicatedStorage.Packages

local Trove = require(Packages.Trove)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

-- Weapon Class
local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] =
		{
			[Enum.UserInputType.MouseButton1]	=	"BeginFlames",
		},
	[Enum.UserInputState.End] =
		{
			[Enum.UserInputType.MouseButton1]	=	"EndFlames",
		}
}

function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
	})
	
	setmetatable(self, Weapon)
	self:_init()
	
	self.States = {
		Equipped = false,
		Equipping = false,
		Burning = false
	}
	
	self.canBurn = true
	self.CanBurn = true

	self.BurnInfo = self.Config.Burn

	self.Ammo = self.BurnInfo.MAX_AMMO
		
	self.Effects:Register("Held", function(weapon)
		weapon.Shoot.SmallFire.Enabled = true
	end)
		
	self.Effects:Register("EnableFlames", function(weapon)
		--// todo: make more advanced replication for future if necessary (ie. split off effects into own file)
		weapon.Shoot.BigFire.Enabled = true
	end)
	
	self.Effects:Register("DisableFlames", function(weapon)
		weapon.Shoot.BigFire.Enabled = false
	end)
	
	return self
end

function Weapon:Equip()	
	if not self:_Equip() then return end --calls weapon base
	
	self.Effects:Play("Held")

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

	self.Animations.Idle:Play()
end

function Weapon:_UpdateFlames(dt)
	--Update values
	for i, v in pairs(self.Timers) do
		self.Timers[i] += dt
	end

	if self.Timers.AmmoReset >= self.BurnInfo.AMMO_TIME then
		self.Ammo -= 1
		self.Timers.AmmoReset = 0
	end

	if self.Timers.UpdateServer >= self.BurnInfo.UPDATE_SERVER then
		--Fires V_Weapon shoot's CFrame
		Remotes.WeaponEvent:FireServer("UpdateFlames", self.WeaponModel[1].Shoot.CFrame) -- TODO: Flamethrower doesn't have Shoot
		self.Timers.UpdateServer = 0
	end

	if self.Ammo <= 0 then
		self.CanFire = false
		self:EndFlames()
	end
end

function Weapon:BeginFlames()
	if self.States.Burning then return end


	self.Timers = {
		AmmoReset = 0, --Time between ammo subtract
		UpdateServer = 0, -- Time between server updates
	}

	self.Sounds.Shoot:FadeIn(2)
	self.Effects:Play("EnableFlames")
	self.States.Burning = true

	Remotes.WeaponEvent:FireServer("EnterFlames", self.ViewModel.Weapon.Shoot.CFrame)

	self.BurnInfoLoop = RunService.Heartbeat:Connect(function(dT)
		self:_UpdateFlames(dT)
	end)
end

function Weapon:EndFlames()
	if not self.States.Burning then return end

	self.BurnInfoLoop:Disconnect()
	self.States.Burning = false
	self.Effects:Play("DisableFlames")
	self.Sounds.Shoot:FadeOut(.5)

	Remotes.WeaponEvent:FireServer("ExitFlames")
end

function Weapon:Unequip()
	self:_Unequip() --calls weapon base
	
	self:EndFlames()
	
	self.States.Equipping = false
	self.States.Equipped = false
	for _, v in pairs(self.Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end

end

return Weapon
