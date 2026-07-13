local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Knockback = require(script.Parent.Knockback)

local Config = {
	MaxImpact = 100,
	PrimedPips = 3,
	PrimedArmTime = 0.35,
	PrimedDuration = 5,
	FinisherInterval = 0.55,
	ProtectionDuration = 1.15,
	DecayDelay = 4.5,
	DecayPerSecond = 6,
	EscapedImpact = 70,
	ConsumedImpact = 40,
	PushPerPower = 1.5,
	PushDuration = 0.14,
	MaxPushGrowth = 1.25,
	FinisherBaseSpeed = 70,
	FinisherPowerScale = 1.25,
	FinisherDuration = 0.2,
	AttributionTime = 8,
}

export type ImpactHit = {
	Power: number,
	Direction: Vector3,
	FinisherMultiplier: number?,
	UpwardVelocity: number?,
}

type ImpactState = {
	Impact: number,
	LastHitAt: number,
	PrimedUntil: number,
	Pips: number,
	NextFinisherAt: number,
	ProtectedUntil: number,
	LastAttacker: Player?,
}

local ImpactService = {}
local states: { [Model]: ImpactState } = {}

local function setAttributes(character: Model, state: ImpactState)
	character:SetAttribute("Impact", state.Impact)
	character:SetAttribute("ImpactPrimed", state.Pips > 0)
	character:SetAttribute("ImpactPips", state.Pips)
	character:SetAttribute("ImpactProtected", time() < state.ProtectedUntil)
end

local function getState(character: Model): ImpactState
	if states[character] then
		return states[character]
	end

	local state = {
		Impact = 0,
		LastHitAt = time(),
		PrimedUntil = 0,
		Pips = 0,
		NextFinisherAt = 0,
		ProtectedUntil = 0,
		LastAttacker = nil,
	}

	states[character] = state
	setAttributes(character, state)
	return state
end

local function isAlive(character: Model): boolean
	if not character.Parent or character:GetAttribute("Dead") == true then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function isTeammate(attacker: Player, targetCharacter: Model): boolean
	local victim = Players:GetPlayerFromCharacter(targetCharacter)
	return victim ~= nil
		and victim ~= attacker
		and victim.Team ~= nil
		and attacker.Team ~= nil
		and victim.Team == attacker.Team
end

local function endPrimed(character: Model, state: ImpactState, resetImpact: number)
	state.Pips = 0
	state.PrimedUntil = 0
	state.NextFinisherAt = 0
	state.Impact = resetImpact
	state.ProtectedUntil = time() + Config.ProtectionDuration
	setAttributes(character, state)
end

local function enterPrimed(character: Model, state: ImpactState, now: number)
	state.Impact = Config.MaxImpact
	state.Pips = Config.PrimedPips
	state.PrimedUntil = now + Config.PrimedDuration
	state.NextFinisherAt = now + Config.PrimedArmTime
	setAttributes(character, state)
end

local function applyPush(character: Model, state: ImpactState, hit: ImpactHit)
	local meterAlpha = math.clamp(state.Impact / Config.MaxImpact, 0, 1)
	local growth = math.lerp(1, Config.MaxPushGrowth, meterAlpha)
	local speed = hit.Power * Config.PushPerPower * growth

	Knockback(character, hit.Direction.Unit, {
		FORCE = speed,
		DURATION = Config.PushDuration,
		MODE = "Push",
	})
end

local function applyFinisher(character: Model, hit: ImpactHit)
	local multiplier = hit.FinisherMultiplier or 1
	local speed = (Config.FinisherBaseSpeed + hit.Power * Config.FinisherPowerScale) * multiplier

	Knockback(character, hit.Direction.Unit, {
		FORCE = speed,
		Y = hit.UpwardVelocity,
		DURATION = Config.FinisherDuration,
		MODE = "Finisher",
	})
end

function ImpactService.ApplyHit(targetCharacter: Model, attacker: Player, hit: ImpactHit)
	if not targetCharacter or not attacker or not isAlive(targetCharacter) or isTeammate(attacker, targetCharacter) then
		return
	end
	if typeof(hit.Power) ~= "number"
		or hit.Power <= 0
		or typeof(hit.Direction) ~= "Vector3"
		or hit.Direction.Magnitude <= 0.001
	then
		return
	end

	local state = getState(targetCharacter)
	local now = time()
	state.LastHitAt = now

	if state.Pips > 0 and now >= state.NextFinisherAt then
		applyFinisher(targetCharacter, hit)
		state.LastAttacker = attacker
		state.Pips -= 1
		state.NextFinisherAt = now + Config.FinisherInterval

		if state.Pips <= 0 then
			endPrimed(targetCharacter, state, Config.ConsumedImpact)
		else
			setAttributes(targetCharacter, state)
		end

		return
	end

	applyPush(targetCharacter, state, hit)
	state.LastAttacker = attacker

	if state.Pips <= 0 then
		state.Impact = math.min(Config.MaxImpact, state.Impact + hit.Power)
		if state.Impact >= Config.MaxImpact and now >= state.ProtectedUntil then
			enterPrimed(targetCharacter, state, now)
		else
			setAttributes(targetCharacter, state)
		end
	end
end

function ImpactService.GetRecentAttacker(targetCharacter: Model): Player?
	local state = states[targetCharacter]
	if not state or time() - state.LastHitAt > Config.AttributionTime then
		return nil
	end

	local attacker = state.LastAttacker
	return if attacker and attacker.Parent == Players then attacker else nil
end

function ImpactService.Clear(character: Model)
	if not character then return end
	states[character] = nil
	character:SetAttribute("Impact", 0)
	character:SetAttribute("ImpactPrimed", false)
	character:SetAttribute("ImpactPips", 0)
	character:SetAttribute("ImpactProtected", false)
end

RunService.Heartbeat:Connect(function(dt)
	local now = time()

	for character, state in pairs(states) do
		if not character.Parent then
			states[character] = nil
			continue
		end

		if state.Pips > 0 and now >= state.PrimedUntil then
			endPrimed(character, state, Config.EscapedImpact)
			continue
		end

		local shouldSync = character:GetAttribute("ImpactProtected") == true and now >= state.ProtectedUntil

		if state.Pips <= 0
			and state.Impact > 0
			and now - state.LastHitAt >= Config.DecayDelay
		then
			local nextImpact = math.max(0, state.Impact - Config.DecayPerSecond * dt)
			shouldSync = shouldSync
				or math.floor(nextImpact) ~= math.floor(state.Impact)
				or nextImpact == 0
			state.Impact = nextImpact
		end

		if shouldSync then
			setAttributes(character, state)
		end
	end
end)

return ImpactService
