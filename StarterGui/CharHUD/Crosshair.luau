local Client = game:GetService("StarterPlayer")

local Fusion = require(Client.Packages.Fusion)
local peek = Fusion.peek
local Children = Fusion.Children

local Bindables = Client:WaitForChild("Bindables")
local Shoot = Bindables:WaitForChild("Shoot")

local WeaponObserver = require(script.Parent.Utils.WeaponObserver)

local BASE_GAP = 9
local PIXELS_PER_SPREAD = 2.5

local FIRE_KICK_STEP = 30
local FIRE_KICK_MAX = 50
local FIRE_KICK_DECAY = 1.25

local GAP_SPEED = 30
local EQUIP_GAP_SPEED = 45
local EQUIP_SPEED_TIME = 0.12
local DAMPING = 1.05

local module = {}

function module:Init(Properties: { Scope: Fusion.Scope, UI: ScreenGui })
	local scope = Properties.Scope:innerScope()
	local UI = Properties.UI

	local Crosshair = UI:WaitForChild("CrosshairFrame")
	local UpPart = Crosshair:WaitForChild("UpPart")
	local DownPart = Crosshair:WaitForChild("DownPart")
	local LeftPart = Crosshair:WaitForChild("LeftPart")
	local RightPart = Crosshair:WaitForChild("RightPart")

	local weaponSpread = scope:Value(0)
	local shotKick = scope:Value(0)
	local springSpeed = scope:Value(GAP_SPEED)

	local decayRunning = false
	local equipSpeedToken = 0

	local function addShotKick(amount: number)
		shotKick:set(math.min(FIRE_KICK_MAX, peek(shotKick) + amount))

		if decayRunning then
			return
		end

		decayRunning = true
		task.spawn(function()
			while peek(shotKick) > 0 do
				task.wait()
				shotKick:set(math.max(0, peek(shotKick) - FIRE_KICK_DECAY))
			end
			decayRunning = false
		end)
	end

	local function boostEquipSpeed()
		equipSpeedToken += 1
		local token = equipSpeedToken

		springSpeed:set(EQUIP_GAP_SPEED)

		task.delay(EQUIP_SPEED_TIME, function()
			if equipSpeedToken == token then
				springSpeed:set(GAP_SPEED)
			end
		end)
	end

	WeaponObserver.observe(scope, {
		onReset = function()
			weaponSpread:set(0)
			springSpeed:set(GAP_SPEED)
		end,

		onWeapon = function(localScope, weapon)
			boostEquipSpeed()

			WeaponObserver.bindValue(localScope, weapon, "Spread", function(value)
				weaponSpread:set(math.max(0, tonumber(value) or 0))
			end)
		end,
	})

	table.insert(scope, Shoot.Event:Connect(function()
		addShotKick(FIRE_KICK_STEP)
	end))

	local goalGap = scope:Computed(function(use)
		return BASE_GAP + (use(weaponSpread) * PIXELS_PER_SPREAD) + use(shotKick)
	end)

	local gap = scope:Spring(goalGap, springSpeed, DAMPING)

	local function positionX(sign: number)
		return scope:Computed(function(use)
			return UDim2.new(0.5, sign * use(gap), 0.5, 0)
		end)
	end

	local function positionY(sign: number)
		return scope:Computed(function(use)
			return UDim2.new(0.5, 0, 0.5, sign * use(gap))
		end)
	end

	scope:Hydrate(Crosshair) {
		[Children] = {
			scope:Hydrate(UpPart) {
				Position = positionY(-1),
			},

			scope:Hydrate(DownPart) {
				Position = positionY(1),
			},

			scope:Hydrate(LeftPart) {
				Position = positionX(-1),
			},

			scope:Hydrate(RightPart) {
				Position = positionX(1),
			},
		},
	}

	return scope
end

return module