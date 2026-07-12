return {
	Movement = {
		JumpBufferTime = 0.14,
		CoyoteTime = 0.2,
		TiltBase = 0.15,
		TiltOppose = 0.9,
		TiltSnap = 0.4,
		SlopeSlideAngle = 60,
	},

	Ground = {
		MoveSpeed = 25,
		MomentumRange = 35,
		AccelerationTime = 0.2,
		DecelerationTime = 0.04,
		Friction = 1.7,
		FastFriction = 0.35,
		CounterFriction = 3.2,
		TurnSpeedFactor = 0.1,
		BulletSpread = 1,
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
		Cooldown = 0.14,
		DoubleJumps = 0,
	},

	Actions = {
		Vault = {
			Cooldown = 0.2,
			Duration = 0.32,
			AutoMinSpeed = 15,
			MinForwardStrength = 20,
			MinLiftStrength = 14,
			MaxLiftStrength = 30,
			MaxHeight = 6,
		},
		WallRun = {
			Cooldown = 0.35,
			MinSpeed = 8,
			MaxDuration = 2.1,
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
