-- PlayerEffects.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local Client            = game:GetService("StarterPlayer")
local Debris = game:GetService("Debris")
local Player			= game:GetService("Players").LocalPlayer

local Events       = ReplicatedStorage.Events
local Components = Client.Components
local Fusion = require(Client.Packages.Fusion)
local HitMarker    = require(Components.HitMarker)
local HitHighlight = require(Components.HitHighlight)

-- Load named effect modules from children (e.g. ExplosionEffect, MuzzleFlash)
local function loadEffectModules(parent: Instance): { [string]: { Play: (...any) -> () } }
	local t = {}
	for _, v in ipairs(parent:GetChildren()) do
		if v:IsA("ModuleScript") then
			t[v.Name] = require(v)
		end
	end
	return t
end

local function projectOnPlane(vec, normal)
	return vec - vec:Dot(normal.Unit) * normal.Unit
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
	
	local SpeedLines = Client.Assets:WaitForChild("SpeedLines")
	SpeedLines = trove:Clone(SpeedLines)

	local Camera = workspace.CurrentCamera
	local ViewportSize = Camera.ViewportSize
	local AspectRatio = ViewportSize.X/ViewportSize.Y

	local Humanoid = Player.Character:WaitForChild("Humanoid") :: Humanoid

	SpeedLines.Parent = Camera
	
	local MIN_SPEED = 20
	local OFFSET = 10
	local root = Player.Character:WaitForChild("HumanoidRootPart")
	
	trove:Connect(RunService.RenderStepped, function()
		SpeedLines.CFrame = Camera.CFrame + Camera.CFrame.LookVector * (OFFSET / Camera.FieldOfView * 70)

		local velocity = root.AssemblyLinearVelocity
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

		local enabled = speed >= MIN_SPEED
		SpeedLines.Attachment.ParticleEmitter.Enabled = enabled

		Camera.FieldOfView = 70 + math.clamp(speed / 2, 0, 20)
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