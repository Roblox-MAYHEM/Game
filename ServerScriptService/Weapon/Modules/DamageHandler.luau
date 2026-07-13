local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage.Events
local Bindables = ServerStorage.Bindables

local LevelSystem = require(ServerStorage.Libraries.LevelSystem)
local ImpactService = require(script.Parent.ImpactService)

local Config = {
	LAST_HIT_MULTIPLIER = 1.5,
	HIT_BUFFER_TIME = 0.1,
	ASSIST_BOUND = 40,
	DEAD_ATTRIBUTE = "Dead",
}

local DamageTable = {} -- { [VictimPlayer] = { [AttackerPlayer] = Damage } }
local HitBuffer = {} -- { [AttackerPlayer] = { [Humanoid] = { damage = number, deadline = number } } }

local Damager = {}
local scoringEnabled = false

local function bufferHit(attacker: Player, humanoid: Humanoid, amount: number)
	HitBuffer[attacker] = HitBuffer[attacker] or {}

	local attackerBuffer = HitBuffer[attacker]
	local hitInfo = attackerBuffer[humanoid]

	if not hitInfo then
		hitInfo = { damage = 0, deadline = 0 }
		attackerBuffer[humanoid] = hitInfo
	end

	hitInfo.damage += amount
	hitInfo.deadline = time() + Config.HIT_BUFFER_TIME

	local scheduledDeadline = hitInfo.deadline

	task.delay(Config.HIT_BUFFER_TIME, function()
		local currentBuffer = HitBuffer[attacker]
		if not currentBuffer then return end

		local currentInfo = currentBuffer[humanoid]
		if not currentInfo then return end
		if currentInfo.deadline ~= scheduledDeadline then return end
		if time() < currentInfo.deadline then return end

		Remotes.PlayerHit:FireClient(attacker, currentInfo.damage, humanoid)

		currentBuffer[humanoid] = nil
		if next(currentBuffer) == nil then HitBuffer[attacker] = nil end
	end)
end

local function publishDeath(victim: Player, lastHit: Player?, forcedKiller: Player?)
	local damageMap = DamageTable[victim] or {}

	local killer = forcedKiller or victim

	if not forcedKiller then
		local bestDamage = -math.huge
		for attacker, damage in pairs(damageMap) do
			local score = damage
			if attacker == lastHit then score *= Config.LAST_HIT_MULTIPLIER end

			if score > bestDamage then
				bestDamage = score
				killer = attacker
			end
		end
	end

	local assists = {}

	for attacker, damage in pairs(damageMap) do
		if attacker ~= victim and attacker ~= killer and damage > Config.ASSIST_BOUND then
			table.insert(assists, attacker)
		end
	end

	Remotes.PlayerKill:FireAllClients(killer, victim)

	if not scoringEnabled then
		DamageTable[victim] = {}
		return
	end

	Bindables.PlayerKilled:Fire(victim, killer)
	if killer ~= victim then
		local success, err = pcall(function()
			LevelSystem.AwardKill(killer, victim)
		end)

		if not success then warn("AwardKill failed:", err) end
	end

	if #assists > 0 then
		Bindables.Assist:Fire(victim, assists)

		for _, assistant in ipairs(assists) do
			local success, err = pcall(function()
				LevelSystem.AwardAssist(assistant, victim)
			end)

			if not success then warn("AwardAssist failed:", err) end
		end
	end

	DamageTable[victim] = {}
end

function Damager.HealHumanoid(humanoid: Humanoid, sender: Player, amount: number)
	if not humanoid or not humanoid.Parent then return end
	if amount <= 0 then return end
	if humanoid.Parent:GetAttribute(Config.DEAD_ATTRIBUTE) then return end

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
end

function Damager.DamageHumanoid(humanoid: Humanoid, attacker: Player, amount: number, friendlyFire: boolean?, forcedKiller: Player?)
	if not humanoid or not humanoid.Parent then return end
	if not attacker or amount <= 0 then return end

	local character = humanoid.Parent
	if character:GetAttribute(Config.DEAD_ATTRIBUTE) then return end

	local victim = Players:GetPlayerFromCharacter(character)

	if victim and not friendlyFire and victim.Team and attacker.Team and victim.Team == attacker.Team then
		return
	end

	local oldHealth = humanoid.Health
	if oldHealth <= 0 then return end

	local appliedDamage = math.min(amount, oldHealth)

	if victim then
		DamageTable[victim] = DamageTable[victim] or {}
		DamageTable[victim][attacker] = (DamageTable[victim][attacker] or 0) + appliedDamage

		local attackerCharacter = attacker.Character
		local attackerRoot = attackerCharacter and attackerCharacter:FindFirstChild("HumanoidRootPart")

		if attackerRoot and attackerRoot:IsA("BasePart") then
			Remotes.PlayerDamaged:FireClient(victim, appliedDamage, attackerRoot.Position)
		end
	end

	if character.Parent and not character:FindFirstChild("ForceField") then
		bufferHit(attacker, humanoid, appliedDamage)
	end

	if oldHealth - appliedDamage <= 0 then
		character:SetAttribute(Config.DEAD_ATTRIBUTE, true)
		ImpactService.Clear(character)
		humanoid.Health = 0
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		end)

		if victim then
			publishDeath(victim, attacker, forcedKiller)
		end
		return
	end

	humanoid:TakeDamage(appliedDamage)
end

function Damager.KillHumanoid(humanoid: Humanoid, attacker: Player, friendlyFire: boolean?, forcedKiller: Player?)
	if not humanoid or not humanoid.Parent then return end
	Damager.DamageHumanoid(humanoid, attacker, humanoid.Health, friendlyFire, forcedKiller)
end

function Damager.SetScoringEnabled(enabled: boolean)
	scoringEnabled = enabled == true
end

function Damager.ClearCharacter(character: Model)
	if not character then return end
	ImpactService.Clear(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		for attacker, buffer in pairs(HitBuffer) do
			buffer[humanoid] = nil
			if next(buffer) == nil then HitBuffer[attacker] = nil end
		end
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		DamageTable[player] = {}
	end
end

local function setupPlayer(player: Player)
	DamageTable[player] = {}

	player.CharacterAdded:Connect(function(character)
		ImpactService.Clear(character)
		character:SetAttribute(Config.DEAD_ATTRIBUTE, false)
	end)

	if player.Character then
		ImpactService.Clear(player.Character)
		player.Character:SetAttribute(Config.DEAD_ATTRIBUTE, false)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	if player.Character then Damager.ClearCharacter(player.Character) end
	for _, damageMap in pairs(DamageTable) do damageMap[player] = nil end
	DamageTable[player] = nil
	HitBuffer[player] = nil
end)

Remotes.ResetCharacter.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	if character:GetAttribute(Config.DEAD_ATTRIBUTE) == true then return end
	if player:GetAttribute("Deployed") ~= true and character:GetAttribute("Deployed") ~= true then
		Damager.ClearCharacter(character)
		Remotes.EnableMenu:FireClient(player)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	Damager.KillHumanoid(humanoid, player, true, player)
end)

return Damager
