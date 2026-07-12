local Players = game:GetService("Players")

local DEFAULTS = {
	Window = 1,
	Grace = 0.08,
	Range = 9,
	Arc = 110,
	Debounce = 0.12,
	LOS = false,
	CanDamage = function() return true end,
	IgnoreInstance = function() return false end,
}

local MeleeValidator = {}
MeleeValidator.__index = MeleeValidator

local function root(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function humanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

function MeleeValidator.new(attacker, config)
	local settings = table.clone(DEFAULTS)
	for key, value in pairs(config or {}) do settings[key] = value end
	return setmetatable({
		Attacker = attacker,
		Config = settings,
		WindowEndsAt = 0,
		LastHitAt = {},
	}, MeleeValidator)
end

function MeleeValidator:BeginAttack()
	self.WindowEndsAt = time() + self.Config.Window + self.Config.Grace
	table.clear(self.LastHitAt)
	return true
end

function MeleeValidator:EndAttack()
	self.WindowEndsAt = 0
	return true
end

function MeleeValidator:_HasLineOfSight(attackerRoot, targetRoot, target)
	if not self.Config.LOS then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.Attacker }
	params.IgnoreWater = true

	local result = workspace:Raycast(attackerRoot.Position, targetRoot.Position - attackerRoot.Position, params)
	return result == nil
		or result.Instance:IsDescendantOf(target)
		or self.Config.IgnoreInstance(result.Instance)
end

function MeleeValidator:ValidateHit(target)
	if typeof(target) ~= "Instance" or not target:IsA("Model") or target == self.Attacker then
		return false, "bad-target"
	end
	if time() > self.WindowEndsAt then return false, "window-closed" end

	local attackerRoot, targetRoot = root(self.Attacker), root(target)
	local targetHumanoid = humanoid(target)
	if not attackerRoot or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return false, "missing-character"
	end

	local lastHit = self.LastHitAt[target]
	if lastHit and time() - lastHit < self.Config.Debounce then return false, "debounced" end

	local attackerPlayer = Players:GetPlayerFromCharacter(self.Attacker)
	local targetPlayer = Players:GetPlayerFromCharacter(target)
	if not self.Config.CanDamage(attackerPlayer, targetPlayer) then return false, "friendly-fire" end

	local delta = targetRoot.Position - attackerRoot.Position
	if delta.Magnitude > self.Config.Range then return false, "out-of-range" end
	if delta.Magnitude > 0.001 then
		local minDot = math.cos(math.rad(self.Config.Arc))
		if attackerRoot.CFrame.LookVector:Dot(delta.Unit) < minDot then return false, "outside-arc" end
	end
	if not self:_HasLineOfSight(attackerRoot, targetRoot, target) then return false, "blocked" end

	self.LastHitAt[target] = time()
	return true
end

function MeleeValidator:Cleanup()
	self:EndAttack()
	table.clear(self.LastHitAt)
end

return MeleeValidator
