local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children = Fusion.Children
local peek = Fusion.peek

local EntryTemplate = script:WaitForChild("Entry")

return function(scope, props)
	local root = EntryTemplate:Clone()
	local AssistsText= root:WaitForChild("Assists")
	local DeathsText = root:WaitForChild("Deaths")
	local KillsText	 = root:WaitForChild("Kills")
	local UserText	 = root:WaitForChild("Username")


	return scope:Hydrate(root) {
		Parent = props.Parent,
		
		[Children] = {
			scope:Hydrate(UserText) {
				Text = scope:Computed(function(use)
					return tostring(use(props.Player.Name))
				end),
			},
			scope:Hydrate(KillsText) {
				Text = scope:Computed(function(use)
					return tostring(use(props.Kills))
				end),
			},
			scope:Hydrate(DeathsText) {
				Text = scope:Computed(function(use)
					return tostring(use(props.Deaths))
				end),
			},
			scope:Hydrate(AssistsText) {
				Text = scope:Computed(function(use)
					return tostring(use(props.Assists))
				end),
			}
		}

	}
end
