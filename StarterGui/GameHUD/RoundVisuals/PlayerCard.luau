local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client			= game:GetService("StarterPlayer")
local Players			= game:GetService("Players")

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local Children = Fusion.Children
local peek = Fusion.peek

local EntryTemplate = script:WaitForChild("Card")

return function(scope, props)
	local root = EntryTemplate:Clone()
	local PlrIcon 	= root:WaitForChild("Image")
	local Info		= root:WaitForChild("Info")
	local KillsText	= Info:WaitForChild("Kills")
	local UserText	= Info:WaitForChild("Username")
	local PlaceText	= Info:WaitForChild("Place")
	
	local Headshot = scope:Computed(function(use)
		local plr = use(props.Player)
		if not plr then return "" end

		local content = Players:GetUserThumbnailAsync(
			plr.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size180x180
		)

		return content
	end)

	return scope:Hydrate(root) {
		Parent = props.Parent,
		
		[Children] = {
			scope:Hydrate(PlrIcon) {
				Image = Headshot
			},
			
			scope:Hydrate(Info) {
				[Children] = {
					scope:Hydrate(UserText) {
						Text = scope:Computed(function(use)
							return tostring(use(props.Player and props.Player.Name or ""))
						end),
					},
					scope:Hydrate(KillsText) {
						Text = scope:Computed(function(use)
							return tostring(use(props.Kills))
						end),
					},
					scope:Hydrate(PlaceText) {
						Text = scope:Computed(function(use)
							return "#"..tostring(use(props.Place))
						end),
					}
				}
			},
			
		}

	}
end
