local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Events
local WeaponAssets = ReplicatedStorage.Assets.Weapons
local WeaponModels = WeaponAssets.Models
local ConfigModule = WeaponAssets.Data:WaitForChild("Config")
local BaseWeapon = require(script.Parent.BaseWeapon)

local CONFIG_REVISION_ATTRIBUTE = "DevConfigRevision"

local function LoadChildren(Parent: Instance): {}
	local Table = {}
	for _, Module in ipairs(Parent:GetChildren()) do
		if Module:IsA("ModuleScript") then
			Table[Module.Name] = require(Module)
		end
	end
	return Table
end

local DataManager = require(ServerScriptService.Data.DataManager)
local Weapons = LoadChildren(script.Parent.Weapons)

local WeaponSystem = {}
local PlayerInfo = {}
local playerConnections = {}
local playerDeployConnections = {}
local configReloadConnection: RBXScriptConnection? = nil

local function getWeaponModel(name: string)
	local model = WeaponModels:FindFirstChild(name)
	if model or name ~= "Boots" then return model end

	model = Instance.new("Model")
	model.Name = "Boots"
	local primary = Instance.new("Part")
	primary.Name = "Primary"
	primary.Size = Vector3.new(0.25, 0.25, 0.25)
	primary.Transparency = 1
	primary.CanCollide = false
	primary.CanQuery = false
	primary.CanTouch = false
	primary.Massless = true
	primary.Parent = model
	local attachment = Instance.new("Attachment")
	attachment.Name = "HandleAttachment"
	attachment.Parent = primary
	model.PrimaryPart = primary
	model.Parent = WeaponModels
	return model
end

local function getHotbarFolder(player: Player): Folder
	local Hotbar = player:FindFirstChild("Hotbar")
	if not Hotbar then
		Hotbar = Instance.new("Folder")
		Hotbar.Name = "Hotbar"
		Hotbar.Parent = player
	end
	return Hotbar :: Folder
end

local function clearWeapons(info)
	for _, Weapon in pairs(info.Hotbar) do
		Weapon:Destroy()
	end
	info.Hotbar = {}
	info.EquippedWeapon = nil
end

local function cleanupPlayerWeapons(player: Player, destroyFolder: boolean)
	local info = PlayerInfo[player]
	if not info then return end

	clearWeapons(info)
	if destroyFolder then
		info.Character = nil
	end

	local Hotbar = player:FindFirstChild("Hotbar")
	if destroyFolder and Hotbar then
		Hotbar:Destroy()
	elseif not destroyFolder then
		getHotbarFolder(player)
	end
end

local function getEquippedWeapon(player: Player)
	local info = PlayerInfo[player]
	return info and info.EquippedWeapon
end

local function isDeployedPlayer(player: Player, character: Model?): boolean
	return player:GetAttribute("Deployed") == true
		or (character ~= nil and character:GetAttribute("Deployed") == true)
end

local function canUseWeapon(player: Player): boolean
	local character = player.Character
	return character ~= nil
		and character.Parent ~= nil
		and isDeployedPlayer(player, character)
end

local function getWeaponSlotCost(weaponName: string): number
	local weaponConfig = BaseWeapon.GetConfig(weaponName)
	local cost = weaponConfig and weaponConfig.SLOT_COST
	return if typeof(cost) == "number" then math.clamp(cost, 1, 3) else 1
end

local function isValidHotbar(newHotbar: { string }, inventory): boolean
	local seen = {}
	local occupied = {}

	for slot = 1, 3 do
		local weaponName = newHotbar[slot]
		if weaponName == nil or weaponName == false then
			continue
		end

		if typeof(weaponName) ~= "string" or inventory[weaponName] == nil or seen[weaponName] then
			return false
		end

		local cost = getWeaponSlotCost(weaponName)
		if slot + cost - 1 > 3 then
			return false
		end

		for occupiedSlot = slot, slot + cost - 1 do
			if occupied[occupiedSlot] then
				return false
			end
			occupied[occupiedSlot] = true
		end

		seen[weaponName] = true
	end

	return true
end

local function rejectHotbarEdit(player: Player)
	local currentHotbar = DataManager.GetData(player, { "Hotbar" })
	if typeof(currentHotbar) == "table" then
		DataManager.SetData(player, { "Hotbar" }, table.clone(currentHotbar))
	end
end

function WeaponSystem._RemoveHotbar(player: Player)
	cleanupPlayerWeapons(player, true)
end

function WeaponSystem._EditHotbar(player: Player, newHotbar: { string })
	if typeof(newHotbar) ~= "table" then
		rejectHotbarEdit(player)
		return
	end

	local inventory = DataManager.GetData(player, { "Inventory" })
	if not inventory or not isValidHotbar(newHotbar, inventory) then
		rejectHotbarEdit(player)
		return
	end

	DataManager.SetData(player, { "Hotbar" }, newHotbar)
	WeaponSystem._ReloadHotbar(player)
end

function WeaponSystem._CreateHotbar(player: Player)
	local info = PlayerInfo[player]
	if not info then return end

	getHotbarFolder(player)
	clearWeapons(info)

	local savedHotbar = DataManager.GetData(player, { "Hotbar" })
	if typeof(savedHotbar) ~= "table" then
		return
	end

	for _, name in ipairs(savedHotbar) do
		if typeof(name) ~= "string" then
			continue
		end

		local weaponModule = Weapons[name]
		local weaponModel = getWeaponModel(name)

		if weaponModule and weaponModel then
			info.Hotbar[name] = weaponModule.new(weaponModel, player)
		end
	end
end

