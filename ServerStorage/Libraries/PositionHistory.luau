local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

export type PartFrame = {
	part: BasePart,
	name: string,
	cframe: CFrame,
	size: Vector3,
}

export type CharacterFrame = {
	t: number,
	rootCFrame: CFrame,
	rootPos: Vector3,
	rootVel: Vector3,
	parts: { PartFrame },
	partMap: { [BasePart]: PartFrame },
	nameMap: { [string]: PartFrame },
}

type HistoryBuffer = {
	samples: { [number]: CharacterFrame? },
	first: number,
	count: number,
	capacity: number,
	trackedParts: { BasePart },
	nextPartRefresh: number,
}

local PositionHistory = {
	MaxRewindSeconds = 1.0,
	MaxExtrapolation = 0.05,
	SampleHz = 60,
	SampleInterval = 1 / 60,
	_history = {} :: { [Model]: HistoryBuffer },
	_initialized = false,
	_sampleAccum = 0,
}

local EPSILON = 1e-6
local PART_REFRESH_INTERVAL = 0.25
local TRACKED_HITBOX_NAMES = {}

for _, name in ipairs({
	"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart",
	"Left Arm", "Right Arm", "Left Leg", "Right Leg",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}) do
	TRACKED_HITBOX_NAMES[name] = true
end

local function lerp(a: Vector3, b: Vector3, alpha: number): Vector3
	return a + (b - a) * alpha
end

local function getCapacity(): number
	return math.max(4, math.ceil(PositionHistory.MaxRewindSeconds * PositionHistory.SampleHz) + 3)
end

