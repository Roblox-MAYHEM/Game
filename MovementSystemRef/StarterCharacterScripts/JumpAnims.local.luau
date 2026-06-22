local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = script.Parent
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local JumpAnim = 1

local Anims = {
	humanoid:LoadAnimation(script.Lanim),
	humanoid:LoadAnimation(script.Ranim)
}

for _,anim in Anims do
	anim.Priority = Enum.AnimationPriority.Movement
end

humanoid.Jumping:Connect(function()
	Anims[JumpAnim]:Play(nil,10,1)
	JumpAnim = (JumpAnim % 2) + 1
end)

humanoid.StateChanged:Connect(function()
	if humanoid:GetState() == Enum.HumanoidStateType.Landed then
		for _,anim in Anims do
			anim:Stop()
		end
	end
end)