local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local module = {}

local Event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("LookEvent")

local SEND_INTERVAL = 1/4
local LOCAL_UPDATE_INTERVAL = 1/30
local REMOTE_UPDATE_INTERVAL = 1/30
local accumulated = 0

local HeadHorFactor = 0.8
local HeadVertFactor = 0.7

local TorsoHorFactor = 0.8
local TorsoVertFactor = 0.7

local UpdateSpeed = 0.5

-- remote tween config
local REMOTE_TWEEN_TIME = 0.25 -- seconds to blend between server snapshots
local MAX_REMOTE_UPDATES_PER_FRAME = 4 -- cap work per frame

-- cache of joints + tween state per remote player (on THIS client)
local remoteJointCache = {} :: { [Player]: any }
local playerConnections = {} :: { [Player]: RBXScriptConnection }

-- list of players that currently have active tweens
local remoteActiveList = {} :: {Player}
local remoteActiveMap = {} :: { [Player]: boolean }
local remoteActiveIndex = 0
local remoteUpdateAccum = 0

local function addActivePlayer(player: Player)
	if not remoteActiveMap[player] then
		table.insert(remoteActiveList, player)
		remoteActiveMap[player] = true
	end
end

local function removeActivePlayer(player: Player)
	if not remoteActiveMap[player] then return end
	remoteActiveMap[player] = nil

	-- remove from list (swap with last to keep O(1))
	for i = 1, #remoteActiveList do
		if remoteActiveList[i] == player then
			local last = remoteActiveList[#remoteActiveList]
			remoteActiveList[i] = last
			remoteActiveList[#remoteActiveList] = nil

			-- keep the round-robin index consistent
			if remoteActiveIndex > #remoteActiveList then
				remoteActiveIndex = #remoteActiveList
			end
			break
		end
	end
end

--////////// Remote joint setup (for *other* players on this client) //////////--

local function setupRemoteCharacter(player: Player, character: Model)
	if player == LocalPlayer then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or not head then
		return
	end

	local data: any = remoteJointCache[player]
	if not data then
		data = {}
		remoteJointCache[player] = data
	end

	data.Humanoid = humanoid
	data.RigType = humanoid.RigType

	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local torso = character:FindFirstChild("Torso")
		if not torso then return end
		data.Neck = torso:FindFirstChild("Neck")
		data.RightShoulder = torso:FindFirstChild("Right Shoulder")
		data.LeftShoulder = torso:FindFirstChild("Left Shoulder")
	else
		local upperTorso = character:FindFirstChild("UpperTorso")
		if not upperTorso then return end
		data.Neck = head:FindFirstChild("Neck")
		data.Waist = upperTorso:FindFirstChild("Waist")
	end

	-- clear any old tween state
	data.TweenStartTime = nil
	data.TweenDuration = nil
	data.StartNeckC0 = nil
	data.TargetNeckC0 = nil
	data.StartWaistC0 = nil
	data.TargetWaistC0 = nil
	data.StartRSC0 = nil
	data.TargetRSC0 = nil
	data.StartLSC0 = nil
	data.TargetLSC0 = nil

	character.AncestryChanged:Connect(function(_, parent)
		if not parent and remoteJointCache[player] == data then
			remoteJointCache[player] = nil
			removeActivePlayer(player)
		end
	end)
end

local function setupRemotePlayer(plr: Player)
	if playerConnections[plr] then return end

	if plr ~= LocalPlayer and plr.Character then
		setupRemoteCharacter(plr, plr.Character)
	end

	playerConnections[plr] = plr.CharacterAdded:Connect(function(char)
		setupRemoteCharacter(plr, char)
	end)
end

-- initial hookup
for _, plr in ipairs(Players:GetPlayers()) do
	setupRemotePlayer(plr)
end

Players.PlayerAdded:Connect(setupRemotePlayer)

Players.PlayerRemoving:Connect(function(plr)
	if playerConnections[plr] then
		playerConnections[plr]:Disconnect()
		playerConnections[plr] = nil
	end

	remoteJointCache[plr] = nil
	removeActivePlayer(plr)
end)

--////////// Receive from server: set tween targets, mark player active //////////--

Event.OnClientEvent:Connect(function(sourcePlayer: Player, rigType, NeckC0, WaistC0, RSc0, LSc0)
	-- Ignore our own data; we already control our own joints locally
	if sourcePlayer == LocalPlayer then
		return
	end

	local data = remoteJointCache[sourcePlayer]
	if not data or not data.Humanoid then
		return
	end

	local now = os.clock()

	-- duration per packet (can be less than SEND_INTERVAL if you want snappier)
	data.TweenStartTime = now
	data.TweenDuration = REMOTE_TWEEN_TIME

	-- we always start from current visual pose to avoid snapping
	if NeckC0 and data.Neck then
		data.StartNeckC0 = data.Neck.C0
		data.TargetNeckC0 = NeckC0
	end

	if RSc0 and data.RightShoulder then
		data.StartRSC0 = data.RightShoulder.C0
		data.TargetRSC0 = RSc0
	end

	if LSc0 and data.LeftShoulder then
		data.StartLSC0 = data.LeftShoulder.C0
		data.TargetLSC0 = LSc0
	end

	if WaistC0 and data.Waist then
		data.StartWaistC0 = data.Waist.C0
		data.TargetWaistC0 = WaistC0
	end

	addActivePlayer(sourcePlayer)
end)

--////////// Time-sliced tween loop for remote players //////////--

RunService.RenderStepped:Connect(function(dt)
	local count = #remoteActiveList
	if count == 0 then
		return
	end

	remoteUpdateAccum += dt
	if remoteUpdateAccum < REMOTE_UPDATE_INTERVAL then
		return
	end
	remoteUpdateAccum = 0

	local now = os.clock()

	local iterations = math.min(MAX_REMOTE_UPDATES_PER_FRAME, count)
	for _ = 1, iterations do
		if count == 0 then break end

		remoteActiveIndex += 1
		if remoteActiveIndex > count then
			remoteActiveIndex = 1
		end

		local player = remoteActiveList[remoteActiveIndex]
		local data = remoteJointCache[player]

		if not data or not data.TweenStartTime or not data.TweenDuration then
			removeActivePlayer(player)
			count = #remoteActiveList
			if count == 0 then break end
		else
			local t = (now - data.TweenStartTime) / data.TweenDuration
			if t >= 1 then
				-- snap to target and deactivate
				if data.Neck and data.TargetNeckC0 then
					data.Neck.C0 = data.TargetNeckC0
				end
				if data.Waist and data.TargetWaistC0 then
					data.Waist.C0 = data.TargetWaistC0
				end
				if data.RightShoulder and data.TargetRSC0 then
					data.RightShoulder.C0 = data.TargetRSC0
				end
				if data.LeftShoulder and data.TargetLSC0 then
					data.LeftShoulder.C0 = data.TargetLSC0
				end

				data.TweenStartTime = nil
				data.TweenDuration = nil

				removeActivePlayer(player)
				count = #remoteActiveList
				if count == 0 then break end
			else
				-- tween in-place
				local alpha = t

				if data.Neck and data.StartNeckC0 and data.TargetNeckC0 then
					data.Neck.C0 = data.StartNeckC0:Lerp(data.TargetNeckC0, alpha)
				end
				if data.Waist and data.StartWaistC0 and data.TargetWaistC0 then
					data.Waist.C0 = data.StartWaistC0:Lerp(data.TargetWaistC0, alpha)
				end
				if data.RightShoulder and data.StartRSC0 and data.TargetRSC0 then
					data.RightShoulder.C0 = data.StartRSC0:Lerp(data.TargetRSC0, alpha)
				end
				if data.LeftShoulder and data.StartLSC0 and data.TargetLSC0 then
					data.LeftShoulder.C0 = data.StartLSC0:Lerp(data.TargetLSC0, alpha)
				end
			end
		end
	end
end)

--////////// Local player control (same concept as before) //////////--

function module:Init(Properties)
	local Character = Properties.Character
	local Player = Properties.Player
	local trove = Properties.Trove:Extend()

	local Camera = workspace:WaitForChild("Camera")
	local Mouse = Player:GetMouse()
	local Head = Character:WaitForChild("Head")
	local Humanoid = Character:WaitForChild("Humanoid")
	local RootPart = Character:WaitForChild("HumanoidRootPart")

	local Torso, Waist, Neck, WaistOrgnC0
	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		Torso = Character:WaitForChild("Torso")
		Neck = Torso:WaitForChild("Neck")
	else
		Torso = Character:WaitForChild("UpperTorso")
		Neck = Head:WaitForChild("Neck")
		Waist = Torso:WaitForChild("Waist")
		WaistOrgnC0 = Waist.C0
	end

	local RightShoulder = Torso:WaitForChild("Right Shoulder")
	local LeftShoulder = Torso:WaitForChild("Left Shoulder")

	local Ang = CFrame.Angles
	local aSin = math.asin

	local NeckOrgnC0 = Neck.C0

	local Dist, Diff, TorsoPosition

	local function computeDistAndDiff()
		local headPos = Head.Position
		local camPos = Camera.CFrame.Position

		if Humanoid.RigType == Enum.HumanoidRigType.R6 then
			Dist = (headPos - camPos).Magnitude
			Diff = headPos.Y - camPos.Y
		else
			TorsoPosition = Torso.Position
			Dist = (headPos - camPos).Magnitude
			Diff = headPos.Y - camPos.Y
		end
	end

	local function updateChar()
		if not Dist or Dist == 0 then
			return
		end

		local headPos = Head.Position
		local camPos = Camera.CFrame.Position
		local torsoLook = Torso.CFrame.LookVector
		local unitToCam = (headPos - camPos).Unit

		if Humanoid.RigType == Enum.HumanoidRigType.R6 then
			Neck.C0 = Neck.C0:Lerp(
				NeckOrgnC0 *
					Ang(
						-(aSin(Diff / Dist) * HeadVertFactor),
						0,
						-(unitToCam:Cross(torsoLook)).Y * HeadHorFactor
					),
				UpdateSpeed / 2
			)

			local mouseOriginPos = Mouse.Origin.Position
			local xRot = -(math.asin((mouseOriginPos - camPos).Unit.Y)) * -1

			local _, yR, zR = RightShoulder.C0:ToEulerAnglesXYZ()
			RightShoulder.C0 = CFrame.new(RightShoulder.C0.Position) * CFrame.Angles(xRot, yR, zR)

			local _, yL, zL = LeftShoulder.C0:ToEulerAnglesXYZ()
			LeftShoulder.C0 = CFrame.new(LeftShoulder.C0.Position) * CFrame.Angles(xRot, yL, zL)

		else -- R15
			Neck.C0 = Neck.C0:Lerp(
				NeckOrgnC0 *
					Ang(
						(aSin(Diff / Dist) * (HeadVertFactor / 2)),
						-((unitToCam:Cross(torsoLook)).Y * (HeadHorFactor / 2)),
						0
					),
				UpdateSpeed / 2
			)

			local torsoUnitToCam = (TorsoPosition - camPos).Unit
			Waist.C0 = Waist.C0:Lerp(
				WaistOrgnC0 *
					Ang(
						(aSin(Diff / Dist) * (TorsoVertFactor / 2)),
						-((torsoUnitToCam:Cross(torsoLook)).Y * (TorsoHorFactor / 2)),
						0
					),
				UpdateSpeed / 2
			)
		end
	end

	local localUpdateAccum = 0

	trove:Connect(RunService.RenderStepped, function(deltaTime)
		localUpdateAccum += deltaTime
		if localUpdateAccum >= LOCAL_UPDATE_INTERVAL then
			computeDistAndDiff()
			updateChar()
			localUpdateAccum = 0
		end

		accumulated += deltaTime
		if accumulated >= SEND_INTERVAL then
			if Humanoid.RigType == Enum.HumanoidRigType.R6 then
				Event:FireServer(accumulated, Neck.C0, nil, RightShoulder.C0, LeftShoulder.C0)
			elseif Humanoid.RigType == Enum.HumanoidRigType.R15
				and Player.CameraMode == Enum.CameraMode.LockFirstPerson
			then
				Event:FireServer(accumulated, Neck.C0, Waist.C0)
			end
			accumulated = 0
		end
	end)
end

return module
