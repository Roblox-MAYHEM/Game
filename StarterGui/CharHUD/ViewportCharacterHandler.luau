local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Client			= game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children, OnEvent = Fusion.Children, Fusion.OnEvent

local OFFSET = CFrame.new(0,2.5,-7)

local ValidClasses = {
	["MeshPart"] = true; ["Part"] = true; ["Accoutrement"] = true;
	["Pants"] = true; ["Shirt"] = true;
	["Humanoid"] = true;
}

local RenderObjects = table.create(25)

local function RemoveObject(Object)
	local Clone = RenderObjects[Object]
	if not Clone then return nil end

	RenderObjects[Object] = nil
	if Clone.Parent:IsA("Accoutrement") then
		Clone.Parent:Destroy()
	else
		Clone:Destroy()
	end

	--print("Removed",Object)
end

local function AddObject(Object)
	if not ValidClasses[Object.ClassName] then
		return nil
	end

	-- Create clone, regardless of Archivable
	local a = Object.Archivable
	Object.Archivable = true
	local RenderClone = Object:Clone()
	Object.Archivable = a

	if Object.ClassName == "MeshPart" or Object.ClassName == "Part" then
		RenderObjects[Object] = RenderClone

	elseif Object:IsA("Accoutrement") then
		RenderObjects[Object.Handle] = RenderClone.Handle

	elseif Object.ClassName == "Humanoid" then
		--Disable all states. We only want it for clothing wrapping.
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.FallingDown,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Running,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Climbing,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.GettingUp,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Jumping,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Landed,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Flying,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Freefall,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Seated,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,	false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Dead,				false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Swimming,			false)
		RenderClone:SetStateEnabled(Enum.HumanoidStateType.Physics,				false)
		RenderClone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	--print("Added",Object)

	return RenderClone
end


local module = {}

function module:Init(Properties: {Scope : Fusion.Scope, UI : ScreenGui})
	local scope = Properties.Scope:innerScope()
	local UI = Properties.UI
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local ViewPort = Player.PlayerGui.CharHUD.ViewportFrame
	local Camera = Instance.new("Camera")
	table.insert(scope, Camera)

	ViewPort.CurrentCamera	= Camera
	
	table.clear(RenderObjects)
	ViewPort:ClearAllChildren()

	local Viewmodel = Instance.new("Model")
	Viewmodel.Name = "PlayerViewmodel"
	Viewmodel.Parent = ViewPort
	
	wait(2)

	local CharObjects = Character:GetDescendants()
	for i, Object in pairs(CharObjects) do
		local RenderClone = AddObject(Object)
		if RenderClone then
			RenderClone.Parent = Viewmodel
		end
	end

	table.insert(scope, Character.DescendantAdded:Connect(function(NewObject)
		local RenderClone = AddObject(NewObject)
		if RenderClone then
			RenderClone.Parent = Viewmodel
		end
	end))
	table.insert(scope, Character.DescendantRemoving:Connect(function(OldObject)
		RemoveObject(OldObject)
	end))
	
	table.insert(scope, RunService.Heartbeat:Connect(function()
		if (not Character:FindFirstChild("HumanoidRootPart")) or (not ViewPort.Visible) then
			return nil
		end

		-- Update camera
		Camera.CFrame = CFrame.new(Character.HumanoidRootPart.CFrame:ToWorldSpace(OFFSET).Position, Character.HumanoidRootPart.Position)

		-- Update objects
		for Original, Clone in pairs(RenderObjects) do
			if Original and Original.Parent then
				Clone.CFrame = Original.CFrame
			else
				RemoveObject(Original)
			end
		end
	end))
end

return module
