local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children = Fusion.Children
local peek = Fusion.peek

local PopupTemplate = script:WaitForChild("Popup")

return function(scope, props)
	local root = PopupTemplate:Clone()

	return scope:Hydrate(root) {
		Parent = props.Parent,

		-- fade the entry background (if it has one)
		TextTransparency = props.Alpha,
		Text = scope:Computed(function(use) return `[+{tostring(use(props.Exp))}]     {use(props.Text)}` end),
		LayoutOrder = props.LayoutOrder
	}
	
end
