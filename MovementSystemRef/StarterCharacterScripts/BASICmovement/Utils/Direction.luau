local module = {}

function module:getMoveDirection(HumanoidRootPart : BasePart,MoveVector : Vector3)
--[[	local forward = (HumanoidRootPart.CFrame.LookVector * MoveVector.Z)
	local right = (HumanoidRootPart.CFrame.RightVector * MoveVector.X)
	local dir = (forward + right)
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude > 1 then
		dir = dir.Unit
	end]]
	return HumanoidRootPart.Parent.Humanoid.MoveDirection
end

function module:updateMoveVector(keysDown : {},moveVector : Vector3)
	moveVector = Vector3.new(
		(keysDown["D"] and 1 or 0) - (keysDown["A"] and 1 or 0),
		0,
		(keysDown["W"] and 1 or 0) - (keysDown["S"] and 1 or 0)
	)
	return moveVector
end

return module
