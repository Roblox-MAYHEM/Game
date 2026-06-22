script.Parent:FindFirstChildOfClass('Humanoid'):ApplyDescription(
	game.Players:GetHumanoidDescriptionFromUserId(game.Players:GetPlayerFromCharacter(script.Parent).UserId)
)