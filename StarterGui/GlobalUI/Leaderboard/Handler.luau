local CAS = game:GetService("ContextActionService")
local Client			= game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local UI = Player:WaitForChild("PlayerGui")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children = Fusion.Children
local scoped, peek = Fusion.scoped, Fusion.peek

local GlobalUI = UI:WaitForChild("GlobalUI") :: ScreenGui
local Leaderboard = GlobalUI:WaitForChild("LeaderboardFrame") :: Frame
local TeamTemplate = Leaderboard:WaitForChild("Teams"):WaitForChild("Template") :: Frame

local PlayerEntry = require(script.Parent.PlayerEntry)

local OPEN_SIZE = UDim2.new(0.8, 0, 0.8, 0)
local CLOSED_SIZE = UDim2.new(0.5, 0, 0, 0)

-- per-player reactive state + instance ref
type EntryData = {
	Kills: Fusion.Value<number>,
	Deaths: Fusion.Value<number>,
	Assists: Fusion.Value<number>,
	instance: GuiObject,
	scope: Fusion.Scope<any>,
}

local scope = scoped(Fusion)
local visible = scope:Value(false)
local goalSize = scope:Value(CLOSED_SIZE)
local size = scope:Spring(goalSize, 50, 0.9)
local gamemode = scope:Value("")

local entries: { [number]: EntryData } = {}
local teamContainers: { [string]: Frame } = {} -- team name → player list frame

scope:Hydrate(Leaderboard) {
	Visible = visible,
	Size = size,

	[scope.Children] = {scope:Hydrate(Leaderboard.Title) {Text = gamemode}}
}

-- team objects cloned from template; returns the inner container for players
local function createTeamFrame(team: Team): Frame
	local frame = TeamTemplate:Clone()
	frame.Name = team.Name
	frame.Visible = true
	frame.Parent = TeamTemplate.Parent
	frame.Heading.BackgroundColor3 = team.TeamColor.Color
	return frame
end

local function createEntry(plr: Player)
	local team = plr.Team

	if entries[plr.UserId] then return end

	local container = team and teamContainers[team.Name]
	if not container then return end

	local entryScope = scope:innerScope()
	local kills = entryScope:Value(0)
	local deaths = entryScope:Value(0)
	local assists = entryScope:Value(0)

	local inst = PlayerEntry(entryScope, {
		Player = plr,
		Kills = kills,
		Assists = assists,
		Deaths = deaths,
		Parent = container,
	})

	entries[plr.UserId] = { Kills = kills, Deaths = deaths, Assists = assists, instance = inst, scope = entryScope}
end

local function RefreshTeam(roundReplica, teamId: string)
	teamId = string.upper(teamId)

	local teamTable = roundReplica.Data.leaderboard[teamId]
	if type(teamTable) ~= "table" then return end

	for idx, entry in ipairs(teamTable) do
		local userId = tonumber(entry.pId)
		if userId then
			local plr = Players:GetPlayerByUserId(userId)
			if plr and not entries[userId] then
				createEntry(plr)
			end

			local data = entries[userId]
			if data then
				data.Kills:set(entry.kills or 0)
				data.Deaths:set(entry.deaths or 0)
				data.Assists:set(entry.assists or 0)

				data.instance.LayoutOrder = idx
			end
		end
	end
end

local function RefreshAllTeams(roundReplica)
	for teamId in pairs(teamContainers) do
		RefreshTeam(roundReplica, teamId)
	end
end

local function removeEntry(plr: Player)
	local data = entries[plr.UserId]
	if not data then return end
	data.scope:doCleanup()
	entries[plr.UserId] = nil
end

local function setOpen(open: boolean)
	goalSize:set(open and OPEN_SIZE or CLOSED_SIZE)
	visible:set(open)
end

local module = {}

function module:Init(props)
	local roundReplica = props.RoundReplica
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	
	if roundReplica.Data.gamemode then
		gamemode:set(roundReplica.Data.gamemode.name)
	end

	TeamTemplate.Visible = false

	for _, team in Teams:GetTeams() do
		teamContainers[team.Name] = createTeamFrame(team)
	end
	for _, plr in Players:GetPlayers() do createEntry(plr, plr.Team) end

	props.trove:Connect(Players.PlayerAdded, createEntry)
	props.trove:Connect(Players.PlayerRemoving, removeEntry)
	
	local function HookLeaderboardWrite(name)
		props.trove:Add(roundReplica:OnWrite(name, function(pId: number, teamId: string)
			RefreshTeam(roundReplica, teamId)
		end))
	end

	HookLeaderboardWrite("IncrementLeaderboardEntry")
	HookLeaderboardWrite("InsertLeaderboardEntry")
	HookLeaderboardWrite("RemoveLeaderboardEntry")

	RefreshAllTeams(roundReplica)
	props.trove:Add(roundReplica:OnChange(function()
		gamemode:set(roundReplica.Data.gamemode and roundReplica.Data.gamemode.name or "")
		RefreshAllTeams(roundReplica)
	end))

	CAS:BindAction("ToggleLeaderboard", function(_, state)
		if state == Enum.UserInputState.Begin then setOpen(true)
		elseif state == Enum.UserInputState.End then setOpen(false) end
	end, false, Enum.KeyCode.Tab)

	props.trove:Add(function() CAS:UnbindAction("ToggleLeaderboard") end)
end

return module
