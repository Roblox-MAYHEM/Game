--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ShapecastHitbox = require(ReplicatedStorage.Packages.ShapecastHitbox)

type RaycastCallback = (result: RaycastResult, segment: any) -> ()
type HumanoidCallback = (humanoid: Humanoid, result: RaycastResult, segment: any) -> ()

local ClientHitbox = setmetatable({}, { __index = ShapecastHitbox })
ClientHitbox.__index = ClientHitbox

-- Constructor
function ClientHitbox.new(hitboxPart: BasePart, params: RaycastParams?)
	if not params then
		local p = RaycastParams.new() :: RaycastParams 
		p.FilterDescendantsInstances = { LocalPlayer and LocalPlayer.Character }
		p.FilterType = Enum.RaycastFilterType.Exclude
		params = p
	end

	local base = ShapecastHitbox.new(hitboxPart, params)
	local self = setmetatable(base, ClientHitbox) :: any

	self.HitTargets = {} :: { [Humanoid]: true }

	-- Callback lists
	self._onOtherHit = {} :: { RaycastCallback }
	self._onHumHit = {} :: { HumanoidCallback }

	-- Default lifecycle hooks
	self:BeforeStart(function()
		table.clear(self.HitTargets)
	end)

	self:OnHit(function(result: RaycastResult, segment: any?)
		self:_processHit(result, segment)
		return self
	end)

	return self :: ShapecastHitbox.Hitbox
end

-- Internal hit processing
function ClientHitbox:_processHit(result: RaycastResult, segment: any?)
	local hit = result.Instance
	if not hit then return end

	-- Find the closest Model, then a Humanoid within it
	local model = hit:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")

	if humanoid then
		-- De-dupe per-humanoid per-session
		if self.HitTargets[humanoid] then return end
		self.HitTargets[humanoid] = true

		for _, callback in ipairs(self._onHumHit) do
			callback(humanoid, result, segment)
		end
	else
		for _, callback in ipairs(self._onOtherHit) do
			callback(result, segment)
		end
	end
end

-- Chainable callbacks
function ClientHitbox:OnHumHit(callback: HumanoidCallback)
	table.insert(self._onHumHit, callback)
	return self
end

function ClientHitbox:OnOtherHit(callback: RaycastCallback)
	table.insert(self._onOtherHit, callback)
	return self
end

-- Optional: manually clear the per-session hit cache
function ClientHitbox:ResetHits()
	table.clear(self.HitTargets)
end

return ClientHitbox
