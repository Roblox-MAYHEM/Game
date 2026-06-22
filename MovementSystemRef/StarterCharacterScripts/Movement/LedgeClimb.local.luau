local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Humanoid.RootPart
local Head = Character:WaitForChild("Head")

local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Exclude
Params.FilterDescendantsInstances = { Character }

local Anim = Humanoid:LoadAnimation(script.Animation)

local Cooldown = false

--detect ledges to climb

local function DetectLedge()
	-- returns
	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		return false
	end

	if Humanoid:GetState() == Enum.HumanoidStateType.Climbing then
		return false
	end
	
	-- rays and vars

	local Forward = RootPart.CFrame.LookVector
	local HRPOrigin = RootPart.Position
	local HeadOrigin = Head.Position + Vector3.new(0, 2, 0)

	local HRPRay = workspace:Raycast(HRPOrigin, Forward * 5, Params)
	local HeadRay = workspace:Raycast(HeadOrigin, Forward * 5, Params)
	
	-- detect the damn ledge
	--(basically if body ray and not head ray then ledge, ez)
	if HRPRay and not HeadRay then
		--make sure your not tooo far down
		local ledgeHeight = HRPRay.Position.Y - RootPart.Position.Y

		if ledgeHeight > 5 then
			return false
		end
		-- after all odds, return the confirmation and ray
		return true, HRPRay
	end

	return false
end
--load the cammovement module and preload animation
game.ContentProvider:PreloadAsync({script.Animation})
local camanim = require("./CameraMovement")

-- Main stuff
local function ClimbLedge(rayData)
	--inital setup
	Cooldown = true
	script.Parent.WallClimb:SetAttribute("Climbing", false)
	task.wait()
	game["Run Service"].RenderStepped:Wait()
	--stability loop
	local Connection = game["Run Service"].RenderStepped:Connect(function()
		Character:SetAttribute("ShiftRotate",false)
		Humanoid.AutoRotate = false
	end)
	
	-- face the correct direction
	local surfaceNormal = rayData.Normal
	local climbUp = Vector3.new(0, 1, 0)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {Character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local verticalRay = workspace:Raycast(rayData.Position, Vector3.new(0, 6, 0), params)

	local climbHeight
	if verticalRay then
		climbHeight = (verticalRay.Position.Y - rayData.Position.Y) - 1
	else
		climbHeight = 2.4
	end

	local upPos = rayData.Position + Vector3.new(0, climbHeight, 0)
	local forwardPos = upPos - (surfaceNormal * 3)

	Anim.Looped = false
	RootPart.Anchored = true
	local stopped = false
	script.Ledge:Play()
	Anim:Play(nil, nil, 0)

	local faceCFrame = CFrame.lookAt(Character:GetPivot().Position, Character:GetPivot().Position - surfaceNormal)
	local START = (CFrame.new(rayData.Position + Vector3.new(0, climbHeight * 0.8, 0)) * faceCFrame.Rotation) * CFrame.new(0,0,0.5)
	
	-- TWEENX(tween so the player is not in the wall or somthing)
	
	local TweenX = game.TweenService:Create(Humanoid.RootPart,TweenInfo.new(0.08),{CFrame = (START)})
	TweenX:Play()
	TweenX.Completed:Wait()
	--wait for the animation to trigger climbing
	Anim:AdjustSpeed(1)
	Anim:GetMarkerReachedSignal("1"):Wait()
	
	camanim:BopDOWN(10,false)

	local FORWARD = (CFrame.new(upPos) * faceCFrame.Rotation) * CFrame.new(0,0.5,-0.6) * CFrame.Angles(math.rad(-25),0,0)
	local UP = FORWARD * CFrame.new(0,0,2)
	
	-- lerp to UP constant
	
	for i = 0, 1, 0.1 do
		if stopped or i > 0.20 then break end
		local LerpC = Character:GetPivot():Lerp(UP, i)
		Character:PivotTo(LerpC)
		task.wait()
	end
	
	-- lerp to FORWARD constant
	
	for i = 0, 1, 0.1 do
		if stopped or i > 0.30 then break end
		local LerpC = Character:GetPivot():Lerp(FORWARD, i)
		Character:PivotTo(LerpC)
		task.wait()
	end
	
	-- setup to quit stuff

	RootPart.Anchored = false
	Connection:Disconnect()
	task.delay(0.3,function()
		Cooldown = false
	end)
end

-- main rs loop

while game["Run Service"].RenderStepped:Wait() do
	--prevent climbing on ragdoll mode and stuff
	if script.Parent.Parent:WaitForChild("RagdollTrigger").Value then continue end
	Params.FilterDescendantsInstances = {Character,game.CollectionService:GetTagged("NODETECTION")}
	if Cooldown then
		continue
	end
	
	if script.Parent.Wallrunning.Value then continue end
	

	if script.Parent.WallClimb:GetAttribute("Climbing") == false then
		continue
	end
	

	local ledgeFound, rayData = DetectLedge()
	if not ledgeFound then
		continue
	end
	--setup a LOT of attributes
	script.Parent.Vault:GetAttribute("Vaultable",false)
	script.Parent.WallClimb:SetAttribute('Climbable',false)
	script.Parent.WallRunnable.Value = false
	Character:SetAttribute("ShiftRotate",false)
	Humanoid.AutoRotate = false
	script:SetAttribute("CLIMBINGLEDGE",true)
	-- i deleted the cutscene but i wanna preserve the code
	local Camera = workspace.CurrentCamera
	local isFirstPerson = false--,(Camera.CFrame.Position - Character.Head.Position).Magnitude < 1.4
	
	if isFirstPerson then
		script.Parent.Parent.Camera.Cutscene.Value = true
		script.Parent.Parent.Camera.LerpCutscene.Value = true
	end
	
	script.Parent.TightRope:SetAttribute('CanDo',false)
	
	-- call the main function
	
	ClimbLedge(rayData)
	
	-- set up everything back off
	
	script.Parent.Parent.Camera.Cutscene.Value = false
	script.Parent.Parent.Camera.LerpCutscene.Value = false
	
	Character:SetAttribute("ShiftRotate",true)
	Humanoid.AutoRotate = true
	task.wait(0.2)
	script.Parent.TightRope:SetAttribute('CanDo',true)
	script.Parent.WallRunnable.Value = true
	script.Parent.WallClimb:SetAttribute('Climbable',true)
	task.wait(0.2)
	script.Parent.Vault:GetAttribute("Vaultable",true)
	script:SetAttribute("CLIMBINGLEDGE",false)
end
