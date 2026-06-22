local Humanoid = script.Parent:FindFirstChildOfClass('Humanoid')

local Jump : Sound = Humanoid.RootPart:WaitForChild("Jumping")
local Run : Sound = Humanoid.RootPart:WaitForChild("Running")


game["Run Service"].RenderStepped:Connect(function()
	local MovementFOLDER = script.Parent.Movement
	if MovementFOLDER.SlidingValue.Value then
		Run.Volume = 0
	elseif MovementFOLDER.Wallclimbing.Value then
		Run.Volume = 0
	else
		Run.Volume = 0.5
	end
end)