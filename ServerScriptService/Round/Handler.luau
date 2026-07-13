-- RoundSystem.lua (server)
local ReplicatedStorage       = game:GetService("ReplicatedStorage")
local SS       = game:GetService("ServerStorage")
local Players  = game:GetService("Players")
local Teams    = game:GetService("Teams")

local Bindables	= SS.Bindables
local Packages = ReplicatedStorage.Packages

local Promise  = require(Packages.Promise)
local Trove    = require(Packages.Trove)

local LoadMap  = require(script.Parent:WaitForChild("LoadMap"))
local Deploy   = require(script.Parent:WaitForChild("DeploySystem"))
local DamageHandler = require(script.Parent.Parent.Weapon.Modules.DamageHandler)

local Replica = require(SS.Libraries.ReplicaServer) 
local RoundWriteLib = Packages.Replica.RoundStateWrite

local module = {
	CurrentGamemodeId = nil,
	CurrentGamemode = nil,
}

local Config = {
	DISABLED = true,
	ENABLE_MAP = false,
	MIN_PLAYERS = 1,
	GAMEMODES = { "KOTH" },
	LOAD_TIME = 3,
	COUNTDOWN_TIME = 2,
	DISPLAY_WINNER_TIME = 10,
}

local function teamId(team: Team?): string?
	if not team then return nil end
	return string.upper(team.Name)
end

local function initScoresFromTeams()
	local scores = {}
	for _, t in ipairs(Teams:GetChildren()) do
		if t:IsA("Team") then
			scores[string.upper(t.Name)] = 0
		end
	end
	return scores
end

local function initLeaderboards()
	local leaderboard = {}
	for _, t in pairs(Teams:GetChildren()) do
		if t:IsA("Team") then
			leaderboard[string.upper(t.Name)] = {}
		end
	end
		
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Team and leaderboard[string.upper(plr.Team.Name)] then
			table.insert(leaderboard[string.upper(plr.Team.Name)], { pId = tostring(plr.UserId), kills = 0, deaths = 0, assists = 0 })
		end
	end
		
	return leaderboard
end

local RoundToken = Replica.Token("RoundState")

local roundReplica
local function initRoundReplica()
	local initial = {
		revision = 0,
		active = false,
		phase = "Idle",
		gamemode = nil,
		endsAt = nil,
		movement = false,
		enabledPlrs = false,
		scores = initScoresFromTeams(),
		winner = nil,
		leaderboard = initLeaderboards(),
	}

	roundReplica = Replica.New({
		Token = RoundToken,
		Data = initial,
		WriteLib = RoundWriteLib,
	})

	roundReplica:Replicate()
end

-- Load gamemode classes
local Gamemodes = {}
for _, m in ipairs(script.Parent:WaitForChild("Gamemodes"):GetChildren()) do
	Gamemodes[m.Name] = require(m)
end

local function enoughPlayers()
	return #Players:GetPlayers() >= Config.MIN_PLAYERS
end

