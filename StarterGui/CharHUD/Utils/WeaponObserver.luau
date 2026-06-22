local Players = game:GetService("Players")
local Client = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer

local Fusion = require(Client.Packages.Fusion)
local peek = Fusion.peek

local Bindables = Client:WaitForChild("Bindables")
local WeaponEquip = Bindables:WaitForChild("WeaponEquip")

local module = {}

local function findEquippedWeapon(weaponName: string): Tool?
	local character = Player.Character
	if not character then
		return nil
	end

	local instance = character:FindFirstChild(weaponName, true)
	if instance and instance:IsA("Tool") then
		return instance
	end

	return nil
end

function module.bindValue(localScope, parent: Instance, childName: string, setter: (any) -> ())
	local valueObject = parent:FindFirstChild(childName)
	if not valueObject or not valueObject:IsA("ValueBase") then
		return
	end

	local function update()
		setter(valueObject.Value)
	end

	update()
	table.insert(localScope, valueObject:GetPropertyChangedSignal("Value"):Connect(update))
end

function module.observe(scope: Fusion.Scope, callbacks: {
	onReset: (() -> ())?,
	onWeapon: ((Fusion.Scope, Tool) -> ())?,
	})
	local currentWeapon = scope:Value(nil :: Tool?)
	local bindingScope: Fusion.Scope? = nil

	local function cleanupBindingScope()
		if bindingScope then
			bindingScope:doCleanup()
			bindingScope = nil
		end
	end

	local function setWeapon(weapon: Tool?)
		cleanupBindingScope()

		if callbacks.onReset then
			callbacks.onReset()
		end

		if not weapon then
			return
		end

		local localScope = scope:innerScope()
		bindingScope = localScope

		if callbacks.onWeapon then
			callbacks.onWeapon(localScope, weapon)
		end

		table.insert(localScope, weapon.Destroying:Connect(function()
			if peek(currentWeapon) == weapon then
				currentWeapon:set(nil)
			end
		end))
	end

	table.insert(scope, scope:Observer(currentWeapon):onChange(function()
		setWeapon(peek(currentWeapon))
	end))

	table.insert(scope, WeaponEquip.Event:Connect(function(weaponName)
		currentWeapon:set(findEquippedWeapon(weaponName))
	end))

	table.insert(scope, Player.CharacterAdded:Connect(function()
		currentWeapon:set(nil)
	end))

	table.insert(scope, function()
		cleanupBindingScope()
	end)
end

return module