local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local char = script.Parent
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local rollKey = Enum.KeyCode.LeftShift
local minFallSpeed = 180
local lethalFallSpeed = 250
local stunTime = 3
local rollWindow = 0.4

local canRoll = true
local isRolling = false
local rollQueued = false
local rollAnim

local fallStartY
local isFalling = false
local stunned = false

local function stunPlayer()
	if stunned then return end
	stunned = true

	local oldWalk = humanoid.WalkSpeed
	local oldJump = humanoid.JumpPower

	script.Parent.Movement.Momentum.Enabled = false
	for _, Anim in humanoid:GetPlayingAnimationTracks() do
		Anim:Stop()
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	char:SetAttribute("ShiftEnabled",false)
	
	local anim = humanoid:LoadAnimation(script.Stun)
	anim:Play()
	
	anim.Stopped:Wait()
	
	char:SetAttribute("ShiftEnabled",true)
	
	script.Parent.Movement.Momentum.Enabled = true
	humanoid.JumpPower = oldJump
	stunned = false
end

local function roll()
	if not script.Parent.Movement.Boosting.Value or stunned then return end
	canRoll = false
	isRolling = true
	
	rollAnim = humanoid:LoadAnimation(script.Roll)
	rollAnim:Play()

	local rollForce = Instance.new("BodyVelocity")
	rollForce.MaxForce = Vector3.new(1, 0, 1) * 30000
	rollForce.Velocity = hrp.CFrame.LookVector * 80
	rollForce.Parent = hrp

	game:GetService("Debris"):AddItem(rollForce, 0.4)

	task.wait(0.6)
	isRolling = false
	canRoll = true
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == rollKey and isFalling and not stunned then
		rollQueued = true
		task.delay(rollWindow, function()
			rollQueued = false
		end)
	end
end)

humanoid.StateChanged:Connect(function(_, new)
	if new == Enum.HumanoidStateType.Freefall then
		isFalling = true
		fallStartY = hrp.Position.Y
		
		local tick2 = tick()
		repeat task.wait() 
			if script.Parent.Movement.WallClimb:GetAttribute("Climbing") then
				tick2 = tick()
			end
			if script.Parent.Movement.Wallrunning.Value then
				tick2 = tick()
			end
		until humanoid.FloorMaterial ~= Enum.Material.Air or tick() - tick2 > 2.5
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			print('yo')
			return
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			local fallSpeed = -humanoid.RootPart.Velocity.Y
			if fallSpeed > 20 then
				for _,Anim in humanoid:GetPlayingAnimationTracks() do
					Anim:Stop()
				end
				
				for _,Anim in humanoid:FindFirstChildOfClass('Animator'):GetPlayingAnimationTracks() do
					Anim:Stop()
				end
				script.RemoteEvent:FireServer(true)
				char:SetAttribute("ShiftRotate",false)
			end
		end
	elseif new == Enum.HumanoidStateType.Landed and isFalling then
		isFalling = false
		if script.Parent.Movement.WallClimb:GetAttribute('Climbing') or script.Parent.Movement.Wallrunning.Value then return end
		
		local fallDistance = fallStartY - hrp.Position.Y
		if fallDistance <= 0 then return end

		local fallSpeed = -humanoid.RootPart.Velocity.Y
		print(fallSpeed)
		if fallSpeed < 20 then return end
		if fallSpeed > minFallSpeed then
			if rollQueued then
				roll()
				if fallSpeed >= lethalFallSpeed then
					humanoid:TakeDamage(humanoid.MaxHealth)
				end
			else
				local damage = (fallSpeed - minFallSpeed) * 0.5
				humanoid:TakeDamage(damage)
				if fallSpeed >= lethalFallSpeed then
					humanoid:TakeDamage(humanoid.MaxHealth)
				else
					if fallSpeed > 100 then
						stunPlayer()
					end
				end
			end
		end

		rollQueued = false
	end
end)