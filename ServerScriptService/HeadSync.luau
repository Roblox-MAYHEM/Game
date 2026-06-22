-- ServerScriptService / Modules / LookServer.lua
local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("LookEvent")

-- Cache minimal info per player (only what the server actually needs)
local playerData = {}
local playerConnections = {}

-- how far other players have to be to receive updates (studs)
local BROADCAST_DISTANCE = 80
local BROADCAST_DISTANCE_SQ = BROADCAST_DISTANCE * BROADCAST_DISTANCE

local function setupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart then
		return
	end

	local data = {
		Humanoid = humanoid,
		RootPart = rootPart,
		RigType = humanoid.RigType,
	}
	playerData[player] = data

	character.AncestryChanged:Connect(function(_, parent)
		if not parent and playerData[player] == data then
			playerData[player] = nil
		end
	end)
end

local function setupPlayer(player)
	if playerConnections[player] then return end

	playerConnections[player] = player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function module:Init()
	-- track players / characters
	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if playerConnections[player] then
			playerConnections[player]:Disconnect()
			playerConnections[player] = nil
		end

		playerData[player] = nil
	end)

	-- SERVER: receive from owner, forward to nearby clients
	-- client → server: Event:FireServer(dt, NeckC0, WaistC0, RSc0, LSc0)
	-- server → clients: Event:FireClient(target, ownerPlayer, rigType, NeckC0, WaistC0, RSc0, LSc0)
	Event.OnServerEvent:Connect(function(player, dt, NeckC0, WaistC0, RSc0, LSc0)
		local data = playerData[player]
		if not data or not data.RootPart then
			return
		end

		-- small sanity check to avoid NaN / bad packets:
		if typeof(NeckC0) ~= "CFrame" and NeckC0 ~= nil then return end
		if typeof(WaistC0) ~= "CFrame" and WaistC0 ~= nil then return end
		if typeof(RSc0) ~= "CFrame" and RSc0 ~= nil then return end
		if typeof(LSc0) ~= "CFrame" and LSc0 ~= nil then return end

		local sourcePos = data.RootPart.Position
		local rigType = data.RigType

		for other, otherData in pairs(playerData) do
			if other ~= player then
				local otherRoot = otherData.RootPart
				if otherRoot then
					-- squared magnitude to avoid sqrt every time
					local diff = otherRoot.Position - sourcePos
					local distSq = diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z

					if distSq <= BROADCAST_DISTANCE_SQ then
						Event:FireClient(other, player, rigType, NeckC0, WaistC0, RSc0, LSc0)
					end
				end
			end
		end
	end)
end

return module
