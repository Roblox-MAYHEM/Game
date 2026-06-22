local Players = game:GetService("Players")
local Client = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(Client.Packages.Fusion)
local scoped = Fusion.scoped
local peek = Fusion.peek
local Children, OnEvent, Out = Fusion.Children, Fusion.OnEvent, Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

type DragInfo = {
	id: string,
	mouseOffset: Vector2 -- relative to the dragged item
}

local function Draggable(
	scope: Fusion.Scope,
	props: {
		ID: string,
		Name: UsedAs<string>?,
		Parent: UsedAs<Instance?>,
		Layout: {
			LayoutOrder: UsedAs<number>?,
			Position: UsedAs<UDim2>?,
			AnchorPoint: UsedAs<Vector2>?,
			ZIndex: UsedAs<number>?,
			Size: UsedAs<UDim2>?,
			AutomaticSize: UsedAs<Enum.AutomaticSize>?,
			OutAbsolutePosition: Fusion.Value<Vector2>?,
		},
		Dragging: {
			MousePosition: UsedAs<Vector2>,
			SelfDragInfo: UsedAs<DragInfo?>,
			OverlayFrame: UsedAs<Instance?>
		},
		[typeof(Children)]: Fusion.Child
	}
): Fusion.Child
	-- When `nil`, the parent can't be measured for some reason.
	local parentSize = scope:Value(nil)
	local resizeConn = nil

	scope:Observer(props.Parent):onBind(function()
		if resizeConn then resizeConn:Disconnect() resizeConn = nil end

		local parent = peek(props.Parent)
		if parent == nil or not parent:IsA("GuiObject") then
			parentSize:set(nil)
			return
		end

		parentSize:set(parent.AbsoluteSize)
		resizeConn = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			parentSize:set(parent.AbsoluteSize)
		end)
	end)

	table.insert(scope, function()
		if resizeConn then resizeConn:Disconnect() end
	end)

	return scope:New "Frame" {
		Name = props.Name or "Draggable",
		Parent = scope:Computed(function(use)
			return
				if use(props.Dragging.SelfDragInfo) ~= nil
				then use(props.Dragging.OverlayFrame)
				else use(props.Parent)
		end),

		LayoutOrder = props.Layout.LayoutOrder,
		AnchorPoint = props.Layout.AnchorPoint,
		ZIndex = props.Layout.ZIndex,
		AutomaticSize = props.Layout.AutomaticSize,

		BackgroundTransparency = 1,

		Position = scope:Computed(function(use)
			local dragInfo = use(props.Dragging.SelfDragInfo)
			if dragInfo == nil then return use(props.Layout.Position) or UDim2.fromOffset(0, 0) end

			local mousePos = use(props.Dragging.MousePosition)
			local overlay = use(props.Dragging.OverlayFrame)
			local overlayOrigin = overlay and overlay.AbsolutePosition or Vector2.zero
			local topLeft = mousePos - dragInfo.mouseOffset - overlayOrigin
			return UDim2.fromOffset(topLeft.X, topLeft.Y)
		end),
		-- Calculated manually so the Scale can be set relative to
		-- `props.Parent` at all times, rather than the `Parent` of this Frame.
		Size = scope:Computed(function(use)
			local udim2 = use(props.Layout.Size) or UDim2.fromOffset(0, 0)
			local parentSize = use(parentSize) or Vector2.zero
			return UDim2.fromOffset(
				udim2.X.Scale * parentSize.X + udim2.X.Offset,
				udim2.Y.Scale * parentSize.Y + udim2.Y.Offset
			)
		end),

		[Out "AbsolutePosition"] = props.Layout.OutAbsolutePosition,
		[Children] = props[Children]
	}
end

return Draggable