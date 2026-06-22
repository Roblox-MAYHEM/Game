return {
	Movement = {
		JumpBufferTime = 0.14,
		CoyoteTime = 0.11,

		TiltBase = 0.15,
		TiltOppose = 0.9,
		TiltSnap = 0.4,

		MomentumBonus = 12,
		MomentumSmoothing = 10,

		SlopeSlideAngle = 60,
		SlopeSlideSpeed = 18,
	},

	States = {
		Air = {
			MaxSpeed = 24,

			Force = {
				Min = 70,
				Max = 150,
				PerSpeed = 6.5,
			},

			TorqueScale = 0.22,
			ReversePenalty = 0.35,
		},

		Jumping = {
			JumpStrength = 35,
			AirEntrySpeed = 20,
			Cooldown = 0.14,
			CoyoteTime = 0.2,
			DoubleJumps = 0,
		},

		Landed = {
			MinEntrySpeed = 15,
			Duration = 0.18,
			SpeedBleed = 20,
			TurnLerp = 8,
			MinCarrySpeed = 20,

			MaxImpactSpeed = 100,
			MaxPitch = 20,
			MaxRoll = 300,
			RollSteepness = 5,
		},

		Knockback = {
			Duration = 0.30,
			WallNormalDotMax = 0.35,
			MinWallSpeed = 25,
			DefaultDazeDuration = 0.9,
			CarryMultiplier = 0.85,
		},

		Dazed = {
			Duration = 0.9,
			HorizontalVelocityMultiplier = 0.08,
		},

		Lunging = {
			TIME = 5.5,
			DISTANCE = 50,
			EASE = 0.35,
			CARRY = 0.2,
			PHASE_THROUGH_PLAYERS = true,
		},

		Running = {
			MoveSpeed = 25,
			BulletSpread = 1,

			AccelerationTime = 0.2,
			DecelerationTime = 0.01,
			Friction = 1.7,
			TurnSpeedFactor = 0.1,
		},

		Vaulting = {
			Cooldown = 0.20,
			RepeatCooldown = 0.15,
			SenseCooldown = 1 / 30,
			AutoMinSpeed = 15,
			Duration = 0.75,
			Clearance = 0.45,
			MinCarrySpeed = 22,
			MinLift = 10,
			MaxLift = 30,

			MaxHeight = {
				Auto = 5,
				Manual = 6,
			},
		},

		WallRunning = {
			Cooldown = 1.1,
			BaseMoveSpeed = 1,

			MinSpeed = 8,
			MaxDuration = 2.1,

			RunSpeed = 28,
			StimeSpeed = 4,

			InitialVerticalSpeed = 22,
			VerticalDecay = 28,
			MinVerticalSpeed = -14,

			JumpStrength = 35,
			JumpWindow = 1.0,
		},
	},
}
