local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Client = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer
local UI = Player:WaitForChild("PlayerGui")
local LoadoutUI = UI:WaitForChild("MainMenu"):WaitForChild("LoadoutFrame")
local ContainerUI = LoadoutUI:WaitForChild("Container")
local BodyUI = ContainerUI:WaitForChild("Body")
local HotbarUI = BodyUI:WaitForChild("Hotbar")
local InventoryUI = BodyUI:WaitForChild("Inventory")
local SelectorUI = ContainerUI:WaitForChild("Selectors")
local OverlayFrame = LoadoutUI.Overlay

local Events = ReplicatedStorage.Events
local Components = Client.Components
local ItemTemplate = require(Components.ItemTemplate)
local Draggable = require(Components.Draggable)

local WeaponList = require(ReplicatedStorage.Assets.Weapons.List)
local WeaponInfo = require(ReplicatedStorage.Assets.Weapons.Data.Info)

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent, Out = Fusion.Children, Fusion.OnEvent, Fusion.Out
type UsedAs<T> = Fusion.UsedAs<T>

local Replica = require(Client.Packages.ReplicaClient)

type DragInfo = {
	id: string,
	mouseOffset: Vector2
}

local scope = scoped(Fusion, { ItemTemplate = ItemTemplate })

local hotbarState = scope:Value({})
local inventoryState = scope:Value({})

local mousePos = scope:Value()

local dropTargetIndex: Fusion.Value<number?> = scope:Value() -- which hotbar slot we're hovering
local currentlyDragging: Fusion.Value<DragInfo?> = scope:Value()

local setState

local function hotbarContains(name: string): boolean
	if not peek(hotbarState) then return false end
	
	for _, w in peek(hotbarState) do
		if w == name then return true end
	end
	return false
end

local function setHotbarSlot(idx: number, name: string): boolean
	if hotbarContains(name) then return false end
	local arr = table.clone(peek(hotbarState))
	arr[idx] = name
	hotbarState:set(arr)
	return true
end

local module = {
	Enabled = scope:Value(false)
}

function module.Enable()
	module.Enabled:set(true)
end

--TODO: add lazy updates
local function syncHotbar(data)
	hotbarState:set(table.clone(data.Hotbar or {}))
end

local function syncInventory(data)
	inventoryState:set(table.clone(data.Inventory or {}))
end

function module:Init(Properties)
	local replica = Properties.Replica
	
	--TODO: introduce writelibs
	
	Properties.trove:Add(replica:OnChange(function()
		syncHotbar(replica.Data)
		syncInventory(replica.Data)
	end))

	-- Initial load
	syncHotbar(replica.Data)
	syncInventory(replica.Data)

	mousePos:set(UserInputService:GetMouseLocation())
	table.insert(scope, UserInputService.InputChanged:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseMovement then
			mousePos:set(UserInputService:GetMouseLocation())
		end
	end))
	
	
	local Hotbar = scope:ForPairs(hotbarState, function(use, scope : Fusion.Scope, index : number, weaponName : any)
		return
			index,
			scope:New "Frame" {
				Name = `Slot_{index}`,
				LayoutOrder = index,
				Size = UDim2.fromOffset(64, 64),
				Parent = HotbarUI,

				[Children] = {
					scope:ItemTemplate { ItemName = weaponName },
				},

				[OnEvent "MouseEnter"] = function()
					dropTargetIndex:set(index :: number)
				end,

				[OnEvent "MouseLeave"] = function()
					if peek(dropTargetIndex) == index then dropTargetIndex:set(nil) end
				end,
			}
	end)

	local Inventory = scope:ForPairs(WeaponList, function(use, scope : Fusion.Scope, _, weaponName: string)
		local absPosVal: Fusion.Value<Vector2> = scope:Value(Vector2.zero)

		local scope = scope:innerScope({ Draggable = Draggable })
	
		local owned = scope:Computed(function(use) return use(inventoryState)[weaponName] ~= nil end)
		local selfDragInfo = scope:Computed(function(use)
			local info = use(currentlyDragging)
			return (info and info.id == weaponName) and info or nil
		end)
		

		local itemEntry = scope:Draggable {
			ID = weaponName,
			Name = weaponName,
			Parent = InventoryUI,
			Layout = { Size = UDim2.new(1, 0, 1, 0), OutAbsolutePosition = absPosVal },
			Dragging = { MousePosition = mousePos, SelfDragInfo = selfDragInfo, OverlayFrame = OverlayFrame },
			[Children] = ItemTemplate(scope, {
				ItemName = weaponName,
				ShowLevel = scope:Computed(function(use) return not (use(currentlyDragging) and use(currentlyDragging).id == weaponName) end),
				Level = scope:Computed(function(use) return use(owned) and use(inventoryState)[weaponName].Level or nil end),
				barSize = scope:Computed(function(use)
					if not use(owned) then return UDim2.new(0, 0, 0, 0) end
					local info = use(inventoryState)[weaponName]
					local ratio = (info.Exp or 0) / math.max(info.ExpRequired or 0, 1)
					return UDim2.new(ratio, 0, 1, 0)
				end),
				Disabled = scope:Computed(function(use) return not use(owned) end),
				OnMouseDown = function()
					if peek(currentlyDragging) ~= nil then return end
					if not peek(inventoryState)[weaponName] then return end
					local offset = peek(mousePos) - (peek(absPosVal) or Vector2.zero)
					currentlyDragging:set({ id = weaponName, mouseOffset = offset })
				end,
			})
		}
	
		return weaponName, itemEntry
	end)
	
	table.insert(scope, UserInputService.InputEnded:Connect(function(io)
		if io.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local dragInfo = peek(currentlyDragging)
		if not dragInfo then return end

		local slotIdx = peek(dropTargetIndex)
		if slotIdx and setHotbarSlot(slotIdx, dragInfo.id) then
			Events.EditHotbar:FireServer(peek(hotbarState))
		end

		currentlyDragging:set(nil)
	end))
	
	local gui = scope:Hydrate(LoadoutUI) {
		Visible = module.Enabled,
		
		[Children] = scope:Hydrate(ContainerUI) {
			[Children] = {
				
				scope:Hydrate(BodyUI) {
					[Children] = {
							scope:Hydrate(HotbarUI) {
							[Children] = Hotbar,
						},

						scope:Hydrate(InventoryUI) {
							[Children] = Inventory,
						},
					}
				},
				
				scope:Hydrate(SelectorUI) {
					[Children] = {
						scope:Hydrate(SelectorUI.ExitButton) {
							[OnEvent "MouseButton1Click"] = (function()
								module.Disable()
							end)
						},

					}
				}
			}
		}
	}
end


function module.Disable()
	module.Enabled:set(false)
	setState("MainMenu")
end

function module.SetStaticStateRef(ref)
	setState = ref
end

return module
