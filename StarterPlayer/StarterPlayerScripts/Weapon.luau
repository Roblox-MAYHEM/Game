local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local KEYNUMS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}

local CONFIG_REVISION_ATTRIBUTE = "DevConfigRevision"
local SCROLL_SENSITIVITY = 0.5
local EQUIP_COOLDOWN = 0.05
local HOTBAR_MODEL_TIMEOUT = 0.5
local HOTBAR_REVISION_TIMEOUT = 2

local function requireFresh(Module: ModuleScript)
	if not RunService:IsStudio() then
		return require(Module)
	end

	local Clone = Module:Clone()
	Clone.Name = Module.Name .. "_HotReload"
	Clone.Parent = Module.Parent

	local Result = require(Clone)
	Clone:Destroy()
	return Result
end

local WeaponSystem = {}
WeaponSystem.Priority = 2

function WeaponSystem:Init(properties)
	local Player = properties.Player
	local Shared = properties.Shared
	local Client = properties.Client
	local Replica = properties.Replica
	local RoundReplica = properties.RoundReplica

	local WeaponConfig = Shared.Assets.Weapons.Data:WaitForChild("Config")
	local Remotes = Shared.Events
	local Bindables = Client.Bindables

	local Trove = properties.Trove:Extend()
	local WeaponTrove = Trove:Extend()

	local PlayerHotbar = Player:WaitForChild("Hotbar")
	local WeaponFolder = Client.Weapon.Weapons

	local enabledPlayers = RoundReplica.Data.enabledPlrs == true
	local weaponModules = {}
	local hotbar = {}

	local equippedWeapon = nil
	local currentIndex = 1
	local firstPerson = true
	local equipDebounce = false

	local vHotbar = Trove:Add(Instance.new("Folder"))
	vHotbar.Name = "vHotbar"
	vHotbar.Parent = Player

	local function unequipWeapon()
		if equippedWeapon then
			equippedWeapon:Unequip()
			equippedWeapon = nil
		end

		Bindables.WeaponEquip:Fire(nil)
	end

	local function waitForServerHotbarRevision(revision)
		local deadline = os.clock() + HOTBAR_REVISION_TIMEOUT
		while revision and PlayerHotbar:GetAttribute(CONFIG_REVISION_ATTRIBUTE) ~= revision and os.clock() < deadline do
			task.wait()
		end
	end

	local function equipWeapon(Weapon, force)
		if not Weapon or Weapon == equippedWeapon or (equipDebounce and not force) then return end

		if not enabledPlayers then
			unequipWeapon()
			return
		end

		equipDebounce = not force
		if equipDebounce then
			task.delay(EQUIP_COOLDOWN, function()
				equipDebounce = false
			end)
		end

		if equippedWeapon then
			equippedWeapon:Unequip()
		end

		equippedWeapon = Weapon
		Bindables.WeaponEquip:Fire(Weapon.Name)
		Remotes.WeaponEquip:FireServer(Weapon.Name)

		Weapon:SetEnable(enabledPlayers)
		Weapon:ToggleView(firstPerson)
		Weapon:Equip()
	end

	local function rebuildHotbar(equippedName, equippedIndex, forceEquip)
		equippedWeapon = nil
		currentIndex = 1

		WeaponTrove:Clean()
		table.clear(hotbar)
		table.clear(weaponModules)

		for _, WeaponModule in ipairs(WeaponFolder:GetChildren()) do
			if WeaponModule:IsA("ModuleScript") and not WeaponModule.Name:find("_HotReload") then
				weaponModules[WeaponModule.Name] = requireFresh(WeaponModule)
			end
		end

		for _, weaponName in ipairs(Replica.Data.Hotbar) do
			local Model = (equippedName and Player.Character:WaitForChild(weaponName, HOTBAR_MODEL_TIMEOUT)) or PlayerHotbar:WaitForChild(weaponName, HOTBAR_MODEL_TIMEOUT)
			local Module = weaponModules[weaponName]

			if Model and Module then
				local Weapon = Module.new({
					Name = weaponName,
					WeaponModel = Model,
					Context = properties,
				})

				table.insert(hotbar, Weapon)
				WeaponTrove:Add(Weapon)
			end
		end

		if #hotbar == 0 then
			unequipWeapon()
			return
		end

		local targetIndex = equippedIndex and hotbar[equippedIndex] and equippedIndex or 1
		for index, Weapon in ipairs(hotbar) do
			if Weapon.Name == equippedName then
				targetIndex = index
				break
			end
		end

		currentIndex = targetIndex
		if enabledPlayers then
			equipWeapon(hotbar[targetIndex], forceEquip)
		else
			unequipWeapon()
		end
	end

	rebuildHotbar(nil, nil, true)

	if RunService:IsStudio() then
		local configReloadQueued = false

		Trove:Connect(WeaponConfig:GetAttributeChangedSignal(CONFIG_REVISION_ATTRIBUTE), function()
			if configReloadQueued then return end
			configReloadQueued = true

			task.delay(0.25, function()
				configReloadQueued = false
				waitForServerHotbarRevision(WeaponConfig:GetAttribute(CONFIG_REVISION_ATTRIBUTE))
				rebuildHotbar(equippedWeapon and equippedWeapon.Name or nil, currentIndex, true)
			end)
		end)
	end

	Trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then return end

		local index = table.find(KEYNUMS, input.KeyCode)
		if index and hotbar[index] then
			currentIndex = index
			equipWeapon(hotbar[index])
		end
	end)

	Trove:Connect(UserInputService.InputChanged, function(input, gameProcessed)
		if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseWheel or #hotbar == 0 then return end

		local scrollDelta = math.round(input.Position.Z * SCROLL_SENSITIVITY)
		if scrollDelta ~= 0 then
			currentIndex = math.clamp(currentIndex + scrollDelta, 1, #hotbar)
			equipWeapon(hotbar[currentIndex])
		end
	end)

	Trove:Connect(Remotes.WeaponEquip.OnClientEvent, function(accepted: boolean, weaponName: string)
		if accepted then return end

		if equippedWeapon and equippedWeapon.Name == weaponName then
			unequipWeapon()
		end
	end)

	Trove:Add(RoundReplica:OnSet({ "enabledPlrs" }, function(enabled: boolean, _)
		enabledPlayers = enabled == true

		if enabledPlayers then
			equipWeapon(hotbar[currentIndex], true)
		else
			unequipWeapon()
		end
	end))

	Trove:Connect(Bindables.ChangeCamState.Event, function(state: string)
		firstPerson = state == "FirstPerson"
		if equippedWeapon then equippedWeapon:ToggleView(firstPerson) end
	end)
end

return WeaponSystem
