-- MeleeValidator.lua
-- Server-only. Per-attacker instance. Returns true/false (+ optional reason).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DEFAULTS = {
	-- Core validation
	Window   = 1.0,   -- attack window (sec)
	Grace    = 0.08,  -- latency allowance
	Range    = 9,     -- studs
	Arc      = 110,   -- degrees in front
	Debounce = 0.12,  -- per-target lockout
	LOS      = false, -- check line-of-sight?
}

local DEFAULT_FUNCS = {
	CanDamage      = function() return true end,
	IgnoreInstance = function() return false end,
}

-- ── small helpers ─────────────────────────────────────────────────────────────
local function playerOf(char) return char and Players:GetPlayerFromCharacter(char) end
local function rootOf(char)   return char and char:FindFirstChild("HumanoidRootPart") end
local function humOf(char)    return char and char:FindFirstChildOfClass("Humanoid") end

local function keyForChar(char) -- works for players & NPCs, no plugin perms
	local plr = playerOf(char)
	if plr then return ("P_%d"):format(plr.UserId) end
	local uid = char:GetAttribute("UID")
	if uid == nil then
		uid = tostring(math.random(1e6, 1e9))
		char:SetAttribute("UID", uid)
	end
	return ("NPC_%s_%s"):format(char.Name, uid)
end

local function inCone(attCF, targetPos, deg)
	if deg >= 179.9 then return true end
	local v = targetPos - attCF.Position
	if v.Magnitude < 1e-3 then return true end
	return attCF.LookVector:Dot(v.Unit) >= math.cos(math.rad(deg))
end

local function hasLineOfSight(fromPos, toPos, ignore, cfg, funcs)
	if not cfg.LOS then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true

	local hit = Workspace:Raycast(fromPos, toPos - fromPos, params)
	if not hit or not hit.Instance then return true end
	if funcs.IgnoreInstance(hit.Instance) then
		local rem = toPos - hit.Position
		if rem.Magnitude <= 0.05 then return true end
		local p2 = RaycastParams.new()
		p2.FilterType = Enum.RaycastFilterType.Exclude
		p2.FilterDescendantsInstances = ignore
		p2.IgnoreWater = true
		return Workspace:Raycast(hit.Position + rem.Unit * 0.05, rem, p2) == nil
	end
	return false
end

-- ── class ─────────────────────────────────────────────────────────────────────
local MeleeValidator = {}
MeleeValidator.__index = MeleeValidator

function MeleeValidator.new(char, config)
	local self = setmetatable({}, MeleeValidator)
	self.cfg = table.clone(DEFAULTS)
	
	for k, v in pairs(config or {}) do
		self.cfg[k] = v
	end
	
	self.funcs = table.clone(DEFAULT_FUNCS)
	for k, v in pairs(config or {}) do
		if DEFAULT_FUNCS[k] then
			self.funcs[k] = v
		end
	end
	
	self.Attacker   = char
	self.windowEnd  = nil
	self.lastHits   = {} -- [targetKey] = timestamp
	
	return self
end

-- Open/close the server-trusted attack window
function MeleeValidator:BeginAttack()
	self.windowEnd = time() + self.cfg.Window + self.cfg.Grace
	table.clear(self.lastHits)
	return true
end
function MeleeValidator:EndAttack()
	self.windowEnd = nil
	return true
end

-- Minimal client payload: target character only.
function MeleeValidator:ValidateHit(targetChar)
	local a, t = self.Attacker, targetChar
	if not a or not t or a == t then return false, "bad-entities" end

	local ah, th = humOf(a), humOf(t)
	local ar, tr = rootOf(a), rootOf(t)
	if not (ah and th and ar and tr) then return false, "missing-parts" end
	if th.Health <= 0 then return false, "dead-target" end

	local now = time()
	if not self.windowEnd or now > self.windowEnd then return false, "window-closed" end

	local tKey = keyForChar(t)
	local last = self.lastHits[tKey]
	if last and (now - last) < self.cfg.Debounce then return false, "debounced" end

	local ap, tp = playerOf(a), playerOf(t)
	if not self.funcs.CanDamage(ap, tp) then return false, "friendly-fire" end

	if (tr.Position - ar.Position).Magnitude > self.cfg.Range then
		return false, "out-of-range"
	end
	if not inCone(ar.CFrame, tr.Position, self.cfg.Arc) then
		return false, "outside-arc"
	end

	if self.cfg.LOS then
		local ignore = { t, a }
		if not hasLineOfSight(ar.Position, tr.Position, ignore, self.cfg, self.funcs) then
			return false, "blocked"
		end
	end

	self.lastHits[tKey] = now
	return true
end

function MeleeValidator:Cleanup()
	self.windowEnd = nil
	table.clear(self.lastHits)
end

return MeleeValidator
