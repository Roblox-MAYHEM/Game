local Client = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Fusion = require(Client.Packages.Fusion)
local Children = Fusion.Children

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local HitMarkerTemplate = script.BillboardGui

local MIN_DAMAGE = 5
local MAX_DAMAGE = 100

local MIN_SIZE = 3.5
local MAX_SIZE = 7.5

local LOW_DAMAGE_COLOR = Color3.fromRGB(255, 145, 35) -- orange
local HIGH_DAMAGE_COLOR = Color3.fromRGB(130, 0, 0) -- deep red

local function inverseLerp(minValue: number, maxValue: number, value: number): number
	return math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
end

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

return function(scope: Fusion.Scope, props: { Amount: number, Humanoid: Humanoid })
	local amount = props.Amount
	local alpha = inverseLerp(MIN_DAMAGE, MAX_DAMAGE, amount)

	local markerSize = lerpNumber(MIN_SIZE, MAX_SIZE, alpha)
	local markerColor = LOW_DAMAGE_COLOR:Lerp(HIGH_DAMAGE_COLOR, alpha)

	local offsetX = math.random(-10, 10) / 10
	local offsetY = math.random(-10, 10) / 10
	local offsetZ = math.random(-10, 10) / 10

	local startOffset = Vector3.new(offsetX, offsetY, offsetZ)
	local endOffset = startOffset + Vector3.new(0, 2, 0)

	local UI = HitMarkerTemplate:Clone()
	local DmgLabel = UI.DmgLabel

	Debris:AddItem(UI, 0.5)

	return scope:Hydrate(UI) {
		Adornee = props.Humanoid.Parent.HumanoidRootPart,
		Parent = workspace,

		StudsOffset = scope:Tween(endOffset, tweenInfo),
		Size = scope:Tween(UDim2.fromScale(markerSize, markerSize), tweenInfo),

		[Children] = {
			scope:Hydrate(DmgLabel) {
				Text = tostring(math.round(amount)),
				TextColor3 = markerColor,
			},
		},
	}
end