local function getRootPart(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	return if root and root:IsA("BasePart") then root else nil
end

local function hasTaggedAncestor(instance: Instance, stopAt: Instance, tagName: string): boolean
	local current = instance
	while current and current ~= stopAt do
		if CollectionService:HasTag(current, tagName) then return true end
		current = current.Parent
	end
	return false
end

local function shouldTrackPart(character: Model, part: BasePart, root: BasePart?): boolean
	return not hasTaggedAncestor(part, character, "Weapon")
		and (part == root or TRACKED_HITBOX_NAMES[part.Name] or (part.Parent == character and part.Name ~= "Handle"))
end

local function refreshTrackedParts(character: Model, history: HistoryBuffer, sampleTime: number): { BasePart }
	if #history.trackedParts > 0 and sampleTime < history.nextPartRefresh then
		return history.trackedParts
	end

	table.clear(history.trackedParts)
	history.nextPartRefresh = sampleTime + PART_REFRESH_INTERVAL

	local root = getRootPart(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and shouldTrackPart(character, descendant, root) then
			history.trackedParts[#history.trackedParts + 1] = descendant
		end
	end
	return history.trackedParts
end

local function captureFrame(character: Model, sampleTime: number, history: HistoryBuffer): CharacterFrame?
	local root = getRootPart(character)
	if not root then return nil end

	local parts, partMap, nameMap = {}, {}, {}
	for _, part in ipairs(refreshTrackedParts(character, history, sampleTime)) do
		if part.Parent and part:IsDescendantOf(character) then
			local partFrame = { part = part, name = part.Name, cframe = part.CFrame, size = part.Size }
			parts[#parts + 1] = partFrame
			partMap[part] = partFrame
			nameMap[part.Name] = partFrame
		end
	end

	return {
		t = sampleTime,
		rootCFrame = root.CFrame,
		rootPos = root.Position,
		rootVel = root.AssemblyLinearVelocity,
		parts = parts,
		partMap = partMap,
		nameMap = nameMap,
	}
end

local function newHistory(): HistoryBuffer
	return { samples = table.create(getCapacity()), first = 1, count = 0, capacity = getCapacity(), trackedParts = {}, nextPartRefresh = 0 }
end

local function appendSample(history: HistoryBuffer, frame: CharacterFrame)
	if history.capacity ~= getCapacity() then
		history.samples, history.first, history.count, history.capacity = table.create(getCapacity()), 1, 0, getCapacity()
	end

	local index
	if history.count < history.capacity then
		index = ((history.first + history.count - 1) % history.capacity) + 1
		history.count += 1
	else
		index = history.first
		history.first = (history.first % history.capacity) + 1
	end
	history.samples[index] = frame
end

local function getSample(history: HistoryBuffer, logicalIndex: number): CharacterFrame?
	if logicalIndex < 1 or logicalIndex > history.count then return nil end
	return history.samples[((history.first + logicalIndex - 2) % history.capacity) + 1]
end

local function makePartFrame(a: PartFrame, b: PartFrame?, alpha: number): PartFrame
	return {
		part = a.part,
		name = a.name,
		cframe = if b then a.cframe:Lerp(b.cframe, alpha) else a.cframe,
		size = if b then lerp(a.size, b.size, alpha) else a.size,
	}
end

local function mapParts(sourceParts, otherMap, alpha: number)
	local parts, partMap, nameMap = {}, {}, {}
	for _, partA in ipairs(sourceParts) do
		local partFrame = makePartFrame(partA, otherMap and otherMap[partA.part], alpha)
		parts[#parts + 1] = partFrame
		partMap[partFrame.part] = partFrame
		nameMap[partFrame.name] = partFrame
	end
	return parts, partMap, nameMap
end

local function frameFrom(frame: CharacterFrame, targetTime: number, delta: Vector3?): CharacterFrame
	delta = delta or Vector3.zero
	local parts, partMap, nameMap = {}, {}, {}
	for _, partFrame in ipairs(frame.parts) do
		local moved = {
			part = partFrame.part,
			name = partFrame.name,
			cframe = partFrame.cframe + delta,
			size = partFrame.size,
		}
		parts[#parts + 1] = moved
		partMap[moved.part] = moved
		nameMap[moved.name] = moved
	end

	return {
		t = targetTime,
		rootCFrame = frame.rootCFrame + delta,
		rootPos = frame.rootPos + delta,
		rootVel = frame.rootVel,
		parts = parts,
		partMap = partMap,
		nameMap = nameMap,
	}
end

local function interpolateFrames(a: CharacterFrame, b: CharacterFrame, targetTime: number): CharacterFrame
	local span = b.t - a.t
	local alpha = if span > EPSILON then math.clamp((targetTime - a.t) / span, 0, 1) else 0
	local parts, partMap, nameMap = mapParts(a.parts, b.partMap, alpha)
	return {
		t = targetTime,
		rootCFrame = a.rootCFrame:Lerp(b.rootCFrame, alpha),
		rootPos = lerp(a.rootPos, b.rootPos, alpha),
		rootVel = lerp(a.rootVel, b.rootVel, alpha),
		parts = parts,
		partMap = partMap,
		nameMap = nameMap,
	}
end

local function findBracket(history: HistoryBuffer, targetTime: number): (CharacterFrame?, CharacterFrame?)
	local lo, hi = 1, history.count
	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		local sample = getSample(history, mid)
		if sample and sample.t == targetTime then
			return sample, sample
		elseif sample and sample.t < targetTime then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end

	local upperIndex = math.clamp(lo, 2, history.count)
	return getSample(history, upperIndex - 1), getSample(history, upperIndex)
end

local function captureNow(character: Model): CharacterFrame?
	if not character then return nil end

	local history = PositionHistory._history[character]
	if not history then
		history = newHistory()
		PositionHistory._history[character] = history
	end

	local frame = captureFrame(character, workspace:GetServerTimeNow(), history)
	if frame then appendSample(history, frame) end
	return frame
end

local function samplePositions(sampleTime: number?)
	local now = sampleTime or workspace:GetServerTimeNow()
	for character, history in pairs(PositionHistory._history) do
		if character.Parent == nil then
			PositionHistory._history[character] = nil
			continue
		end

		local frame = captureFrame(character, now, history)
		if frame then appendSample(history, frame) end
	end
end

local function bindSampler(callback: (number) -> ())
	local runService = RunService :: any
	if typeof(runService.BindToSimulation) == "function" then
		local ok = pcall(function()
			runService:BindToSimulation(callback, Enum.StepFrequency.Hz60)
		end)
		if ok then return end
	end
	RunService.Heartbeat:Connect(callback)
end

function PositionHistory:Init(maxRewindSeconds: number?, sampleHz: number?)
	if PositionHistory._initialized then return end

	PositionHistory.MaxRewindSeconds = maxRewindSeconds or PositionHistory.MaxRewindSeconds
	PositionHistory.SampleHz = sampleHz or PositionHistory.SampleHz
	PositionHistory.SampleInterval = 1 / PositionHistory.SampleHz
	PositionHistory._history = {}

	local function watchPlayer(player: Player)
		if player.Character then PositionHistory.RegisterCharacter(player.Character) end
		player.CharacterAdded:Connect(PositionHistory.RegisterCharacter)
		player.CharacterRemoving:Connect(PositionHistory.UnregisterCharacter)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
	Players.PlayerRemoving:Connect(function(player)
		if player.Character then PositionHistory.UnregisterCharacter(player.Character) end
	end)

	for _, rig in ipairs(CollectionService:GetTagged("Dummy")) do
		if rig:IsA("Model") then PositionHistory.RegisterCharacter(rig) end
	end
	CollectionService:GetInstanceAddedSignal("Dummy"):Connect(function(rig)
		if rig:IsA("Model") then PositionHistory.RegisterCharacter(rig) end
	end)
	CollectionService:GetInstanceRemovedSignal("Dummy"):Connect(function(rig)
		if rig:IsA("Model") then PositionHistory.UnregisterCharacter(rig) end
	end)

	bindSampler(function(dt)
		PositionHistory._sampleAccum += dt
		if PositionHistory._sampleAccum < PositionHistory.SampleInterval then return end

		PositionHistory._sampleAccum = PositionHistory._sampleAccum % PositionHistory.SampleInterval
		samplePositions(workspace:GetServerTimeNow())
	end)

	PositionHistory._initialized = true
end

function PositionHistory.RegisterCharacter(character: Model)
	if not character then return end

	local history = PositionHistory._history[character]
	if not history then
		history = newHistory()
		PositionHistory._history[character] = history
	end
	if history.count > 0 or captureNow(character) then return end

	task.defer(function()
		local start = os.clock()
		while character.Parent ~= nil and history.count == 0 and os.clock() - start < 2 do
			if captureNow(character) then return end
			RunService.Heartbeat:Wait()
		end
	end)
end

function PositionHistory.UnregisterCharacter(character: Model)
	if character then PositionHistory._history[character] = nil end
end

function PositionHistory.GetFrameAt(character: Model, targetTime: number): CharacterFrame?
	local history = PositionHistory._history[character]
	if not history or history.count == 0 then return nil end

	local oldest = getSample(history, 1)
	local newest = getSample(history, history.count)
	if not oldest or not newest then return nil end
	if targetTime <= oldest.t then return oldest end

	if targetTime >= newest.t then
		local live = captureFrame(character, workspace:GetServerTimeNow(), history)
		if not live then return newest end
		if targetTime <= live.t then return interpolateFrames(newest, live, targetTime) end

		local dt = math.min(targetTime - live.t, PositionHistory.MaxExtrapolation)
		return frameFrom(live, targetTime, live.rootVel * dt)
	end

	local lower, upper = findBracket(history, targetTime)
	if not lower then return nil end
	return if upper and lower ~= upper then interpolateFrames(lower, upper, targetTime) else lower
end

return PositionHistory
