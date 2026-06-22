local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children = Fusion.Children
local peek = Fusion.peek

local KillEntryTemplate = script:WaitForChild("KillEntry")

return function(scope, props)
	local root = KillEntryTemplate:Clone()
	local killerText = root:WaitForChild("Killer")
	local victimText = root:WaitForChild("Victim")
	local killedText = root:WaitForChild("Killed")
	
	return scope:Hydrate(root) {
		Parent = props.Parent,
		LayoutOrder = props.LayoutOrder,

		-- fade the entry background (if it has one)
		BackgroundTransparency = props.Alpha,

		[Children] = {
			scope:Hydrate(killerText) {
				Text = scope:Computed(function()
					local p = peek(props.Killer)
					return (p and p.Name) or ""
				end),
				
				TextColor3 = scope:Computed(function()
					local p = peek(props.Killer)
					return (p and p.Team and p.Team.TeamColor.Color) or Color3.fromRGB(0,0,0)
				end),

				TextTransparency = props.Alpha,
			},
			
			scope:Hydrate(killedText) {
				TextTransparency = props.Alpha,
			},

			scope:Hydrate(victimText) {
				Text = scope:Computed(function()
					local p = peek(props.Victim)
					return (p and p.Name) or ""
				end),
				
				TextColor3 = scope:Computed(function()
					local p = peek(props.Victim)
					return (p and p.Team and p.Team.TeamColor.Color) or Color3.fromRGB(0,0,0)
				end),

				TextTransparency = props.Alpha,
			},
		},
	}
end
