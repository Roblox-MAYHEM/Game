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

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui, Replica : ReplicaClient.Replica})
	local scope = Properties.Scope:innerScope({ItemTemplate = ItemTemplate})
	local UI = Properties.UI
	
	local equippedItem = scope:Value()
	local hotbar = scope:Value(Properties.Replica.Data.Hotbar)
	
	table.insert(scope, Bindables.WeaponEquip.Event:Connect(function(weaponName)
		equippedItem:set(weaponName) 
	end))
	
	local root = scope:Hydrate(HotbarUI) {
		[Children] = scope:ForPairs(hotbar, function(use, scope, index, weaponName)
			return index, scope:ItemTemplate({
				LayoutOrder = index,
				ItemName = weaponName,
				Size = scope:Computed(function(use)
					return if use(equippedItem) == weaponName then UDim2.new(1.1, 0, 1.1, 0) else UDim2.new(1, 0, 1, 0)
				end),
				Disabled = not WeaponInfo[weaponName],
			})
		end)
	}
end

return module
