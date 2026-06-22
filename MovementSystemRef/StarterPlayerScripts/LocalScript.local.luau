local plr = game.Players.LocalPlayer
local Char = plr.Character or plr.CharacterAdded:Wait()
if Char:FindFirstChildOfClass('Humanoid') then
	local H = Char:FindFirstChildOfClass('Humanoid')
	H:LoadAnimation(script.Animation):Play()
end