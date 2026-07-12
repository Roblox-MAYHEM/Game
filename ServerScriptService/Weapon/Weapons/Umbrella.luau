--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Behaviors will perform certain weapon-specific moves.
Modularized for easier reuse and combination.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local DamageHandler = require(WeaponSystem.Modules.DamageHandler)
local ImpactService = require(WeaponSystem.Modules.ImpactService)
local MeleeValidator = require(Modules.MeleeValidator)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

function Weapon.new(WeaponModel : Model, player : Player)
	local self = BaseWeapon.new({
		["Player"] 		= player,
		["WeaponModel"] 	= WeaponModel,
		["Name"]		= WeaponModel.Name,
	})

	setmetatable(self, Weapon)

	self.LungeInfo = self.Config.Lunge

	self.LungeValidator = MeleeValidator.new(self.Character, { -- Settings
		Window = self.LungeInfo.WINDOW,
		Range = self.LungeInfo.RANGE,
		Arc = self.LungeInfo.ARC,
		Debounce = self.LungeInfo.HIT_DEBOUNCE,
		LOS = self.LungeInfo.LOS,
	})
	
	return self
end

function Weapon:_SetCollision(val : boolean)
	for _, v in self.Character:GetChildren() do
		if v:isA("BasePart") then
			v.CollisionGroup = val and "Players" or "NoCollision"
		end
	end
end

function Weapon:ProcessHit(targetCharacter)
	local ok, reason = self.LungeValidator:ValidateHit(targetCharacter)
	
	if not ok then return false end

	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local attackerRoot = self.Character:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		local direction = attackerRoot and targetRoot and (targetRoot.Position - attackerRoot.Position) or Vector3.zAxis

		ImpactService.ApplyHit(targetCharacter, self.Player, {
			Power = self.LungeInfo.IMPACT_POWER,
			Direction = direction,
			FinisherMultiplier = self.LungeInfo.FINISHER_MULTIPLIER,
			UpwardVelocity = self.LungeInfo.FINISHER_Y,
		})
		DamageHandler.DamageHumanoid(humanoid, self.Player, self.LungeInfo.DMG, false)
	end

	return true
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end

function Weapon:Lunge()
	self:_SetCollision(false)
	self.LungeValidator:BeginAttack()
	return true
end

function Weapon:CancelLunge()
	self:_SetCollision(true)
	self.LungeValidator:EndAttack()
end

return Weapon
