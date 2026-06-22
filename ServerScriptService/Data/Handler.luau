local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.Events

local ProfileStore = require(ServerStorage.Libraries.ProfileStore)
local ReplicaServer = require(ServerStorage.Libraries.ReplicaServer)
local PlayerDataToken = ReplicaServer.Token("PlayerData")

local function GetStoreName() : "Test" | "_Live"
	return RunService:IsStudio() and "Test" or "_Live"
end

local Template = require(script.Parent.Template)

local PlayerStore = ProfileStore.New(GetStoreName(), Template)
local DataManager = require(ServerScriptService.Data.DataManager)

local WeaponsList = require(ReplicatedStorage.Assets.Weapons.List)

local module = {}

local STARTER_WEAPON_DATA = {
	Level = 1,
	Exp = 0,
	ExpRequired = 100,
}

local function ensureWeapon(data, weaponName: string)
	data.Inventory = data.Inventory or {}
	data.Inventory[weaponName] = data.Inventory[weaponName] or table.clone(STARTER_WEAPON_DATA)
end

local function CleanupPlayerReplica(plr: Player)
	local replica = DataManager.DataReplica[plr]
	if replica then
		replica:Destroy()
		DataManager.DataReplica[plr] = nil
	end
end

--add leaderstats and synchronize player data
local function Initialize(plr : Player, profile : typeof(PlayerStore:StartSessionAsync()))
	--debug

	CleanupPlayerReplica(plr)

	DataManager.DataReplica[plr] = ReplicaServer.New({
		Token = PlayerDataToken,
		Tags = { UserId = plr.UserId },
		Data = profile.Data,
	})
	DataManager.DataReplica[plr]:Replicate()
end


--Creates and stores profile
local function PlayerAdded(plr : Player)
	--Start a new profile session
	local profile = PlayerStore:StartSessionAsync("Player_" .. plr.UserId, {
		Cancel = function()
			return plr.Parent ~= Players
		end,
	})

	--Sanity check to ensure profile exists
	if profile ~= nil then

		profile:AddUserId(plr.UserId) --GDPR compliance
		profile:Reconcile() -- Fill in missing variables from Template
		ensureWeapon(profile.Data, "ClassicSword")
		ensureWeapon(profile.Data, "GreatSword")

		-- handles session locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[plr] = nil
			CleanupPlayerReplica(plr)
			if plr.Parent == Players then
				plr:Kick("Data error occured. Please rejoin.")
			end
		end) 

		if plr.Parent == Players then

			DataManager.Profiles[plr] = profile
			Initialize(plr, profile)

		else
			profile:EndSession()
		end

	else
		--server shuts down while player joining
		plr:Kick("Data error occured. Please rejoin.")
	end

end

function module:Init()
	--Early joiners
	for _, plr in Players:GetPlayers() do
		task.spawn(PlayerAdded, plr)
	end

	Players.PlayerAdded:Connect(PlayerAdded)

	Players.PlayerRemoving:Connect(function(plr)
		local profile = DataManager.Profiles[plr]

		if profile then
			profile:EndSession()
		end
		DataManager.Profiles[plr] = nil
		CleanupPlayerReplica(plr)
	end)
end

return module
