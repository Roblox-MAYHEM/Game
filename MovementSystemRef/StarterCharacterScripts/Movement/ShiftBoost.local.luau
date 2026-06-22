local Player = game.Players.LocalPlayer
local GUI = Player.PlayerGui.ParkourUI.ShiftBoost

local Character = Player.Character
local Humanoid = Character:FindFirstChildOfClass('Humanoid')

local Essential = game.ReplicatedStorage.Modules:WaitForChild('Essential')
local InputManager = require(Essential:WaitForChild('Services'):WaitForChild('InputHandler'))

local inputObject = InputManager.CreateInputObject()

local Cooldown = false

local MoveDirection = ("N")

function UpdateMoveDirection()
	local W = Character.HumanoidRootPart.CFrame.LookVector
	local S = -Character.HumanoidRootPart.CFrame.LookVector
	local A = -Character.HumanoidRootPart.CFrame.RightVector
	local D = Character.HumanoidRootPart.CFrame.RightVector

	if Humanoid.MoveDirection:Dot(W) >= 0.75 then
		MoveDirection = ("W")
	elseif Humanoid.MoveDirection:Dot(S) >= 0.75 then
		MoveDirection = ("S")
	elseif Humanoid.MoveDirection:Dot(A) >= 0.75 then
		MoveDirection = ("A")
	elseif Humanoid.MoveDirection:Dot(D) >= 0.75 then
		MoveDirection = ("D")
	else
		MoveDirection = ("N")
	end
end

function Dash()
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then return end
	UpdateMoveDirection()
	print('dash')
	if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then return end
	local Vector = Humanoid.RootPart.CFrame.LookVector

	if MoveDirection == "N" then
		MoveDirection = "W"
	end	
	if MoveDirection == ("W") then

		Vector = Humanoid.RootPart.CFrame.LookVector * 2
	elseif MoveDirection == ("A") then

		Vector = -Humanoid.RootPart.CFrame.RightVector * 2
	elseif MoveDirection == ("S") then
		Vector = -Humanoid.RootPart.CFrame.LookVector * 2
	elseif MoveDirection == ("D") then
		Vector = Humanoid.RootPart.CFrame.RightVector * 2
	end

	if MoveDirection == "N" then return end

	local MULTIPLICATION_AMOUNT = 75

	--Sound:Play()

	local BodyVelo = Instance.new('BodyVelocity',Humanoid.RootPart)
	BodyVelo.Name = "SHIFT_BoostDash"

	BodyVelo.Velocity = Vector * MULTIPLICATION_AMOUNT
	BodyVelo.MaxForce = Vector3.new(1,0,1) * 200000
	
	game.Debris:AddItem(BodyVelo,0.1)
end


function Main()
	if Cooldown then return end
	Cooldown = true
	local Tween1 = game.TweenService:Create(GUI.Frame,TweenInfo.new(0.1),{BackgroundTransparency = 0})
	local Tween2 = game.TweenService:Create(GUI.Frame.Bar,TweenInfo.new(0.1),{BackgroundTransparency = 0})
	Tween1:Play()
	Tween2:Play()
	
	Dash()
	script.Parent.Boosting.Value = true
	local BarTween = game.TweenService:Create(GUI.Frame.Bar,TweenInfo.new(0.4),{Size = UDim2.new(0 / 100,0,1,0)})
	BarTween:Play()
	BarTween.Completed:Wait()
	script.Parent.Boosting.Value = false
	task.wait(0.2)


	local Tween1 = game.TweenService:Create(GUI.Frame,TweenInfo.new(0.25),{BackgroundTransparency = 1})
	local Tween2 = game.TweenService:Create(GUI.Frame.Bar,TweenInfo.new(0.25),{BackgroundTransparency = 1})
	Tween1:Play()
	Tween2:Play()
	Tween2.Completed:Wait()
	GUI.Frame.Bar.Size = UDim2.new(1,0,1,0)
	wait(0.2)
	Cooldown = false
end

inputObject:ConnectFunctionToKey(Enum.KeyCode.LeftShift,true,Main)
inputObject:ConnectFunctionToKey(Enum.KeyCode.ButtonR2,true,Main)
inputObject:ConnectFunctionToKey(Enum.KeyCode.ButtonY,true,Main)