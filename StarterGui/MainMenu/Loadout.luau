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
	mouseOffset: Vector2,
	source: string?,
	sourceSlot: number?,
}

local scope = scoped(Fusion, { ItemTemplate = ItemTemplate })

local hotbarState = scope:Value({})
local inventoryState = scope:Value({})

local mousePos = scope:Value()

local dropTargetIndex: Fusion.Value<number?> = scope:Value() -- which hotbar slot we're hovering
local currentlyDragging: Fusion.Value<DragInfo?> = scope:Value()

local setState
local MAX_SLOTS = 3
local SLOT_SIZE = 64
local SLOT_GAP = 8
local pendingHotbar = nil
local shakeToken = 0

local function getSlotCost(name: string): number
	local info = WeaponInfo[name]
	local cost = info and info.SLOT_COST
	return if typeof(cost) == "number" then math.clamp(cost, 1, 3) else 1
end

local function slotWidth(cost: number): number
	return SLOT_SIZE * cost + SLOT_GAP * (cost - 1)
end

local function normalizeHotbar(hotbar): { any }
	local slots = table.create(MAX_SLOTS, false)
	local explicit = false

	for slot = 1, MAX_SLOTS do
		if hotbar and hotbar[slot] == false then
			explicit = true
			break
		end
	end

	if explicit then
		for slot = 1, MAX_SLOTS do
			slots[slot] = if typeof(hotbar[slot]) == "string" then hotbar[slot] else false
		end
		return slots
	end

	local slot = 1
	for _, weaponName in ipairs(hotbar or {}) do
		if typeof(weaponName) == "string" and slot <= MAX_SLOTS then
			slots[slot] = weaponName
			slot += getSlotCost(weaponName)
		end
	end

	return slots
end

local function sameHotbar(a, b): boolean
	a = normalizeHotbar(a)
	b = normalizeHotbar(b)

	for slot = 1, MAX_SLOTS do
		if a[slot] ~= b[slot] then return false end
	end

	return true
end

local function clearWeapon(slots, name: string)
	for slot = 1, MAX_SLOTS do
		if slots[slot] == name then
			slots[slot] = false
		end
	end
end

local function spansOverlap(aStart: number, aCost: number, bStart: number, bCost: number): boolean
	return aStart <= bStart + bCost - 1 and bStart <= aStart + aCost - 1
end

local function dropStart(slot: number, name: string): number
	local cost = getSlotCost(name)
	return math.clamp(slot, 1, MAX_SLOTS - cost + 1)
end

local function shakeHotbar()
	shakeToken += 1
	local token = shakeToken
	local origin = HotbarUI.Position

	task.spawn(function()
		for _, x in ipairs({ -6, 6, -4, 4, 0 }) do
			if token ~= shakeToken then return end
			HotbarUI.Position = origin + UDim2.fromOffset(x, 0)
			task.wait(0.035)
		end
		HotbarUI.Position = origin
	end)
end

local function submitHotbar()
	local hotbar = normalizeHotbar(peek(hotbarState))
	pendingHotbar = hotbar
	Events.EditHotbar:FireServer(hotbar)
end

local function setHotbarSlot(idx: number, name: string): boolean
	local arr = normalizeHotbar(peek(hotbarState))
	local cost = getSlotCost(name)
	local start = dropStart(idx, name)

	clearWeapon(arr, name)

	for slot = 1, MAX_SLOTS do
		local weaponName = arr[slot]
		if typeof(weaponName) == "string" and spansOverlap(slot, getSlotCost(weaponName), start, cost) then
			arr[slot] = false
		end
	end

	arr[start] = name
	hotbarState:set(arr)
	return true
end

