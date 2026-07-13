local WeaponSystem = script.Parent.Parent

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
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
			[Enum.UserInputType.MouseButton2]	= 	"StopFanFire",
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
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()

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
