
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UI: PlayerGui = Player.PlayerGui
local Bindables = Client.Bindables
local Packages = ReplicatedStorage.Packages

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children = Fusion.Children

local Scene = Client.Assets.MenuScene :: Model
local CameraPositions = Scene.Cameras

local MainMenu = UI.MainMenu
local MenuFrame = MainMenu:WaitForChild("MenuFrame") :: Frame
local MenuList = MenuFrame:WaitForChild("MenuList") :: Frame
local IconFrame = MainMenu:WaitForChild("IconFrame") :: Frame

local StatsFrame = MenuFrame:WaitForChild("StatsFrame") :: Frame
local ExperienceBar = StatsFrame:WaitForChild("ExperienceBar") :: Frame
local InfoFrame = StatsFrame:WaitForChild("InfoFrame") :: Frame

local Loadout = require(script.Parent.Loadout)
local Shop = require(script.Parent.Shop)
local Crates = require(script.Parent.Crates)
local Remotes = ReplicatedStorage.Events

local ScreenGen = require(Client.Packages.Screen3D)
local Screen3D = ScreenGen.new(MainMenu, 5)

local MenuFrame3D = Screen3D:GetComponent3D(MenuFrame)
local IconFrame3D = Screen3D:GetComponent3D(IconFrame)

local MAX_ANGLE  = math.rad(2) -- radians
local MAX_OFFSET = 0.01        -- small because Screen3D adds depth
local VERTICAL_SCALE = 0.6

local module = {}
local scope = scoped(Fusion)

local MenuState, CameraOffset, CameraGoal = scope:Value("MainMenu"), scope:Value(), scope:Value()
local Exp, ExpRequired, Lvl = scope:Value(0), scope:Value(0), scope:Value(0)

local CameraSpring

local barSize = scope:Computed(function(use)
 	local req = use(ExpRequired)
	return UDim2.new(use(Exp) / (req == 0 and 1 or req), 0, 1, 0)
end)

scope:Hydrate(ExperienceBar.Fill) {
	Size = scope:Spring(barSize, 25, 1)
}

scope:Hydrate(InfoFrame) {
	[Children] = {
		scope:Hydrate(InfoFrame.Left) {
			Text = scope:Computed(function(use) return Player.Name .. " | " .. "Level " .. use(Lvl) .. " | " .. use(Exp) .. " XP" end)
		},
		scope:Hydrate(InfoFrame.Right) {
			Text = scope:Computed(function(use) return tostring(use(ExpRequired)) end)
		}
	}
}

local function setMenuState(newState)
	local oldState = peek(MenuState)
	if oldState == newState then return end
	MenuState:set(newState)

	if oldState == "Loadout" then
		Loadout.Disable()
	elseif oldState == "MainMenu" then
		MenuFrame.Visible = false
		IconFrame.Visible = false
	elseif oldState == "Shop" then
		Shop.Disable()
	end
	
	if newState == "Loadout" then
		Loadout.Enable()
	elseif newState == "MainMenu" then
		MenuFrame.Visible = true
		IconFrame.Visible = true
	elseif newState == "" then
		MenuFrame.Visible = false
		IconFrame.Visible = false
	elseif newState == "Shop" then
		Shop.Enable()
	end

	if CameraPositions:FindFirstChild(newState) then
		CameraGoal:set(CameraPositions[newState].CFrame)
	end
end

