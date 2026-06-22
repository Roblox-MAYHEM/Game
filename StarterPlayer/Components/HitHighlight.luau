local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService 		= game:GetService("TweenService")
local Debris			= game:GetService("Debris")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages").Fusion)
local Children = Fusion.Children

local fillTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local outlineTween = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local HitHighlightTemplate = script:WaitForChild("Highlight")

return function( scope: Fusion.scope, props: { Character : Model })
	local UI = HitHighlightTemplate:Clone()

	Debris:AddItem(UI, 0.5)
	return scope:Hydrate(UI) {
		Parent = props.Character,
		FillTransparency = scope:Tween(0.95, fillTween),
		OutlineTransparency = scope:Tween(0.7, outlineTween),
	}
end
