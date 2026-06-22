local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")
local Packages = Client.Packages

local Fusion = require(Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local WeaponInfo = require(ReplicatedStorage.Assets.Weapons.Data.Info)

local ItemTemplate = script.Slot

local function getIconFor(name: string): string?
	local info = WeaponInfo[name] 
	return info and info.THUMBNAIL or nil
end

return function(
	scope : Fusion.Scope, 
	props: {
		ItemName: UsedAs<string>,
		Icon: UsedAs<string?>?,
		Disabled: UsedAs<boolean>?,
		ShowLevel: UsedAs<boolean>?,
		Level: UsedAs<number>?,
		barSize: UsedAs<number>?,
		OnMouseDown: (() -> ())?,
		Parent: UsedAs<Instance?>,
		LayoutOrder: UsedAs<number>?,
		Size: UsedAs<UDim2>?,
	}
) : Frame
	
	local template = ItemTemplate:Clone()
	local DragButton = template:WaitForChild("DragButton")
	local DisabledOverlay = template:WaitForChild("DisabledOverlay")
	local StatsFrame = template:WaitForChild("StatsFrame")
	local ExperienceBar = StatsFrame:WaitForChild("ExperienceBar")
	local InfoFrame = StatsFrame:WaitForChild("InfoFrame")
	
	local icon = scope:Computed(function(use)
		local explicit = props.Icon and use(props.Icon)
		if explicit ~= nil then return explicit end
		local n = use(props.ItemName)
		return n and getIconFor(n) or ""
	end)
		
	return scope:Hydrate(template) {
		Parent = props.Parent,
		LayoutOrder = props.LayoutOrder,
		Name = props.ItemName,
		Visible = true,
		Size = props.Size,
		
		[Children] = {
			scope:Hydrate(DragButton) {
				AutoButtonColor = scope:Computed(function(use)
					return not (use(props.Disabled) or false)
				end),
				Image = icon,
				ImageTransparency = scope:Computed(function(use)
					return (use(icon) and 0 or 1)
				end),
				
				[Children] = scope:Hydrate(DragButton.TextLabel) { Text = props.ItemName },
				
				[OnEvent "MouseButton1Down"] = function()
					if peek(props.OnMouseDown) and not peek(props.Disabled) then
						props.OnMouseDown()
					end
				end,
			},
			
			scope:Hydrate(StatsFrame) { 
				Visible = scope:Computed(function(use)
					return use(props.ShowLevel) or false
				end),
				
				[Children] = {
					scope:Hydrate(ExperienceBar) { 
						[Children] = scope:Hydrate(ExperienceBar.Fill) { Size = props.barSize } 
					},
					scope:Hydrate(InfoFrame) {
						[Children] = scope:Hydrate(InfoFrame.Text) {
							Text = scope:Computed(function(use) return use(props.Level) or 0 end )
						}
					}
				}
			},
			
			scope:Hydrate(DisabledOverlay) {
				Visible = scope:Computed(function(use)
					return use(props.Disabled) or false
				end),
			},
		}
	}
end
