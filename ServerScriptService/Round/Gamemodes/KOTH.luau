-- KOTH.lua
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local SS	  = game:GetService("ServerStorage")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Promise = require(Packages.Promise)
local Trove   = require(Packages.Trove)

local Events  = ReplicatedStorage.Events
local LevelSystem = require(SS.Libraries.LevelSystem)

local KOTH = {}
KOTH.__index = KOTH

KOTH.ID = "KOTH"
KOTH.NAME = "King of the Hill"
KOTH.ROUND_TIME = 120
KOTH.WIN_PTS = 100
KOTH.TICK_SECONDS = 0.5
KOTH.TICK_EXP = 5

local function alivePlayerFromHit(hit: BasePart): Player?
	local char = hit and hit.Parent
	if not char then return nil end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end

	return Players:GetPlayerFromCharacter(char)
end

function KOTH.new(ctx)
	local self = setmetatable({}, KOTH)
	self._ctx = ctx
	self._trove = Trove.new()

	self._points = {}        -- [Team] = pts
	self._countByTeam = {}   -- [Team] = players in hill
	self._touchCount = {}    -- [Player] = touching parts count
	self._touchTime = {} 	 -- [Player] = time elapsed in hill

	self._pointsArea = nil
	self._ring = nil
	self._defaultColor = nil

	self._active = false
	self._ended = false

	return self
end

function KOTH:_setColor(color)
	if self._pointsArea then
		self._pointsArea.Color = color
	end
	if self._ring and self._ring:IsA("BasePart") then
		self._ring.Color = color
	end
end

function KOTH:_enter(plr: Player)
	local team = plr.Team
	if not team then return end
	self._countByTeam[team] = (self._countByTeam[team] or 0) + 1
	self._touchTime[plr] = 0
	Events.EnterHill:FireClient(plr, true)
end

function KOTH:_exit(plr: Player)
	local team = plr.Team
	if not team then return end
	local new = (self._countByTeam[team] or 0) - 1
	if new <= 0 then
		self._countByTeam[team] = nil
	else
		self._countByTeam[team] = new
	end
	self._touchTime[plr] = nil
	Events.EnterHill:FireClient(plr, false)
end

function KOTH:_onTouched(hit: BasePart)
	if not self._active then return end

	local plr = alivePlayerFromHit(hit)
	if not plr then return end

	local c = (self._touchCount[plr] or 0) + 1
	self._touchCount[plr] = c
	if c == 1 then
		self:_enter(plr)
	end
end

function KOTH:_onTouchEnded(hit: BasePart)
	if not self._active then return end

	local plr = alivePlayerFromHit(hit)
	if not plr then return end

	local c = (self._touchCount[plr] or 0) - 1
	if c <= 0 then
		self._touchCount[plr] = nil
		self:_exit(plr)
	else
		self._touchCount[plr] = c
	end
end

function KOTH:_tickAward(): Team?
	if not self._active then
		return nil
	end

	local owner: Team? = nil
	local contested = false

	for team, count in pairs(self._countByTeam) do
		if count and count > 0 then
			if not owner then
				owner = team
			else
				contested = true
				break
			end
		end
	end

	if not owner or contested then
		self:_setColor(self._defaultColor)
		return nil
	end

	local newPts = (self._points[owner] or 0) + 1
	self._points[owner] = newPts
	
	for plr, cnt in pairs(self._touchCount) do
		if plr.Team == owner and cnt > 0 then
			self._touchTime[plr] += KOTH.TICK_SECONDS
			
			if self._touchTime[plr] - KOTH.TICK_EXP > 0 then
				self._touchTime[plr] = 0
				LevelSystem.AddExp(plr, 40, "Holding Hill")
			end
			
		end
	end

	-- NEW: update round state through ctx API (no direct remotes here)
	if self._ctx.SetScore then
		self._ctx.SetScore(owner, newPts)
	end

	self:_setColor(owner.TeamColor.Color)

	if newPts >= KOTH.WIN_PTS then
		return owner
	end

	return nil
end

function KOTH:Start()
	self._active = true
	self._ended = false

	local hill = self._ctx.Map:WaitForChild("Hill")
	self._pointsArea = hill:WaitForChild("PointsArea")
	self._ring = hill:FindFirstChild("Ring")
	self._defaultColor = self._pointsArea.Color

	self:_setColor(self._defaultColor)

	self._trove:Connect(self._pointsArea.Touched, function(hit)
		self:_onTouched(hit)
	end)

	self._trove:Connect(self._pointsArea.TouchEnded, function(hit)
		self:_onTouchEnded(hit)
	end)

	-- ensure dead players don't remain counted
	local function hook(plr: Player)
		self._trove:Connect(plr.CharacterAdded, function(char)
			local hum = char:WaitForChild("Humanoid")
			hum.Died:Once(function()
				if self._touchCount[plr] then
					self._touchCount[plr] = nil
					self:_exit(plr)
				end
			end)
		end)
	end

	for _, plr in ipairs(self._ctx.Players:GetPlayers()) do
		hook(plr)
	end
	self._trove:Connect(self._ctx.Players.PlayerAdded, hook)

	-- scoring loop
	local scorePromise = Promise.new(function(resolve, _reject, onCancel)
		local acc = 0
		local conn

		conn = RunService.Heartbeat:Connect(function(dt)
			if not self._active then return end

			acc += dt
			if acc < KOTH.TICK_SECONDS then return end
			acc -= KOTH.TICK_SECONDS

			local winner = self:_tickAward()
			if winner then
				resolve(winner)
			end
		end)

		onCancel(function()
			if conn then conn:Disconnect() end
		end)

		self._trove:Add(conn)
	end)

	return Promise.race({
		Promise.delay(KOTH.ROUND_TIME):andThenReturn(nil),
		scorePromise,
	})
end

function KOTH:End(winnerTeam: Team?)
	if self._ended then
		return Promise.resolve()
	end
	self._ended = true
	self._active = false

	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end

	table.clear(self._touchCount)
	table.clear(self._countByTeam)

	if self._pointsArea and self._defaultColor then
		if winnerTeam then
			self:_setColor(winnerTeam.TeamColor.Color)
		else
			self:_setColor(self._defaultColor)
		end
	end
	
	if winnerTeam then
		for _, plr in winnerTeam:GetPlayers() do
			LevelSystem.AddExp(plr, 100, "Won game")
		end
	end

	local t = (self._ctx.Config and self._ctx.Config.DISPLAY_WINNER_TIME) or 5
	return Promise.delay(t)
end

function KOTH:Destroy()
	if self._pointsArea and self._defaultColor then
		self:_setColor(self._defaultColor)
	end

	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return KOTH