function WeaponSystem._ReloadHotbar(player: Player)
	local info = PlayerInfo[player]
	if not info or not player.Character then return end

	if not canUseWeapon(player) then
		cleanupPlayerWeapons(player, true)
		return
	end

	local equippedName = info.EquippedWeapon and info.EquippedWeapon.Name
	WeaponSystem._CreateHotbar(player)
	getHotbarFolder(player):SetAttribute(CONFIG_REVISION_ATTRIBUTE, ConfigModule:GetAttribute(CONFIG_REVISION_ATTRIBUTE))

	local Weapon = equippedName and info.Hotbar[equippedName]
	if Weapon then
		info.EquippedWeapon = Weapon
		Weapon:Equip()
		if not Weapon.Equipped then
			info.EquippedWeapon = nil
		end
	end
end

local function setupCharacter(player: Player, character: Model)
	PlayerInfo[player] = PlayerInfo[player] or { Hotbar = {} }
	local info = PlayerInfo[player]

	if not isDeployedPlayer(player, character) then
		WeaponSystem._RemoveHotbar(player)
		return
	end

	info.Character = character
	WeaponSystem._CreateHotbar(player)

	local rightArm = character:WaitForChild("Right Arm", 5)
	if not rightArm then
		warn(("[WeaponSystem] Right Arm missing for %s; server weapon grip skipped."):format(player.Name))
		return
	end

	local Grip = rightArm:FindFirstChild("Grip")
	if not Grip then
		Grip = Instance.new("Motor6D")
		Grip.Name = "Grip"
	end

	Grip.Part0 = rightArm
	Grip.Parent = rightArm

	player.CharacterRemoving:Once(function(removingCharacter)
		local currentInfo = PlayerInfo[player]
		if removingCharacter == character and currentInfo and currentInfo.Character == character then
			WeaponSystem._RemoveHotbar(player)
			if PlayerInfo[player] then
				PlayerInfo[player].Character = nil
			end
		end
	end)
end

local function setupPlayer(player: Player)
	if playerConnections[player] then return end

	PlayerInfo[player] = PlayerInfo[player] or { Hotbar = {} }
	playerConnections[player] = player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	playerDeployConnections[player] = player:GetAttributeChangedSignal("Deployed"):Connect(function()
		if player:GetAttribute("Deployed") ~= true then
			WeaponSystem._RemoveHotbar(player)
		end
	end)

	if player.Character then
		task.defer(setupCharacter, player, player.Character)
	end
end

function WeaponSystem:Init(_Properties)
	BaseWeapon.SetContext(_Properties)
	Remotes.EditHotbar.OnServerEvent:Connect(WeaponSystem._EditHotbar)
	Remotes.WeaponEvent.OnServerEvent:Connect(function(player, callback, ...)
		if callback == "Shoot" or typeof(callback) ~= "string" or not canUseWeapon(player) then return end
		local weapon = getEquippedWeapon(player)
		local method = weapon and weapon[callback]
		if method and weapon.Character == player.Character then
			method(weapon, ...)
		end
	end)

	local Projectile = _Properties.Projectile
	assert(Projectile, "WeaponSystem requires Projectile runtime")

	Projectile.FireRequested:Connect(function(player, packet)
		if not canUseWeapon(player) then return end

		local weapon = getEquippedWeapon(player)
		if not weapon then return end

		local validPacket = typeof(packet) == "table"
			and typeof(packet.spawns) == "table"
			and packet.weaponName == (weapon and weapon.Name)
			and weapon.Character == player.Character

		if weapon and weapon.Shoot and validPacket then
			weapon:Shoot(packet)
		end
	end)

	Projectile.UpdateRequested:Connect(function(player, id, position, velocity)
		if not canUseWeapon(player) then return end

		local weapon = getEquippedWeapon(player)
		if weapon and weapon.Character == player.Character and weapon.HandleProjectileUpdate then
			weapon:HandleProjectileUpdate(id, position, velocity)
		end
	end)

	if RunService:IsStudio() and not configReloadConnection then
		configReloadConnection = ConfigModule:GetAttributeChangedSignal(CONFIG_REVISION_ATTRIBUTE):Connect(function()
			BaseWeapon.ReloadConfig()
			for _, player in ipairs(Players:GetPlayers()) do
				WeaponSystem._ReloadHotbar(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if playerConnections[player] then
			playerConnections[player]:Disconnect()
			playerConnections[player] = nil
		end
		if playerDeployConnections[player] then
			playerDeployConnections[player]:Disconnect()
			playerDeployConnections[player] = nil
		end

		WeaponSystem._RemoveHotbar(player)
		PlayerInfo[player] = nil
	end)
end

Remotes.WeaponEquip.OnServerEvent:Connect(function(player, weaponName)
	if not canUseWeapon(player) then
		Remotes.WeaponEquip:FireClient(player, false, weaponName)
		return
	end

	local info = PlayerInfo[player]
	local Weapon = info and info.Hotbar[weaponName]

	if not Weapon then
		Remotes.WeaponEquip:FireClient(player, false, weaponName)
		return
	end

	if info.EquippedWeapon and info.EquippedWeapon.CanUnequip and not info.EquippedWeapon:CanUnequip() then
		Remotes.WeaponEquip:FireClient(player, false, weaponName)
		return
	end

	if info.EquippedWeapon then
		info.EquippedWeapon:Unequip()
	end

	info.EquippedWeapon = Weapon
	Weapon:Equip()
	if not Weapon.Equipped then
		info.EquippedWeapon = nil
		Remotes.WeaponEquip:FireClient(player, false, weaponName)
		return
	end

	Remotes.WeaponEquip:FireClient(player, true, weaponName)
end)

return WeaponSystem
