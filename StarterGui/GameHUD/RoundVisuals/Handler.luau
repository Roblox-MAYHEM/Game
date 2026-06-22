local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local UI = Player:WaitForChild("PlayerGui")

local Fusion = require(Client.Packages.Fusion)
local scoped, peek, doCleanup = Fusion.scoped, Fusion.peek, Fusion.doCleanup

local HUD       = UI:WaitForChild("GameHUD") :: ScreenGui
local TopBar    = HUD:WaitForChild("TopBar") :: Frame
local PBar      = TopBar:WaitForChild("ProgressBar") :: Frame
local Countdown = HUD:WaitForChild("Countdown") :: Frame
local WinCard   = HUD:WaitForChild("WinCard") :: Frame
local PostBoard = HUD:WaitForChild("PostMatchBoard") :: Frame

local PlayerSlot = require(script.Parent.PlayerCard)

local module = {}
local scope = scoped(Fusion)

local isLoaded       = scope:Value(false)
local phase          = scope:Value("Idle")
local endsAt         = scope:Value(0)
local gmName         = scope:Value("")
local winPts         = scope:Value(10)
local winnerTeam     = scope:Value("")
local serverNow      = scope:Value(workspace:GetServerTimeNow())
local redPts         = scope:Value(0)
local bluPts         = scope:Value(0)
local ownPlace		 = scope:Value(0)
local isWinCard      = scope:Value(false)
local isPostBoard    = scope:Value(false)

local timeLeft = scope:Computed(function(use)
	return math.max(math.ceil(use(endsAt) - use(serverNow)), 0)
end)

local function fillSize(pts)
	return scope:Spring(scope:Computed(function(use)
		return UDim2.new(use(pts) / math.max(use(winPts), 1), 0, 1, 0)
	end), 25, 1)
end

-- Hydrations (flat — no re-parenting wrappers needed for existing instances)

scope:Hydrate(TopBar)    { Visible = isLoaded }
scope:Hydrate(Countdown) { Visible = scope:Computed(function(use) return use(phase) == "Countdown" and use(timeLeft) > 0 end) }
scope:Hydrate(WinCard)   { Visible = isWinCard }
scope:Hydrate(PostBoard) { Visible = isPostBoard }

scope:Hydrate(Countdown:WaitForChild("Text")) {
	Text = scope:Computed(function(use) return tostring(use(timeLeft)) end)
}

scope:Hydrate(PostBoard:WaitForChild("Text")) {
	Text = scope:Computed(function(use) return "You placed: " .. tostring(use(ownPlace)) .. "!" end)
}

scope:Hydrate(TopBar:WaitForChild("Gamemode"):WaitForChild("Text")) { Text = gmName }

scope:Hydrate(TopBar:WaitForChild("Timer"):WaitForChild("Text")) {
	Text = scope:Computed(function(use)
		if use(phase) ~= "Round" then return "00:00" end
		local t = use(timeLeft)
		return string.format("%02d:%02d", math.floor(t / 60), t % 60)
	end)
}

scope:Hydrate(WinCard:WaitForChild("Result")) {
	Text = scope:Computed(function(use)
		local team = Player.Team
		return team and use(winnerTeam) == team.Name and "VICTORY" or "DEFEAT"
	end)
}

scope:Hydrate(PBar:WaitForChild("RED"):WaitForChild("Fill")) { Size = fillSize(redPts) }
scope:Hydrate(PBar:WaitForChild("BLU"):WaitForChild("Fill")) { Size = fillSize(bluPts) }

scope:Hydrate(PBar:WaitForChild("RED"):WaitForChild("Fill"):WaitForChild("Text")) {
	Text = scope:Computed(function(use) return tostring(use(redPts)) end)
}
scope:Hydrate(PBar:WaitForChild("BLU"):WaitForChild("Fill"):WaitForChild("Text")) {
	Text = scope:Computed(function(use) return tostring(use(bluPts)) end)
}

local function addPlayerCard(player, kills, place)
	return PlayerSlot(scope:innerScope(), {
		Parent      = PostBoard:WaitForChild("PlayerCards"),
		LayoutOrder = place,
		Kills       = kills,
		Place		= place,
		Player      = player,
	})
end

local function showPostMatchBoard(s)
	isWinCard:set(false)
	isPostBoard:set(true)

	local cards = {}
	for _, teamData in pairs(s.leaderboard or {}) do
		for _, entry in pairs(teamData) do
			table.insert(cards, { pId = entry.pId, kills = entry.kills or 0 })
		end
	end
	table.sort(cards, function(a, b) return a.kills > b.kills end)
	
	for i, card in ipairs(cards) do
		if card.pId == tostring(Player.UserId) then ownPlace:set(i) end
	end

	local activeCards = {}
	for i = 1, math.min(#cards, 3) do
		local c = cards[i]
		table.insert(activeCards, addPlayerCard(Players:GetPlayerByUserId(tonumber(c.pId)), c.kills, i))
	end

	task.wait(3)
	isPostBoard:set(false)
	for _, v in activeCards do
		v:Destroy()
	end
end

local function applyFromReplica(s)
	if s.phase == "Ended" and s.phase ~= peek(phase) then
		isWinCard:set(true)
		task.delay(3, showPostMatchBoard, s)
	end

	phase:set(s.phase or "Idle")
	gmName:set(s.gamemode and s.gamemode.name or "")
	winPts:set(s.gamemode and s.gamemode.winPts or 10)
	endsAt:set(type(s.endsAt) == "number" and s.endsAt or 0)
	redPts:set(s.scores and s.scores.RED or 0)
	bluPts:set(s.scores and s.scores.BLU or 0)
	winnerTeam:set(s.winner or "")
	isLoaded:set(true)
end

function module:Init(props)
	props.trove:Connect(RunService.Heartbeat, function()
		serverNow:set(workspace:GetServerTimeNow())
	end)

	applyFromReplica(props.RoundReplica.Data)

	props.trove:Add(props.RoundReplica:OnChange(function()
		applyFromReplica(props.RoundReplica.Data)
	end))
end

return module