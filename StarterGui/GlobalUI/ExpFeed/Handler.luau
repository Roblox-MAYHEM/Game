local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local scoped = Fusion.scoped
local doCleanup = Fusion.doCleanup

local UI = script.Parent.Parent
local ExpFeedFrame = UI:WaitForChild("ExpFeedFrame") :: Frame

local ExpPopup = require(script.Parent.ExpPopup)

local Remotes = ReplicatedStorage:WaitForChild("Events")

-- settings
local MAX_ENTRIES = 6
local LIFETIME_SECONDS = 1
local FADE_TIME = 1
local FADE_TWEEN = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local layoutIdx = 0

local scope = scoped(Fusion)

type EntryRecord = {
	scope: any,
	instance: GuiObject,
	alphaGoal : Fusion.Value<number>,
	removing : boolean,
}

local entries: {EntryRecord} = {}

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

local function addPopup(exp : number, text : string)
	text = text or ""
	-- If we get WAY over cap due to pending fades, hard trim immediately
	while #entries > MAX_ENTRIES + 3 do
		hardRemoveIndex(1)
	end

	-- Soft trim (fade oldest) if at/over cap
	if #entries >= MAX_ENTRIES then
		fadeOutIndex(1)
	end

	local entryScope = scope:innerScope()

	-- alpha tween (0 visible -> 1 invisible)
	local alphaGoal = entryScope:Value(0)
	local alphaTween = entryScope:Tween(alphaGoal, FADE_TWEEN)

	local inst = ExpPopup(entryScope, {
		Parent = ExpFeedFrame,
		Exp = exp,
		Text = text,
		Alpha = alphaTween,
		LayoutOrder = layoutIdx
	})
	
	layoutIdx -= 1
	

	local rec: EntryRecord = {
		scope = entryScope,
		instance = inst,
		alphaGoal = alphaGoal,
		removing = false,
	}
	table.insert(entries, rec)
	
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
		trove:Connect(Remotes.ExpUpdated.OnClientEvent, addPopup)
	else
		Remotes.ExpUpdated.OnClientEvent:Connect(addPopup)
	end
end

return module
