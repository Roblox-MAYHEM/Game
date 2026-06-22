local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")
local Player = game:GetService("Players").LocalPlayer
local UI = Player.PlayerGui

local Fusion = require(Client:WaitForChild("Packages"):WaitForChild("Fusion"))
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local Libraries = Client.Libraries
local Events	= ReplicatedStorage.Events
local Bindables	= Client.Bindables

local Camera = game.Workspace.CurrentCamera
local WeaponInfo = require(ReplicatedStorage.Assets.Weapons.Data.Info)
local ItemTemplate = require(Client.Components.ItemTemplate)

local ReplicaClient = require(Client.Packages.ReplicaClient)

local HotbarUI = UI.CharHUD.HotbarFrame

local module = {}
local MAX_SLOTS = 3
local SLOT_SIZE = 64
local SLOT_GAP = 8

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

local function isCovered(hotbar, slot: number): boolean
	for start = 1, slot - 1 do
		local weaponName = hotbar[start]
		if typeof(weaponName) == "string" and slot <= start + getSlotCost(weaponName) - 1 then
			return true
		end
	end

	return false
end

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui, Replica : ReplicaClient.Replica})
	local scope = Properties.Scope:innerScope({ItemTemplate = ItemTemplate})
	local UI = Properties.UI
	
	local equippedItem = scope:Value()
	local hotbar = scope:Value(normalizeHotbar(Properties.Replica.Data.Hotbar))
	
	table.insert(scope, Bindables.WeaponEquip.Event:Connect(function(weaponName)
		equippedItem:set(weaponName) 
	end))

	table.insert(scope, Properties.Replica:OnChange(function()
		hotbar:set(normalizeHotbar(Properties.Replica.Data.Hotbar))
	end))
	
	local root = scope:Hydrate(HotbarUI) {
		[Children] = scope:ForPairs(hotbar, function(use, scope, index, weaponName)
			local hotbarNow = use(hotbar)
			if isCovered(hotbarNow, index) then
				return index, scope:New "Frame" {
					LayoutOrder = index,
					Size = UDim2.fromOffset(0, 0),
					Visible = false,
				}
			end

			if typeof(weaponName) ~= "string" then
				return index, scope:New "Frame" {
					Name = `Slot_{index}`,
					LayoutOrder = index,
					Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
					BackgroundColor3 = Color3.fromRGB(20, 22, 28),
					BackgroundTransparency = 0.45,

					[Children] = {
						scope:New "UICorner" {
							CornerRadius = UDim.new(0, 6),
						},
						scope:New "UIStroke" {
							Color = Color3.fromRGB(70, 74, 86),
							Transparency = 0.45,
						},
					},
				}
			end

			return index, scope:ItemTemplate({
				LayoutOrder = index,
				ItemName = weaponName,
				SlotCost = getSlotCost(weaponName),
				Size = scope:Computed(function(use)
					local scale = if use(equippedItem) == weaponName then 1.1 else 1
					local width = slotWidth(getSlotCost(weaponName))
					return UDim2.fromOffset(width * scale, SLOT_SIZE * scale)
				end),
				Disabled = not WeaponInfo[weaponName],
			})
		end)
	}
end

return module
