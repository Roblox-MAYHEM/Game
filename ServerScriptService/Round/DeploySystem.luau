local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams 	= game:GetService("Teams")
local Players 	= game:GetService("Players")

local Events	= ReplicatedStorage.Events
local DamageHandler = require(script.Parent.Parent.Weapon.Modules.DamageHandler)

local canDeploy = false

local module = {}
local SpawnLocations = {} --{Team : {CFrame}}
local DeployedPlayers = {} :: {[Player]: boolean}

local function getTeamCounts()
	local counts = {}
	for _, team in ipairs(Teams:GetTeams()) do
		counts[team] = 0
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Team and counts[plr.Team] ~= nil then
			counts[plr.Team] += 1
		end
	end

	return counts
end

local function chooseSpawn(tm : Team)
	local teamName = tm and tm.Name or "Neutral"

	local spawns = SpawnLocations[teamName]
	if not spawns or #spawns == 0 then
		warn("No spawn available for team", tm)
		return
	end

	return SpawnLocations[teamName][math.random(#SpawnLocations[teamName])]
end

function module.GetSpawns()
	local CurrentMap = workspace:FindFirstChild("Map")
	if not CurrentMap then
		warn("No current map found")
		return
	end

	table.clear(SpawnLocations)

	local Spawns = CurrentMap:FindFirstChild("Spawns")
	
	if Spawns then
		for _, v in ipairs(Spawns:GetChildren()) do
			SpawnLocations[v.Name] = {}
			for _, spn in ipairs(v:GetChildren()) do
				table.insert(SpawnLocations[v.Name], spn.CFrame + Vector3.new(0,5,0))
			end
		end
	else
		warn("No spawn found in map")
	end
end

function module.EnableDeploy()
	canDeploy = true
end

function module.DisableDeploy()
	canDeploy = false
end

function module.ClearDeployedPlayers()
	table.clear(DeployedPlayers)

	for _, plr in ipairs(Players:GetPlayers()) do
		plr:SetAttribute("Deployed", false)
		if plr.Character then
			plr.Character:SetAttribute("Deployed", false)
		end
	end
end

function module:Init()
	Events.DeployRequest.OnServerInvoke = module.DeployPlayer

	Players.PlayerRemoving:Connect(function(plr)
		DeployedPlayers[plr] = nil
	end)
end

function module.AssignPlayer(plr : Player)
	local counts = getTeamCounts()
	local teams = Teams:GetTeams()
	if #teams == 0 then
		warn("[Deploy] No teams available for assignment")
		return
	end

	table.sort(teams, function(a, b)
		return counts[a] < counts[b]
	end)

	plr.Team = teams[1]
end

function module.AssignAllPlayers()
	local teams = Teams:GetTeams()
	local players = Players:GetPlayers()
	if #teams == 0 then
		warn("[Deploy] No teams available for assignment")
		return
	end

	-- Shuffle players to avoid bias
	for i = #players, 2, -1 do
		local j = math.random(i)
		players[i], players[j] = players[j], players[i]
	end

	-- Assign round-robin
	for i, plr in ipairs(players) do
		plr.Team = teams[((i - 1) % #teams) + 1]
	end
end

function module.ResetAllPlayers()
	module.ClearDeployedPlayers()

	for _, plr : Player in pairs(Players:GetPlayers()) do
		if plr.Character then
			local character = plr.Character
			plr:SetAttribute("Deployed", false)
			character:SetAttribute("Deployed", false)
			DamageHandler.ClearCharacter(character)

			character:Destroy()
			Events.EnableMenu:FireClient(plr)
		end
	end
end

function module.DeployAllPlayers()
	warn("DeployAllPlayers is disabled; players must deploy manually.")
end

function module.DeployPlayer(plr : Player)
	if not canDeploy then return false end

	if DeployedPlayers[plr] and plr.Character and plr.Character.Parent then
		return true
	end

	local spawnCFrame = chooseSpawn(plr.Team)
	if not spawnCFrame then return false end

	DeployedPlayers[plr] = true
	plr:SetAttribute("Deployed", true)

	local loaded, err = pcall(function()
		plr:LoadCharacterAsync()
	end)

	if not loaded then
		DeployedPlayers[plr] = nil
		plr:SetAttribute("Deployed", false)
		warn(("[Deploy] LoadCharacterAsync failed for %s: %s"):format(plr.Name, tostring(err)))
		return false
	end

	local character = plr.Character
	if not character then
		DeployedPlayers[plr] = nil
		plr:SetAttribute("Deployed", false)
		return false
	end

	character:SetAttribute("Deployed", true)

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		DeployedPlayers[plr] = nil
		plr:SetAttribute("Deployed", false)
		character:SetAttribute("Deployed", false)
		warn(("[Deploy] HumanoidRootPart missing for %s; deploy aborted."):format(plr.Name))
		return false
	end

	hrp.CFrame = spawnCFrame

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Once(function()
			DeployedPlayers[plr] = nil
			plr:SetAttribute("Deployed", false)
			character:SetAttribute("Deployed", false)
		end)
	end

	return true
end

return module
