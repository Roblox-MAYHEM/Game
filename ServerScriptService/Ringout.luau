local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageHandler = require(ServerScriptService.Weapon.Modules.DamageHandler)
local ImpactService = require(ServerScriptService.Weapon.Modules.ImpactService)

local Ringout = {}
local boundZones: { [BasePart]: boolean } = {}
local resolvingCharacters: { [Model]: boolean } = {}

local function getPlayerCharacter(part: BasePart): (Model?, Humanoid?, Player?)
	local character = part:FindFirstAncestorWhichIsA("Model")
	if not character then return nil, nil, nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	if not humanoid or not player then return nil, nil, nil end

	return character, humanoid, player
end

local function ringOut(part: BasePart)
	local character, humanoid, victim = getPlayerCharacter(part)
	if not character or not humanoid or not victim then return end
	if resolvingCharacters[character] or character:GetAttribute("Dead") == true or humanoid.Health <= 0 then return end

	resolvingCharacters[character] = true
	character.Destroying:Once(function()
		resolvingCharacters[character] = nil
	end)

	local attacker = ImpactService.GetLastAttacker(character) or victim
	DamageHandler.KillHumanoid(humanoid, attacker, true)
end

local function bindZone(instance: Instance)
	if not instance:IsA("BasePart") or boundZones[instance] then return end
	boundZones[instance] = true

	instance.Touched:Connect(ringOut)
	instance.Destroying:Once(function()
		boundZones[instance] = nil
	end)
end

function Ringout:Init()
	for _, instance in ipairs(CollectionService:GetTagged("RingoutZone")) do
		bindZone(instance)
	end

	CollectionService:GetInstanceAddedSignal("RingoutZone"):Connect(bindZone)
end

return Ringout
