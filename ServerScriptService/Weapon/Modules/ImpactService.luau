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
	PushPerPower = 0.55,
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
	Flat: boolean?,
	UpwardVelocity: number?,
	Source: string?,
}

type ImpactState = {
	Impact: number,
	LastHitAt: number,
	Primed: boolean,
	PrimedUntil: number,
	PrimedReadyAt: number,
	Pips: number,
	NextFinisherAt: number,
	ProtectedUntil: number,
	LastAttacker: Player?,
}

local ImpactService = {}
local states: { [Model]: ImpactState } = {}
local initialized = false

local function setAttributes(character: Model, state: ImpactState)
	character:SetAttribute("Impact", state.Impact)
	character:SetAttribute("ImpactPrimed", state.Primed)
	character:SetAttribute("ImpactPips", state.Pips)
	character:SetAttribute("ImpactProtected", time() < state.ProtectedUntil)
end

local function newState(character: Model): ImpactState
	local state = {
		Impact = 0,
		LastHitAt = time(),
		Primed = false,
		PrimedUntil = 0,
		PrimedReadyAt = 0,
		Pips = 0,
		NextFinisherAt = 0,
		ProtectedUntil = 0,
		LastAttacker = nil,
	}

	states[character] = state
	setAttributes(character, state)

	character.Destroying:Once(function()
		states[character] = nil
	end)

	return state
end

local function getState(character: Model): ImpactState
	return states[character] or newState(character)
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

local function finishPrimed(character: Model, state: ImpactState, escaped: boolean)
	state.Primed = false
	state.Pips = 0
	state.PrimedUntil = 0
	state.PrimedReadyAt = 0
	state.NextFinisherAt = 0
	state.Impact = if escaped then Config.EscapedImpact else Config.ConsumedImpact
	state.ProtectedUntil = time() + Config.ProtectionDuration
	setAttributes(character, state)
end

local function enterPrimed(character: Model, state: ImpactState, now: number)
	state.Impact = Config.MaxImpact
	state.Primed = true
	state.Pips = Config.PrimedPips
	state.PrimedReadyAt = now + Config.PrimedArmTime
	state.PrimedUntil = now + Config.PrimedDuration
	state.NextFinisherAt = state.PrimedReadyAt
	setAttributes(character, state)
end

local function normalizedDirection(direction: Vector3): Vector3?
	if typeof(direction) ~= "Vector3" or direction.Magnitude <= 0.001 then
		return nil
	end
	return direction.Unit
end

local function applyPush(character: Model, state: ImpactState, hit: ImpactHit)
	local direction = normalizedDirection(hit.Direction)
	if not direction then return end

	local meterAlpha = math.clamp(state.Impact / Config.MaxImpact, 0, 1)
	local growth = math.lerp(1, Config.MaxPushGrowth, meterAlpha)
	local speed = hit.Power * Config.PushPerPower * growth

	Knockback(character, direction, {
		FORCE = speed,
		FLAT = hit.Flat,
		MODE = "Push",
		SOURCE = hit.Source,
	})
end

local function applyFinisher(character: Model, hit: ImpactHit)
	local direction = normalizedDirection(hit.Direction)
	if not direction then return false end

	local multiplier = hit.FinisherMultiplier or 1
	local speed = (Config.FinisherBaseSpeed + hit.Power * Config.FinisherPowerScale) * multiplier

	Knockback(character, direction, {
		FORCE = speed,
		Y = hit.UpwardVelocity,
		FLAT = hit.Flat,
		DURATION = Config.FinisherDuration,
		MODE = "Finisher",
		SOURCE = hit.Source,
	})

	return true
end

function ImpactService.ApplyHit(targetCharacter: Model, attacker: Player, hit: ImpactHit): boolean
	if not targetCharacter or not attacker or not isAlive(targetCharacter) or isTeammate(attacker, targetCharacter) then
		return false
	end
	if not hit or typeof(hit.Power) ~= "number" or hit.Power <= 0 then
		return false
	end

	local state = getState(targetCharacter)
	local now = time()
	state.LastHitAt = now

	if state.Primed
		and state.Pips > 0
		and now >= state.PrimedReadyAt
		and now >= state.NextFinisherAt
	then
		if applyFinisher(targetCharacter, hit) then
			state.LastAttacker = attacker
			state.Pips -= 1
			state.NextFinisherAt = now + Config.FinisherInterval

			if state.Pips <= 0 then
				finishPrimed(targetCharacter, state, false)
			else
				setAttributes(targetCharacter, state)
			end

			return true
		end
	end

	applyPush(targetCharacter, state, hit)
	state.LastAttacker = attacker

	if not state.Primed then
		state.Impact = math.min(Config.MaxImpact, state.Impact + hit.Power)
		if state.Impact >= Config.MaxImpact and now >= state.ProtectedUntil then
			enterPrimed(targetCharacter, state, now)
		else
			setAttributes(targetCharacter, state)
		end
	end

	return true
end

function ImpactService.GetLastAttacker(targetCharacter: Model): Player?
	local state = states[targetCharacter]
	if not state or time() - state.LastHitAt > Config.AttributionTime then
		return nil
	end

	local attacker = state and state.LastAttacker
	return if attacker and attacker.Parent == Players then attacker else nil
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(newState)
	if player.Character then
		newState(player.Character)
	end
end

function ImpactService:Init()
	if initialized then return end
	initialized = true

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	RunService.Heartbeat:Connect(function(dt)
		local now = time()

		for character, state in pairs(states) do
			if not character.Parent then
				states[character] = nil
				continue
			end

			if state.Primed and now >= state.PrimedUntil then
				finishPrimed(character, state, true)
				continue
			end

			local shouldSync = character:GetAttribute("ImpactProtected") == true and now >= state.ProtectedUntil

			if not state.Primed
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
end

return ImpactService
