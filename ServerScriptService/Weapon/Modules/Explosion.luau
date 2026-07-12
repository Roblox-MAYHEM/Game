--[[
Objectives:
- Creates + handles explosion area hitboxing
- Deals damage according to appropriate damage drop-off
- Sends request to client to create visual effects
]]

local PlayersService	= game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes		= ReplicatedStorage.Events
local Modules		= script.Parent

local DamageHandler = require(Modules.DamageHandler)
local ImpactService = require(Modules.ImpactService)
local Knockback = require(Modules.Knockback)

local OverlapParam = OverlapParams.new()
OverlapParam.FilterType = Enum.RaycastFilterType.Exclude

local function DetectHumanoidFromPart(part)
	if not part or not part:IsA("BasePart") then return nil end

	local character = part:FindFirstAncestorWhichIsA("Model")
	if character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			return humanoid
		end
	end

	return nil
end

local function CalculateDmgDropOff(Distance : number, Radius : number, MinDamage : number, MaxDamage : number) : number
	local falloff = 1 - (Distance / Radius)
	local dmg = falloff * (MaxDamage - MinDamage) + MinDamage
	return dmg
end

return function(hitPosition : Vector3, Sender : Player, ExplosionInfo, IgnoreHumanoids : {Humanoid}?)
	-- Visuals
	Remotes.ReplicateEffect:FireAllClients(
		"Explosion2Effect", 
		hitPosition, 
		ExplosionInfo.RADIUS, 
		ExplosionInfo.DURATION
	)

	OverlapParam.FilterDescendantsInstances = {unpack(IgnoreHumanoids or {})}
	local results = workspace:GetPartBoundsInRadius(hitPosition, ExplosionInfo.RADIUS, OverlapParam)
	if not results then return end

	local HitHumanoids = {}

	for _, part in pairs(results) do
		local Humanoid = DetectHumanoidFromPart(part)
		if Humanoid and not table.find(HitHumanoids, Humanoid) then
			table.insert(HitHumanoids, Humanoid)

			local Character = Humanoid.Parent
			local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
			local HitPlr = Character and PlayersService:GetPlayerFromCharacter(Character)
			if not HRP then continue end

			-- Damage falloff
			local Distance = (HRP.Position - hitPosition).Magnitude
			local Damage = CalculateDmgDropOff(
				Distance, 
				ExplosionInfo.RADIUS, 
				ExplosionInfo.MIN_DMG, 
				ExplosionInfo.MAX_DMG
			)
			if HitPlr == Sender then
				Damage = CalculateDmgDropOff(
					Distance, 
					ExplosionInfo.RADIUS, 
					0, 
					ExplosionInfo.SELF_DMG or 0
				)
			end

			-- Base direction (no Y_INFLUENCE anymore)
			local rawDirection
			if HitPlr ~= Sender then
				rawDirection = HRP.Position - hitPosition
			else
				rawDirection = (Character:FindFirstChild("Head") and Character.Head.Position or HRP.Position) - hitPosition
			end
			-- Raycast to clamp force based on line-of-sight distance
			local rayResult = workspace:Raycast(hitPosition, HRP.Position - hitPosition)
			local pos = rayResult and rayResult.Position or HRP.Position

			local hitDist = (pos - hitPosition).Magnitude
			hitDist = math.clamp(hitDist, 0, ExplosionInfo.RADIUS)
			local t = hitDist / ExplosionInfo.RADIUS
			local magnitude = math.lerp(ExplosionInfo.IMPULSE_MAX, ExplosionInfo.IMPULSE_MIN, t)

			if HitPlr == Sender or not ExplosionInfo.IMPACT_MAX then
				Knockback(Character, rawDirection, {
					IMPULSE = magnitude,
					YMAX = ExplosionInfo.Y_MAX,
				})
			else
				local impactPower = math.lerp(ExplosionInfo.IMPACT_MAX, ExplosionInfo.IMPACT_MIN, t)
				ImpactService.ApplyHit(Character, Sender, {
					Power = impactPower,
					Direction = rawDirection,
					FinisherMultiplier = ExplosionInfo.FINISHER_MULTIPLIER,
				})
			end

			-- Apply damage
			DamageHandler.DamageHumanoid(Humanoid, Sender, Damage, false)
		end
	end
end
