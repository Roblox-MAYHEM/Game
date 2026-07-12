local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Events

type KnockbackParams = {
	FORCE: number?,
	IMPULSE: number?,
	MODE: ("Push" | "Finisher")?,
	Y: number?,
	YMAX: number?,
	FLAT: boolean?,
	DURATION: number?,
	WALL_DAZE: boolean?,
	DAZE_DURATION: number?,
	WALL_SPEED_MIN: number?,
}

return function(targetCharacter: Model, direction: Vector3, params: KnockbackParams?)
	params = params or {}

	local root = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or direction.Magnitude <= 0.001 then
		return
	end

	if params.FLAT then
		direction = Vector3.new(direction.X, 0, direction.Z)
		if direction.Magnitude <= 0.001 then
			return
		end
	end

	local force = params.FORCE or params.IMPULSE or 0
	local velocity = direction.Unit * force
	if params.Y then
		velocity += Vector3.yAxis * params.Y
	end
	if params.YMAX and velocity.Y > params.YMAX then
		velocity = Vector3.new(velocity.X, params.YMAX, velocity.Z)
	end
	if velocity.Magnitude <= 0.001 then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if targetPlayer then
		Remotes.Knockback:FireClient(targetPlayer, {
			Velocity = velocity,
			Mode = params.MODE or "Finisher",
			Duration = params.DURATION,
			WallDaze = params.WALL_DAZE == true,
			DazeDuration = params.DAZE_DURATION,
			WallSpeedMin = params.WALL_SPEED_MIN,
		})
	else
		root:ApplyImpulse(velocity * root.AssemblyMass)
	end
end