local function pick(list)
	return list[math.random(1, #list)]
end

local function enoughPlayersPromise()
	if enoughPlayers() then return Promise.resolve() end
	return Promise.fromEvent(Players.PlayerAdded, function()
		return enoughPlayers() and true or nil
	end):andThenReturn()
end

local function notEnoughPlayersPromise()
	if not enoughPlayers() then return Promise.resolve() end
	return Promise.fromEvent(Players.PlayerRemoving, function()
		local remaining = #Players:GetPlayers() - 1
		return remaining < Config.MIN_PLAYERS and true or nil
	end):andThenReturn()
end

local function loadRandomMap()
	if not Config.ENABLE_MAP then
		return workspace:FindFirstChild("Map")
	end

	local maps = SS:WaitForChild("Maps"):GetChildren()
	if #maps == 0 then return nil end

	local chosen = pick(maps)
	LoadMap(chosen.Name, false, false)
	return workspace:WaitForChild("Map")
end

local function makeCtx(mapRoot)
	return {
		Players = Players,
		Map = mapRoot,
		Config = Config,
		TeamId = teamId,

		SetScore = function(teamOrId, pts: number)
			local id
			if typeof(teamOrId) == "Instance" then
				id = teamId(teamOrId)
			else
				id = string.upper(tostring(teamOrId))
			end
			if not id then return end
			roundReplica:Write("SetScore", id, pts)
		end,
	}
end

function module:Init()
	Deploy:Init()
	DamageHandler.SetScoringEnabled(false)

	initRoundReplica()

	if Config.DISABLED then
		Deploy.GetSpawns()
		Deploy.EnableDeploy()
		roundReplica:Write("Apply", { movement = true, enabledPlrs = true })
		return
	end

	while true do
		module.WaitForPlayers():await()
		module.Intermission():await()
		module.StartRound():await()
		task.wait()
	end
end

function module.WaitForPlayers()
	return enoughPlayersPromise()
end

function module.Intermission()
	if not enoughPlayers() then return Promise.resolve() end

	Deploy.DisableDeploy()
	DamageHandler.SetScoringEnabled(false)
	Deploy.ClearDeployedPlayers()

	roundReplica:Write("Apply", {
		active = false,
		phase = "Idle",
		gamemode = nil,
		enabledPlrs = false,
		movement = false,
		endsAt = nil,
		scores = initScoresFromTeams(),
		winner = nil,
	})

	return Promise.delay(Config.LOAD_TIME)
end

function module.SelectGamemodeId()
	module.CurrentGamemodeId = pick(Config.GAMEMODES)
	return module.CurrentGamemodeId
end

function module.StartRound(modeId: string?)
	if not enoughPlayers() then
		return Promise.resolve()
	end

	modeId = modeId or module.SelectGamemodeId()
	local gmClass = Gamemodes[modeId]
	if not gmClass or type(gmClass.new) ~= "function" then
		warn(("[Round] Invalid gamemode '%s'"):format(tostring(modeId)))
		return Promise.resolve()
	end

	local roundTrove = Trove.new()

	local mapRoot = loadRandomMap()
	if not mapRoot then
		warn("[Round] No map loaded")
		roundTrove:Destroy()
		return Promise.resolve()
	end

	local ctx = makeCtx(mapRoot)

	local gm = gmClass.new(ctx)
	module.CurrentGamemode = gm
	roundTrove:Add(gm)

	Deploy.AssignAllPlayers()
	roundTrove:Connect(Players.PlayerAdded, Deploy.AssignPlayer)

	Deploy.GetSpawns()
	Deploy.ClearDeployedPlayers()
	Deploy.EnableDeploy()
	
	roundReplica:Write("Apply", {
		active = true,
		phase = "Countdown",
		gamemode = {
			id = gm.ID,
			name = gm.NAME,
			winPts = gm.WIN_PTS,
			roundTime = gm.ROUND_TIME,
		},
		endsAt = workspace:GetServerTimeNow() + Config.COUNTDOWN_TIME,
		scores = initScoresFromTeams(),
		leaderboard = initLeaderboards(),
		winner = nil,
	})
		
	roundTrove:Connect(Bindables.PlayerKilled.Event, function(plrKilled : Player, Killer : Player)
		if plrKilled.Team then
			roundReplica:Write("IncrementLeaderboardEntry", plrKilled.UserId, plrKilled.Team.Name, "deaths")
		end

		if plrKilled ~= Killer and Killer and Killer.Team then
			roundReplica:Write("IncrementLeaderboardEntry", Killer.UserId, Killer.Team.Name, "kills")
		end
	end)

	roundTrove:Connect(Bindables.Assist.Event, function(plrKilled : Player, Assists : {Player})
		for _, plr in ipairs(Assists) do
			if plr.Team then
				roundReplica:Write("IncrementLeaderboardEntry", plr.UserId, plr.Team.Name, "assists")
			end
		end
	end)

	roundTrove:Connect(Players.PlayerAdded, function(plr :Player)
		if plr.Team then
			roundReplica:Write("InsertLeaderboardEntry", plr.UserId, plr.Team.Name)
		end
	end)

	return Promise.delay(Config.COUNTDOWN_TIME)
		:andThen(function()
			DamageHandler.SetScoringEnabled(true)
			roundReplica:Write("Apply", {
				active = true,
				phase = "Round",
				enabledPlrs = true,
				movement = true,
				endsAt = workspace:GetServerTimeNow() + gm.ROUND_TIME,
			})

			return Promise.race({
				Promise.try(function() return gm:Start() end),
				notEnoughPlayersPromise():andThenReturn(nil),
			})
		end)
		:andThen(function(winnerTeam: Team?)
			Deploy.DisableDeploy()
			DamageHandler.SetScoringEnabled(false)

			roundReplica:Write("Apply", {
				active = true,
				phase = "Ended",
				endsAt = nil,
				enabledPlrs = false,
				winner = winnerTeam and teamId(winnerTeam) or nil,
			})

			if type(gm.End) == "function" then
				return Promise.try(function()
					return gm:End(winnerTeam)
				end)
			end

			return Promise.delay(Config.DISPLAY_WINNER_TIME)
		end)
		:catch(function(err)
			DamageHandler.SetScoringEnabled(false)
			warn(("[Round] StartRound error (%s): %s"):format(tostring(modeId), tostring(err)))
		end)
		:finally(function()
			DamageHandler.SetScoringEnabled(false)
			module.CurrentGamemode = nil

			roundReplica:Write("Apply", {
				active = false,
				phase = "Idle",
				gamemode = nil,
				endsAt = nil,
				movement = false,
				enabledPlrs = false,
				scores = initScoresFromTeams(),
				winner = nil,
			})

			Deploy.ResetAllPlayers()
			roundTrove:Destroy()
		end)
end

return module