local function removeHotbarSlot(slot: number): boolean
	local arr = normalizeHotbar(peek(hotbarState))
	if typeof(arr[slot]) ~= "string" then return false end

	arr[slot] = false
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
	local nextHotbar = normalizeHotbar(data.Hotbar)
	if pendingHotbar then
		if not sameHotbar(nextHotbar, pendingHotbar) then
			shakeHotbar()
		end
		pendingHotbar = nil
	end
	hotbarState:set(nextHotbar)
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

	local dropPreviewState = scope:Computed(function(use)
		local dragInfo = use(currentlyDragging)
		local slot = use(dropTargetIndex)
		if not dragInfo or not slot then return nil end

		local start = dropStart(slot, dragInfo.id)
		return {
			Start = start,
			End = start + getSlotCost(dragInfo.id) - 1,
		}
	end)

	local function isCovered(hotbar, slot: number): boolean
		for start = 1, slot - 1 do
			local weaponName = hotbar[start]
			if typeof(weaponName) == "string" and slot <= start + getSlotCost(weaponName) - 1 then
				return true
			end
		end

		return false
	end

	local function isPreviewed(preview, slot: number, cost: number): boolean
		return preview ~= nil and slot <= preview.End and preview.Start <= slot + cost - 1
	end
	
	
	local Hotbar = scope:ForPairs(hotbarState, function(use, scope : Fusion.Scope, index : number, weaponName : any)
		local hotbar = use(hotbarState)
		if isCovered(hotbar, index) then
			return index, scope:New "Frame" {
				LayoutOrder = index,
				Size = UDim2.fromOffset(0, 0),
				Visible = false,
			}
		end

		local preview = use(dropPreviewState)
		local cost = if typeof(weaponName) == "string" then getSlotCost(weaponName) else 1
		local highlighted = isPreviewed(preview, index, cost)

		local function onSlotEnter()
			dropTargetIndex:set(index :: number)
		end

		local function onSlotLeave()
			if peek(dropTargetIndex) == index then dropTargetIndex:set(nil) end
		end

		if typeof(weaponName) ~= "string" then
			return index, scope:New "Frame" {
				Name = `Slot_{index}`,
				LayoutOrder = index,
				Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
				BackgroundColor3 = if highlighted then Color3.fromRGB(95, 120, 255) else Color3.fromRGB(20, 22, 28),
				BackgroundTransparency = if highlighted then 0.2 else 0.45,
				Parent = HotbarUI,

				[OnEvent "MouseEnter"] = onSlotEnter,
				[OnEvent "MouseLeave"] = onSlotLeave,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0, 6),
					},
					scope:New "UIStroke" {
						Color = if highlighted then Color3.fromRGB(180, 195, 255) else Color3.fromRGB(70, 74, 86),
						Transparency = if highlighted then 0.1 else 0.45,
					},
				},
			}
		end

		local absPosVal: Fusion.Value<Vector2> = scope:Value(Vector2.zero)
		local source = `Hotbar_{index}`
		local dragScope = scope:innerScope({ Draggable = Draggable })
		local selfDragInfo = dragScope:Computed(function(use)
			local info = use(currentlyDragging)
			return (info and info.source == source) and info or nil
		end)

		return
			index,
			dragScope:Draggable {
				ID = weaponName,
				Name = `Slot_{index}`,
				Parent = HotbarUI,
				Layout = {
					LayoutOrder = index,
					Size = UDim2.fromOffset(slotWidth(cost), SLOT_SIZE),
					OutAbsolutePosition = absPosVal,
				},
				Dragging = { MousePosition = mousePos, SelfDragInfo = selfDragInfo, OverlayFrame = OverlayFrame },

				[Children] = {
					scope:New "Frame" {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),

						[OnEvent "MouseEnter"] = onSlotEnter,
						[OnEvent "MouseLeave"] = onSlotLeave,

						[Children] = scope:ItemTemplate {
							ItemName = weaponName,
							SlotCost = cost,
							Size = UDim2.fromScale(1, 1),
							OnMouseDown = function()
								if peek(currentlyDragging) ~= nil then return end
								local offset = peek(mousePos) - (peek(absPosVal) or Vector2.zero)
								currentlyDragging:set({
									id = weaponName,
									mouseOffset = offset,
									source = source,
									sourceSlot = index,
								})
							end,
						},
					},
				}
			}
	end)

	local Inventory = scope:ForPairs(WeaponList, function(use, scope : Fusion.Scope, _, weaponName: string)
		local absPosVal: Fusion.Value<Vector2> = scope:Value(Vector2.zero)

		local scope = scope:innerScope({ Draggable = Draggable })
	
		local owned = scope:Computed(function(use) return use(inventoryState)[weaponName] ~= nil end)
		local selfDragInfo = scope:Computed(function(use)
			local info = use(currentlyDragging)
			return (info and info.id == weaponName and info.source == "Inventory") and info or nil
		end)
		

		local itemEntry = scope:Draggable {
			ID = weaponName,
			Name = weaponName,
			Parent = InventoryUI,
			Layout = { Size = UDim2.fromOffset(slotWidth(getSlotCost(weaponName)), SLOT_SIZE), OutAbsolutePosition = absPosVal },
			Dragging = { MousePosition = mousePos, SelfDragInfo = selfDragInfo, OverlayFrame = OverlayFrame },
			[Children] = ItemTemplate(scope, {
				ItemName = weaponName,
				SlotCost = getSlotCost(weaponName),
				ShowLevel = scope:Computed(function(use) return not (use(currentlyDragging) and use(currentlyDragging).id == weaponName) end),
				Level = scope:Computed(function(use) return use(owned) and use(inventoryState)[weaponName].Level or nil end),
				barSize = scope:Computed(function(use)
					if not use(owned) then return UDim2.new(0, 0, 0, 0) end
					local info = use(inventoryState)[weaponName]
					local ratio = (info.Exp or 0) / math.max(info.ExpRequired or 0, 1)
					return UDim2.new(ratio, 0, 1, 0)
				end),
				Disabled = scope:Computed(function(use) return not use(owned) end),
				Locked = scope:Computed(function(use) return not use(owned) end),
				OnMouseDown = function()
					if peek(currentlyDragging) ~= nil then return end
					if not peek(inventoryState)[weaponName] then return end
					local offset = peek(mousePos) - (peek(absPosVal) or Vector2.zero)
					currentlyDragging:set({ id = weaponName, mouseOffset = offset, source = "Inventory" })
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
		local changed = false

		if slotIdx then
			changed = setHotbarSlot(slotIdx, dragInfo.id)
		elseif dragInfo.sourceSlot then
			changed = removeHotbarSlot(dragInfo.sourceSlot)
		end

		if changed then
			submitHotbar()
		elseif dragInfo.sourceSlot then
			shakeHotbar()
		end

		dropTargetIndex:set(nil)
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
