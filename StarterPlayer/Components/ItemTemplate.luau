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
		SlotCost: UsedAs<number>?,
		Locked: UsedAs<boolean>?,
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

	local slotCostText = scope:Computed(function(use)
		local cost = if typeof(props.SlotCost) == "number" then props.SlotCost elseif props.SlotCost then use(props.SlotCost) else 1
		return if cost and cost > 1 then `x{cost}` else ""
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

			scope:New "TextLabel" {
				Name = "Locked",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 15, 18),
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.72, 0.26),
				Text = "LOCKED",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				Visible = scope:Computed(function(use)
					return use(props.Locked) or false
				end),
				ZIndex = 20,

				[Children] = scope:New "UICorner" {
					CornerRadius = UDim.new(0, 5),
				},
			},

			scope:New "TextLabel" {
				Name = "SlotCost",
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(15, 15, 18),
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(30, 18),
				Visible = scope:Computed(function(use)
					return use(slotCostText) ~= ""
				end),
				Text = slotCostText,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 21,

				[Children] = scope:New "UICorner" {
					CornerRadius = UDim.new(0, 4),
				},
			},
		}
	}
end
