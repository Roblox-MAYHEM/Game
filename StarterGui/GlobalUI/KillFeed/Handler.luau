local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local scoped = Fusion.scoped
local doCleanup = Fusion.doCleanup

local UI = script.Parent.Parent
local KillFeedFrame = UI:WaitForChild("KillFeed")

local KillEntry = require(script.Parent.KillEntry)

local Remotes = ReplicatedStorage:WaitForChild("Events")

-- settings
local MAX_ENTRIES = 6
local LIFETIME_SECONDS = 6
local SPACING = 6

local MOVE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_TIME = 0.20
local FADE_TWEEN = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local scope = scoped(Fusion)

type EntryRecord = {
	scope: any,
	instance: GuiObject,
	goalPos: any,      -- Value<UDim2>
	alphaGoal: any,    -- Value<number>
	removing: boolean,
}

local entries: {EntryRecord} = {}

local function getEntryHeight(inst: GuiObject): number
	local h = inst.AbsoluteSize.Y
	if h > 0 then
		return h
	end
	return inst.Size.Y.Offset
end

local function relayout()
	-- Newest at bottom; stack goes up.
	local y = 0

	for i = #entries, 1, -1 do
		local rec = entries[i]
		local inst = rec.instance

		local h = getEntryHeight(inst)
		rec.goalPos:set(UDim2.new(1, 0, 1, -y))
		y += h + SPACING
	end
end

local function hardRemoveIndex(index: number)
	local rec = entries[index]
	if not rec then
		return
	end

	table.remove(entries, index)

	if rec.instance and rec.instance.Parent then
		rec.instance:Destroy()
	end
	doCleanup(rec.scope)

	relayout()
end

local function fadeOutIndex(index: number)
	local rec = entries[index]
	if not rec or rec.removing then
		return
	end
	rec.removing = true

	-- start fade
	rec.alphaGoal:set(1)

	-- after fade completes, remove safely (index may shift)
	task.delay(FADE_TIME, function()
		local foundIndex
		for i, r in ipairs(entries) do
			if r == rec then
				foundIndex = i
				break
			end
		end
		if foundIndex then
			hardRemoveIndex(foundIndex)
		end
	end)
end

local function addKill(killer: Player, victim: Player)
	-- If we get WAY over cap due to pending fades, hard trim immediately
	while #entries > MAX_ENTRIES + 3 do
		hardRemoveIndex(1)
	end

	-- Soft trim (fade oldest) if at/over cap
	if #entries >= MAX_ENTRIES then
		fadeOutIndex(1)
	end

	local entryScope = scope:innerScope()

	-- position tween
	local startPos = UDim2.new(1, 0, 1, 20)
	local goalPos = entryScope:Value(startPos)
	local tweenPos = entryScope:Tween(goalPos, MOVE_TWEEN)

	-- alpha tween (0 visible -> 1 invisible)
	local alphaGoal = entryScope:Value(0)
	local alphaTween = entryScope:Tween(alphaGoal, FADE_TWEEN)

	local inst = KillEntry(entryScope, {
		Parent = KillFeedFrame,
		LayoutOrder = 0,
		Killer = killer,
		Victim = victim,
		Alpha = alphaTween,
	})

	-- drive Position from tween
	entryScope:Hydrate(inst) {
		Position = tweenPos,
	}

	local rec: EntryRecord = {
		scope = entryScope,
		instance = inst,
		goalPos = goalPos,
		alphaGoal = alphaGoal,
		removing = false,
	}
	table.insert(entries, rec)

	-- If AbsoluteSize wasn’t ready yet, relayout when it becomes valid
	local conn
	conn = inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if inst.AbsoluteSize.Y > 0 then
			relayout()
			if conn then
				conn:Disconnect()
				conn = nil
			end
		end
	end)
	entryScope.doCleanup(function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end)

	relayout()

	-- expire with fade
	task.delay(LIFETIME_SECONDS, function()
		for i, r in ipairs(entries) do
			if r == rec then
				fadeOutIndex(i)
				break
			end
		end
	end)
end

local module = {}

function module:Init(props)
	local trove = props and (props.Trove or props.trove)
	if trove then
		trove:Connect(Remotes.PlayerKill.OnClientEvent, addKill)
	else
		Remotes.PlayerKill.OnClientEvent:Connect(addKill)
	end
end

return module
