task.wait(1.5)
local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local root = Player.Character.HumanoidRootPart
local dir, vel
local angle = 0
local angle2 = 0
local original = root.RootJoint.C0

local hb = game:GetService("RunService")

hb.Heartbeat:Connect(function()
	if script.Parent.Values.TightSpace.Value then
		root.RootJoint.C0 = original
		return
	end
	if Player.Character.Humanoid.Health > 0 then
		vel = root.Velocity * Vector3.new(1,0,1)

		if vel.Magnitude > 2  then
			dir = vel.Unit
			angle = root.CFrame.RightVector:Dot(dir)/6.5
			angle2 = root.CFrame.LookVector:Dot(dir)/6.5
		else
			angle = 0
			angle2 = 0
		end

		local tweenInfo = TweenInfo.new(
			.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)

		local tween = TweenService:Create(root.RootJoint, tweenInfo, {C0 = original*CFrame.Angles(angle2, -angle, 0)})

		tween:Play()
	end
end)
