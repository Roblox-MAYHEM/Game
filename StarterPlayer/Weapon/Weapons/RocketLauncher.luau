local WeaponSystem = script.Parent.Parent
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] =
		{
			[Enum.UserInputType.MouseButton1]	=	"Shoot", --[Input] : Behavior
			[Enum.KeyCode.R] 					= 	"Reload",
		},
	[Enum.UserInputState.End] =
		{
			[Enum.UserInputType.MouseButton1]   =   "StopShooting",
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
