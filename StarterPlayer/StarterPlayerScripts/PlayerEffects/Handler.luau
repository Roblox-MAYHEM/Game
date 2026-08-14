-- PlayerEffects.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local Client            = game:GetService("StarterPlayer")
local Debris = game:GetService("Debris")

local Events       = ReplicatedStorage.Events
local Components = Client.Components
local Fusion = require(Client.Packages.Fusion)
local HitMarker    = require(Components.HitMarker)
local HitHighlight = require(Components.HitHighlight)

-- Load named effect modules from children (e.g. ExplosionEffect, MuzzleFlash)
local function loadEffectModules(parent: Instance): { [string]: { Play: (...any) -> () } }
	local t = {}
	for _, child in ipairs(parent:GetChildren()) do
		local module = if child:IsA("ModuleScript") then child elseif child:IsA("Folder") then child:FindFirstChild("init") else nil
		if module and module:IsA("ModuleScript") then
			t[child.Name] = require(module)
		end
	end
	return t
end

local NO_SOUND_BELOW_DAMAGE = 5
local DAMAGE_FOR_MAX_EFFECT = 100

local function inverseLerp(minValue: number, maxValue: number, value: number): number
	return math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
end

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local effectModules = loadEffectModules(script.Parent:WaitForChild("Effects"))

local module = {}

function module:Init(properties)
	local trove  = properties.Trove:Extend()
	local scope = Fusion.scoped(Fusion)
	trove:Add(function() scope:doCleanup() end)

	local HitSound = SoundService.Effects.Hit
	local BigHitSound = SoundService.Effects.BigHit

	trove:Connect(Events.PlayerHit.OnClientEvent, function(amount: number, humanoid: Humanoid)
		if amount >= NO_SOUND_BELOW_DAMAGE then
			local alpha = inverseLerp(NO_SOUND_BELOW_DAMAGE, DAMAGE_FOR_MAX_EFFECT, amount)

			if amount >= 60 then
				local heavyAlpha = inverseLerp(35, DAMAGE_FOR_MAX_EFFECT, amount)

				local thud = BigHitSound:Clone()
				thud.Volume = lerpNumber(0.1, 0.55, heavyAlpha)

				thud.PlaybackSpeed = 1

				thud.Parent = SoundService
				thud:Play()

				Debris:AddItem(thud, math.max(thud.TimeLength, 1) + 0.25)
			end

			local sound = HitSound:Clone()
			sound.Volume = lerpNumber(0.25, 0.85, alpha)

			-- Very slight pitch variation for normal hit sound.
			-- Range: 0.98x to 1.02x
			local randomVariation = math.random(-2, 2) / 100
			sound.PlaybackSpeed = 1 + randomVariation

			sound.Parent = SoundService
			sound:Play()

			Debris:AddItem(sound, math.max(sound.TimeLength / sound.PlaybackSpeed, 1) + 0.25)
		end

		HitMarker(scope, { Amount = amount, Humanoid = humanoid })
		HitHighlight(scope, { Character = humanoid.Parent })
	end)

	trove:Connect(Events.PlayerDamaged.OnClientEvent, function(amount: number, sourcePos: Vector3)
		-- TODO: damaged effect
	end)

	trove:Connect(Events.ReplicateEffect.OnClientEvent, function(effect: string, ...)
		module.PlayEffect(effect, ...)  -- play locally without re-firing server
	end)
end

-- Call this from weapons to play an effect locally + replicate to other clients
function module.PlayEffect(effect: string, ...)
	local m = effectModules[effect] 
	if m then task.spawn(m.Play, ...) end
end

function module.ReplicateEffect(effect: string, ...)
	module.PlayEffect(effect, ...)
	Events.ReplicateEffect:FireServer(effect, ...)
end

return module
