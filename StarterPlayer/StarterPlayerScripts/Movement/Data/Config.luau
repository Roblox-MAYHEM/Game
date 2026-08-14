return {
	Movement = {
		JumpBufferTime = 0.14,
		CoyoteTime = 0.2,
		WeightExaggeration = 1.2,
		TiltBase = 0.15,
		TiltOppose = 0.9,
		TiltSnap = 0.4,
		SlopeSlideAngle = 60,
	},

	Ground = {
		Speed = 25,
		Acceleration = 0.2,
		Grip = 1.7,
	},

	Landing = {
		Carry = 1,
		Time = 1,
	},

	Air = {
		MoveSpeed = 24,
		Force = {
			Min = 70,
			Max = 150,
			PerSpeed = 6.5,
		},
		TorqueScale = 0.22,
	},

	Jump = {
		Strength = 35,
		Boost = 6,
		MaxSpeed = 40,
		Cooldown = 0.14,
		DoubleJumps = 0,
	},

	Actions = {
		Vault = {
			Cooldown = 0.2,
			Duration = 0.32,
			Speed = 34,
			LiftSpeed = 24,
			Height = 6,
			AutoSpeed = 15,
			JumpDelay = 0.16,
		},
		WallRun = {
			Cooldown = 0.35,
			MinSpeed = 8,
			RunSpeed = 28,
			AdhesionStrength = 5,
			LiftStrength = 20,
			VerticalDecay = 28,
			MinVerticalSpeed = -14,
			JumpStrength = 35,
			JumpWindow = 1,
		},
		Knockback = {
			Duration = 0.3,
			SteeringScale = 0.2,
			WallNormalDotMax = 0.35,
			MinWallSpeed = 25,
			DazeDuration = 0.9,
			DazeHorizontalCarry = 0.08,
		},
		Lunge = {
			Duration = 0.35,
			Strength = 42,
			SteeringScale = 0.1,
		},
		Stomp = {
			Strength = 55,
		},
	},
}