function module:Init(Properties)
	local Replica = Properties.Replica
	local trove = Properties.Trove or Properties.trove
	local MainMenuPart = CameraPositions:WaitForChild("MainMenu")
	
	setMenuState("MainMenu")
	
	CameraOffset:set(CFrame.identity)
	
	Loadout.SetStaticStateRef(setMenuState)
	Shop.SetStaticStateRef(setMenuState)
	
	--TODO: make this code better
	local map = workspace:FindFirstChild("Map")
	local cam = map and map:FindFirstChild("Camera")
	if cam then
		Scene:PivotTo(cam.CFrame)
	end
		
	module.Enable()
	Crates.Enable() --enable crate opening
	MenuFrame3D:Enable()
	IconFrame3D:Enable()
	

	trove:Connect(MenuList.DeployButton.MouseButton1Click, function()
		local success = Remotes.DeployRequest:InvokeServer()
		if success then
			Scene.Parent = ReplicatedStorage
			module.Disable()
			UI:WaitForChild("CharHUD").Enabled = true
			UI:WaitForChild("GameHUD").Enabled = true
		end
	end)

	trove:Connect(MenuList.LoadoutButton.MouseButton1Click, function()
		setMenuState("Loadout")
	end)
	
	trove:Connect(MenuList.ShopButton.MouseButton1Click, function()
		setMenuState("Shop")
	end)
	
	trove:Connect(Remotes.EnableMenu.OnClientEvent, module.Enable)
	trove:Connect(Bindables.EnableMenu.Event, module.Enable)
	
	
	local function applyFromReplica()
		Lvl:set(Replica.Data.Level)
		Exp:set(Replica.Data.Exp)
		ExpRequired:set(Replica.Data.ExpRequired)
	end
	
	
	applyFromReplica()
	trove:Add(Replica:OnChange(applyFromReplica))
	
	if map then
		trove:Connect(map.ChildAdded, function(child)
			if child.Name ~= "Camera" then return end
			Scene:PivotTo(child.CFrame)
		end)
	end
end

function module.Enable()
	setMenuState("MainMenu")
	
	Scene.Parent = workspace
	
	MainMenu.Enabled = true
	
	--TODO: get rid of this
	local gameHUD = UI:FindFirstChild("GameHUD")
	if gameHUD then
		gameHUD.Enabled = false
	end
	local charHUD = UI:FindFirstChild("CharHUD")
	if charHUD then
		charHUD.Enabled = false
	end

	Camera.CameraType = Enum.CameraType.Scriptable
	CameraGoal:set(CameraPositions:WaitForChild("MainMenu").CFrame)

	if CameraSpring then
		CameraSpring.oldestTask()
	end

	CameraSpring = scope:Spring(CameraGoal, 10, 0.9)
	
	RS:BindToRenderStep(
		"MenuCameraParallax",
		Enum.RenderPriority.Camera.Value - 1,
		function()
			if Camera.CameraType ~= Enum.CameraType.Scriptable then return end

			local viewport = Camera.ViewportSize
			local mouse = UserInputService:GetMouseLocation()

			local x = (mouse.X / viewport.X - 0.5) * 2
			local y = (mouse.Y / viewport.Y - 0.5) * 2
			y *= VERTICAL_SCALE

			-- circular clamp
			local mag = math.sqrt(x * x + y * y)
			if mag > 1 then
				x /= mag
				y /= mag
			end

			CameraOffset:set(
				CFrame.new(x * MAX_OFFSET, -y * MAX_OFFSET, 0) *
					CFrame.Angles(-y * MAX_ANGLE, -x * MAX_ANGLE, 0)
			)

			local offsetCF = peek(CameraOffset)
			local offsetPos = offsetCF.Position

			local cameraSpaceOffset = Camera.CFrame:VectorToObjectSpace(offsetPos)
			local cancelTranslation = CFrame.new(-cameraSpaceOffset)

			local UI_TILT_SCALE = 0.6  -- << increase for stronger tilt

			local tiltX = -y * MAX_ANGLE * UI_TILT_SCALE
			local tiltY = -x * MAX_ANGLE * UI_TILT_SCALE

			local uiTilt = CFrame.Angles(tiltX, tiltY, 0)

			-- cancel translation, then apply tilt
			local uiOffset = uiTilt * cancelTranslation

			MenuFrame3D.offset = uiOffset
			IconFrame3D.offset = uiOffset
		end
	)

	RS:BindToRenderStep(
		"MenuCameraApply",
		Enum.RenderPriority.Camera.Value,
		function()
			if CameraSpring then
				Camera.CFrame = peek(CameraSpring) * peek(CameraOffset)
			end
		end
	)
end

function module.Disable()
	MainMenu.Enabled = false
	
	if CameraSpring then
		CameraSpring.oldestTask()
		CameraSpring = nil
	end
	Camera.CameraType = Enum.CameraType.Custom
	
	setMenuState("")
	
	RS:UnbindFromRenderStep("MenuCameraParallax")
	RS:UnbindFromRenderStep("MenuCameraApply")
	
end

return module
