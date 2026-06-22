local Transitions = {}

Transitions.Parents = {
	Idle = { "Locomotion" },
	Running = { "Locomotion" },
	Air = { "Locomotion" },
	Landed = { "Locomotion" },
	WallRunning = { "Locomotion" },
	Knockback = { "Locomotion" },
	Dazed = { "Locomotion" },
}

Transitions.Key = {
	Locomotion = {
		OnBegan = {
			{ key = "Space", to = "Vaulting", when = function(fsm) return fsm.States.Vaulting:CanStart("Manual") end },
			{ key = "Space", to = "Jumping", when = function(fsm) return fsm.States.Jumping:CanStart() end },
		},
		OnEnded = {},
	},

	WallRunning = {
		OnBegan = {
			{ key = "Space", to = "Jumping", when = function(fsm) return fsm.States.WallRunning:CanJump() end },
		},
		OnEnded = {},
	},

	Idle = { OnBegan = {}, OnEnded = {} },
	Running = { OnBegan = {}, OnEnded = {} },
	Air = { OnBegan = {
			{ key = "Space", to = "Jumping", when = function(fsm) return fsm.States.WallRunning:CanJump() end },
		},
		OnEnded = {},
	},
	Landed = { OnBegan = {}, OnEnded = {} },
	Knockback = { OnBegan = {}, OnEnded = {} },
	Dazed = { OnBegan = {}, OnEnded = {} },
	Jumping = { OnBegan = {}, OnEnded = {} },
	Vaulting = { OnBegan = {}, OnEnded = {} },
	Lunging = { OnBegan = {}, OnEnded = {} },
}

Transitions.Auto = {
	Disabled = {},

	Idle = {
		{ to = "Air", when = function(fsm) return not fsm.Frame.Grounded end },
		{ to = "Running", when = function(fsm) return fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	Running = {
		{ to = "Vaulting", when = function(fsm) return fsm.States.Vaulting:CanStart("Auto") end },
		{ to = "Air", when = function(fsm) return not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.Frame.Grounded and fsm:IsIdle() end },
	},

	Jumping = {
		{ to = "Air", when = function() return true end },
	},

	Air = {
		{ to = "Jumping", when = function(fsm) return fsm:HasBufferedKey("Space") and fsm.States.Jumping:CanStart() end },
		{ to = "WallRunning", when = function(fsm) return fsm.States.WallRunning:CanStart() end },
		{ to = "Landed", when = function(fsm) return fsm.Frame.Grounded and fsm.States.Landed:CanStart() end },
		{ to = "Idle", when = function(fsm) return fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	WallRunning = {
		{ to = "Landed", when = function(fsm) return fsm.Frame.Grounded and fsm.States.Landed:CanStart() end },
		{ to = "Air", when = function(fsm) return not fsm.States.WallRunning:CanContinue() end },
	},

	Landed = {
		{ to = "Jumping", when = function(fsm) return fsm:HasBufferedKey("Space") and fsm.States.Jumping:CanStart() end },
		{ to = "Air", when = function(fsm) return not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.States.Landed:IsFinished() and fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.States.Landed:IsFinished() and fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	Knockback = {
		{ to = "Air", when = function(fsm) return fsm.States.Knockback:IsFinished() and not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.States.Knockback:IsFinished() and fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.States.Knockback:IsFinished() and fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	Dazed = {
		{ to = "Air", when = function(fsm) return fsm.States.Dazed:IsFinished() and not fsm.Frame.Grounded end },
		{ to = "Idle", when = function(fsm) return fsm.States.Dazed:IsFinished() and fsm.Frame.Grounded and fsm:IsIdle() end },
		{ to = "Running", when = function(fsm) return fsm.States.Dazed:IsFinished() and fsm.Frame.Grounded and not fsm:IsIdle() end },
	},

	Vaulting = {
		{ to = "Landed", when = function(fsm)
			return fsm.Frame.Grounded and fsm.States.Vaulting:IsFinished()
		end },
		{ to = "Air", when = function(fsm) return fsm.States.Vaulting:IsFinished() end },
	},

	Lunging = {
		{ to = "Air", when = function(fsm) return not fsm.Frame.Grounded and fsm.States.Lunging:IsFinished() end },
		{ to = "Idle", when = function(fsm) return fsm.Frame.Grounded and fsm:IsIdle() and fsm.States.Lunging:IsFinished() end },
		{ to = "Running", when = function(fsm) return fsm.Frame.Grounded and not fsm:IsIdle() and fsm.States.Lunging:IsFinished() end },
	},
}

return Transitions
