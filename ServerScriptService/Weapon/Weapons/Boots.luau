local WeaponSystem = script.Parent.Parent
local Modules = WeaponSystem.Modules

local BaseWeapon = require(WeaponSystem.BaseWeapon)
local DamageHandler = require(Modules.DamageHandler)
local ImpactService = require(Modules.ImpactService)
local MeleeValidator = require(Modules.MeleeValidator)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

local function humanoidsInRadius(position, radius, ignore)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ignore }
	local found = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid then found[humanoid] = model end
	end
	return found
end

function Weapon.new(model, player)
	local self = BaseWeapon.new({ Player = player, WeaponModel = model, Name = model.Name })
	setmetatable(self, Weapon)
	self.AttackInfo = self.Config.Attack
	self.StompInfo = self.Config.Stomp
	self.AttackValidator = MeleeValidator.new(self.Character, {
		Window = self.AttackInfo.WINDOW,
		Range = self.AttackInfo.RANGE,
		Arc = self.AttackInfo.ARC,
		Debounce = self.AttackInfo.HIT_DEBOUNCE,
		LOS = self.AttackInfo.LOS,
	})
	return self
end

function Weapon:Equip()
	self.StompReady = self:_Equip() == true
end

function Weapon:Unequip()
	self.StompReady = false
	self:_Unequip()
end

function Weapon:AttackStart()
	return self.AttackValidator:BeginAttack()
end

function Weapon:ProcessHit(target)
	local ok = self.AttackValidator:ValidateHit(target)
	if not ok then return false end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	local attackerRoot = self.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not humanoid or not attackerRoot or not targetRoot then return false end

	ImpactService.ApplyHit(target, self.Player, {
		Power = self.AttackInfo.IMPACT_POWER,
		Direction = targetRoot.Position - attackerRoot.Position,
		FinisherMultiplier = self.AttackInfo.FINISHER_MULTIPLIER,
		UpwardVelocity = self.AttackInfo.FINISHER_Y,
	})
	DamageHandler.DamageHumanoid(humanoid, self.Player, self.AttackInfo.DMG, false)
	return true
end

function Weapon:Stomp(position, directTarget, downwardSpeed)
	if not self.StompReady or typeof(position) ~= "Vector3" then return false end
	self.StompReady = false
	downwardSpeed = math.max(tonumber(downwardSpeed) or 0, 0)
	local scale = math.clamp(downwardSpeed / self.StompInfo.REFERENCE_SPEED, 0.6, 1.8)

	for humanoid, character in pairs(humanoidsInRadius(position, self.StompInfo.RADIUS, self.Character)) do
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local direct = character == directTarget
			local multiplier = direct and self.StompInfo.DIRECT_MULTIPLIER or 1
			local direction = root.Position - position
			if direction.Magnitude <= 0.001 then direction = Vector3.yAxis end

			ImpactService.ApplyHit(character, self.Player, {
				Power = self.StompInfo.IMPACT_POWER * scale * multiplier,
				Direction = direction,
				FinisherMultiplier = self.StompInfo.FINISHER_MULTIPLIER * multiplier,
				UpwardVelocity = self.StompInfo.FINISHER_Y,
			})
			DamageHandler.DamageHumanoid(
				humanoid,
				self.Player,
				self.StompInfo.DMG * scale * multiplier,
				false
			)
		end
	end
	return true
end

return Weapon
