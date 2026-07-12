--[[

Config Module
{
Weapon : {
	{Behavior : {Info}}
}
}

]]

return {
	["Pistol"] = {
		EQUIP_LOAD = 1.0,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Bullet",
			PROJ_RANGE 	= 300,
			--PROJ_VELOCITY = 100,
			PROJ_SHAPE	= "Sphere",
			PROJ_SIZE	= 4,

			FIRE_DELAY	= 0.3, -- delay after equip when the gun can start shooting
			FIRE_RATE 	= 0.25,
			AUTO_FIRE = true,

			--BURST_FIRE = {
			--	COUNT = 4,
			--	DELAY = 0.1,
			--	REPEAT_ON_HOLD = false,
			--},

			MAX_AMMO 			= 12,
			MAX_MAG 			= 100,

			MUZZLE_FLASH = true,

			DMG_TABLE = {
				[10] = 30,
				[30] = 20,
				[100] = 10,
			},
			IMPACT_TABLE = {
				[10] = 8,
				[30] = 6,
				[100] = 4,
			},
			FINISHER_MULTIPLIER = 0.9,
			FINISHER_Y = 6,

			KICK 				= Vector3.new(1,2,0), --OOMPH that the gun "feels" instead of the player
			RECOIL 				= Vector3.new(20,0,0),
			RECOIL_DAMPENER	 	= 1 --For supressors, will reduce recoil. 1 is none
		},
		["AimDownSights"] = {
			BOB_MOD	= 0.1,
			FOV 	= 50,
			TILT 	= 2,
			TIME 	= 0.5,
		},
		["Reload"] = {
			CAN_CANCEL	= true,
		}

	},


	["DBShotgun"] = {
		EQUIP_LOAD = 1.5,

		["Equip"] = {
			TIME		= .1,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE 		= 1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Bullet",
			PROJ_RANGE 	= 75,
			FIRE_RATE 			= .5,
			MAX_AMMO 			= 2,
			MAX_MAG 			= 100,
			FIRE_DELAY			= 0.3,
			AUTO_FIRE = false,
			PELLETS = 16,
			SPREAD = 10,
			MUZZLE_FLASH = false,



			DMG_TABLE = {
				[0]  = 20,
				[15] = 20, 
				[50] = 15,  
				[75] = 5,
			},
			IMPACT_TABLE = {
				[0] = 2.5,
				[15] = 2.5,
				[50] = 1.5,
				[75] = 0.75,
			},
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 8,

			KICK 				= Vector3.new(10,15,0), 
			RECOIL 				= Vector3.new(75,0,0),
			RESET_RECOIL 		= .2,
			RECOIL_DAMPENER	 	= 1,

			KNOCKBACK			= 30,
			KNOCK_DIST			= 9,
			KNOCK_HIT			= 0.8,

		},
		["AimDownSights"] = {
			BOB_MOD	= 0.1,
			FOV 	= 50,
			TILT 	= 2,
			TIME 	= 0.5,
		},
		["Reload"] = {
			CAN_CANCEL	= true,

		}
	},

	["PumpShotgun"] = {
		EQUIP_LOAD = 1.2,

		["Equip"] = {
			TIME		= .1,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE 		= 1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Bullet",
			PROJ_RANGE 	= 100,
			FIRE_RATE 			= .8,
			MAX_AMMO 			= 6,
			MAX_MAG 			= 100,
			FIRE_DELAY			= 0.3,
			AUTO_FIRE = false,
			PELLETS = 8,
			SPREAD = 7,


			DMG_TABLE = {
				[0]  = 0, 
				[15] = 9, 
				[20] = 9, 
				[30] = 0,
			},
			IMPACT_TABLE = {
				[0] = 2,
				[15] = 2.25,
				[20] = 2.25,
				[30] = 0.75,
			},
			FINISHER_MULTIPLIER = 1.05,
			FINISHER_Y = 7,

			KICK = Vector3.new(6,7,0),
			RECOIL = Vector3.new(35,0,25),
			RECOIL_DAMPENER	 	= 1,

			KNOCKBACK			= 30,
		},
		["AimDownSights"] = {
			BOB_MOD	= 0.1,
			FOV 	= 70,
			TILT 	= 2,
			TIME 	= 0.5,
		},
		["Reload"] = {
			CAN_CANCEL	= true,
			TIME = .5,
			DELAY = .05,

			CONTINUOUS_LOAD = true,
			LOAD_SIZE = 1,

		},
	},

	["KBShotgun"] = {
		EQUIP_LOAD = 1.2,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE 		= 1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Bullet",
			PROJ_RANGE 	= 50,

			IMPACT_POWER = 3,
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 9,

			FIRE_RATE 			= 0.5,
			MAX_AMMO 			= 4,
			MAX_MAG 			= 100,
			FIRE_DELAY			= 0.3,
			AUTO_FIRE = false,
			PELLETS = 10,
			SPREAD = 10,


			DMG_TABLE = {
				[0] = 3,
				[7] = 4,
				[20] = 4,
				[30] = 0,
			},

			KICK 				= Vector3.new(6,7,0), 
			RECOIL 				= Vector3.new(35,0,25),
			RECOIL_DAMPENER	 	= 1, 

			KNOCKBACK			= 230,
		},
		["AimDownSights"] = {
			BOB_MOD	= 0.1,
			FOV 	= 70,
			TILT 	= 2,
			TIME 	= 0.5,
		},
		["Reload"] = {
			CAN_CANCEL	= true,
			TIME = 7,
		}
	},


	["RocketLauncher"] = {
		EQUIP_LOAD = 1.2,

		["Equip"] = {
			TIME		= .1,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Rocket",
			PROJ_VELOCITY = 60, 
			PROJ_DMG 		= 100, --direct hit
			PROJ_RANGE 	= 300,
			PROJ_ACTIVE_HB = false,
			PROJ_SHAPE	= "Sphere",
			PROJ_SIZE	= 6,
			PROJ_DEFLECTABLE = true,

			FIRE_RATE = 1,
			MAX_AMMO  = 4,
			MAX_MAG   = 25,	
			FIRE_DELAY			= 0.3,


			KICK 				= Vector3.new(10,15,0),
			RECOIL 				= Vector3.new(75,0,50),
			RECOIL_DAMPENER	 	= 1
		},
		["Explosion"] = {
			DURATION 	= 1,

			RADIUS 		= 7.5,
			IMPULSE_MAX 	= 100,
			IMPULSE_MIN 	= 80,
			Y_MAX	= 80,
			MAX_DMG 	= 90,
			MIN_DMG 	= 35,
			IMPACT_MAX = 20,
			IMPACT_MIN = 10,
			FINISHER_MULTIPLIER = 1.1,
		},
		["Reload"] = {
			CAN_CANCEL = true,
			TIME = .1,
			DELAY = .05,

			CONTINUOUS_LOAD = true,
			LOAD_SIZE = 1,
		}
	},

	["RPG"] = {
		EQUIP_LOAD = 1.4,

		["Equip"] = {
			TIME		= .1,
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE		= 1.1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "RPGRocket",
			PROJ_VELOCITY = 60, 
			PROJ_DMG 		= 50, --direct hit
			PROJ_RANGE 	= 300,
			PROJ_ACTIVE_HB = false,
			PROJ_SHAPE	= "Sphere",
			PROJ_ACCEL = Vector3.new(0,-50,0),
			PROJ_SIZE	= 6,
			PROJ_DEFLECTABLE = true,


			FIRE_RATE = 2.5,
			MAX_AMMO  = 1,
			MAX_MAG   = 25,
			FIRE_DELAY			= 0.3,


			KICK 				= Vector3.new(10,15,0),
			RECOIL 				= Vector3.new(100,0,50),
			RECOIL_DAMPENER	 	= 1,

			KNOCKBACK = 450,
		},
		["Explosion"] = {
			DURATION 	= .3,

			RADIUS 		= 18,
			IMPULSE_MAX 	= 150,
			IMPULSE_MIN 	= 50,
			Y_MAX	= 60,
			MAX_DMG 	= 50,
			MIN_DMG 	= 15,
			IMPACT_MAX = 18,
			IMPACT_MIN = 8,
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 12,
		},
		["Reload"] = {
			CAN_CANCEL = false,
			TIME = .1,
			DELAY = .05,

			CONTINUOUS_LOAD = true,
			LOAD_SIZE = 1,
		}
	},

	["HandCannon"] = {
		EQUIP_LOAD = 1.7,

		["Equip"] = {
			TIME		= .1,
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE		= 1.1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Cannonball",
			PROJ_VELOCITY = 90, 
			PROJ_ACCEL = Vector3.new(0, -50, 0),
			PROJ_DMG 		= 35, --direct hit
			PROJ_RANGE 	= 300,
			PROJ_ACTIVE_HB = false,
			PROJ_SHAPE	= "Sphere",
			PROJ_SIZE	= 8,
			PROJ_DEFLECTABLE = true,

			FIRE_RATE = 1.1,
			MAX_AMMO  = 2,
			MAX_MAG   = 25,

			KICK 				= Vector3.new(10,15,0),
			RECOIL 				= Vector3.new(75,0,50),
			RECOIL_DAMPENER	 	= 1,

			KNOCKBACK = 300,
		},
		["Explosion"] = {
			DURATION 	= .3,

			RADIUS 		= 12,
			IMPULSE_MAX 	= 150,
			IMPULSE_MIN 	= 50,
			Y_MAX	= 60,
			MAX_DMG 	= 50,
			MIN_DMG 	= 15,
			IMPACT_MAX = 16,
			IMPACT_MIN = 7,
			FINISHER_MULTIPLIER = 1.1,
			FINISHER_Y = 10,
		},
		["Reload"] = {
			CAN_CANCEL = true,
			TIME = .1
		}
	},

	["Dartgun"] = {
		EQUIP_LOAD =0.8,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE 		= 1,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Dart",
			PROJ_VELOCITY = 100,
			PROJ_ACCEL 	= Vector3.new(0,-workspace.Gravity,0),
			PROJ_DMG 		= 15,
			PROJ_RANGE 	= 130,

			FIRE_RATE = .2,
			MAX_AMMO = 10,
			MAX_MAG = 100,

			KICK = Vector3.new(2,1,0), --OOMPH that the projectile "feels" instead of the player
			RECOIL = Vector3.new(0,2,0),
			RECOIL_DAMPENER = 1, --For supressors, will reduce recoil. 1 is none
		},
		["AimDownSights"] = {
			BOB_MOD	= 0.1,
			FOV 	= 50,
			TILT 	= 2,
			TIME 	= 0.5,
		},
		["Reload"] = {
			CAN_CANCEL = false,
		},
	},

	["Flamethrower"] = {
		EQUIP_LOAD = 2,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Burn"] = {
			DEBOUNCE = .15, --delay before activates
			UPDATE_SERVER = 5 / 60, --per sec

			DAMAGE_TABLE = {
				[0.0] 	= 0.5,
				[0.5]	= 1.0,
				[1.5] 	= 1.25,
				[2.0]	= 1.50,
			},
			DAMAGE_FALLOFF = {
				[0] 	= 1.0,
				[17.5]	= 0.3,
			},
			BASE_DMG = 2,
			DAMAGE_TIME = .1, --How often damage is applied
			AMMO_TIME = .2, --Time until ammo is subtracted

			MAX_AMMO = 250,
		},
		["AfterBurn"] = {
			BASE_DMG = 2,
			DAMAGE_TIME = .5, --How often damage is applied
			BURN_DUR = 7,
		}
	},

	["Umbrella"] = {
		EQUIP_LOAD = 0.8,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
			SCALE		= .5,
		},
		["Glide"] = {
			LAUNCH_VELOCITY = 25,
			COOLDOWN = .5,
			POP_SPEED          = 30,     -- upward Δv when opening
			OPEN_RAMP_TAU      = 0.10,   -- seconds – how quickly drag ramps up
			CLOSE_RAMP_TAU     = 0.12,   -- seconds – how quickly drag ramps down
			K_OPEN             = 0.10,   -- quadratic drag coefficient (accel form)
			K_CLOSED           = 0.00,   -- drag while closed (normally 0)
			GRAVITY_SCALE_OPEN = 0.55,   -- 1 = normal gravity, lower = floatier
		},
		["Lunge"] = {
			DMG = 60,
			IMPACT_POWER = 14,
			FINISHER_MULTIPLIER = 0.85,
			FINISHER_Y = 18,

			ACTIVE_TIME = .2,	
			OPEN_TIME = .1,
			FORWARD_VELOCITY = 20,
			UP_VELOCITY = 3,
			COOLDOWN = 1.5,

			WINDOW = 4,
			RANGE = 30,
			ARC = 50,
			HIT_DEBOUNCE = 0.8,
			LOS = true,
		}
	},


	["Pan"] = {
		EQUIP_LOAD = 0.9,

		["Equip"] = {
			TIME		= .3,
			JOINT_C1 	= CFrame.new(0,0,0), --* CFrame.Angles(math.rad(-90), math.rad(180), math.rad(180)),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Attack"] = {
			DMG = 30,
			IMPACT_POWER = 14,
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 8,

			TIME = .8,
			RANGE = 40,
			WINDOW = 1,
			ARC = 150,
			HIT_DEBOUNCE = 0.05,
			LOS = true,

			DEFLECT_RADIUS = 7,
			DEFLECT_OFFSET = CFrame.new(0,0,-5),

		}
	},

	["Rock"] = {
		EQUIP_LOAD = 0.6,

		["Equip"] = {
			TIME		= .5,
			JOINT_C1 	= CFrame.new(0,-1,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 0,
		},
		["Attack"] = {
			DMG = 10,
			IMPACT_POWER = 9,
			FINISHER_MULTIPLIER = 1,
			FINISHER_Y = 5,

			TIME = .15,
			RANGE = 10,
			WINDOW = 1,
			ARC = 150,
			HIT_DEBOUNCE = 0.05,
			LOS = true,

			DEFLECT_RADIUS = 8,
			DEFLECT_OFFSET = CFrame.new(0,0,-5),
		}
	},

	["Medkit"] = {
		EQUIP_LOAD = 0.5,

		["Equip"] = {
			TIME		= 1,
			JOINT_C1 	= CFrame.new(0,-1,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Throw"] = { --AAAA
			PROJ_NAME 	= "Medkit",
			PROJ_VEL_INFLUENCE = Vector3.new(0,15,0), 
			PROJ_VELOCITY = 40,
			PROJ_ACCEL	= Vector3.new(0,-workspace.Gravity,0),
			PROJ_RANGE 	= 300,
			PROJ_ACTIVE_HB = true,
			PROJ_SHAPE	= "Block",
			PROJ_SIZE	= 6,
			PROJ_DEFLECTABLE = true,
			PROJ_ADD_PLAYER_VELOCITY = true,

			COOLDOWN = 1,
		},
		["Heal"] = {
			DURATION 	= 5,

			RADIUS 		= 7.5,
			DELTA 		= .75,
			AMOUNT		= 10,
		}
	},

	["BaseballBat"] = {
		EQUIP_LOAD = 1,

		["Equip"] = {
			TIME		= 0.5,
			CAM_OFFSET	= CFrame.new(1,.25,-1),
			CAN_SWAY	= true,
			TILT		= 0,
		},
		["Attack"] = {
			TIME = .6,
			COOLDOWN = .6,
			DMG = 10,
			IMPACT_POWER = 16,
			FINISHER_MULTIPLIER = 1.25,
			FINISHER_Y = 16,
			WINDOW = 3,
			RANGE = 50,
			ARC = 160,
			HIT_DEBOUNCE = 0.10,
			LOS = true,
		},
		["Windup"] = {
			TIME = 1,
			COOLDOWN = 2,
			MAX = 90,
			RATE = 0.1,
		},
		["Special"] = {
			BASE_DMG = 80,
			BASE_IMPACT = 24,
			IMPACT_CHARGE_MULT = 0.1,
			FINISHER_MULTIPLIER = 1.5,
			FINISHER_Y = 20,
			DURATION = 1,
			COOLDOWN = 5, --1.5
			WIND_MULT = 0.5,
			TIME = 2,
			HIT_TIME = 0.75,
		}
	},

	["ClassicSword"] = {
		EQUIP_LOAD = 0.8,

		["Equip"] = {
			TIME = 0.25,
			JOINT_C1 = CFrame.new(0, 0, -1.70000005, 0, 0, 1, 1, 0, 0, 0, 1, 0),
			CAM_OFFSET = CFrame.new(0, 0, -1),
			CAN_SWAY = true,
			TILT = 8,
		},
		["Attack"] = {
			TIME = 0.35,
			COOLDOWN = 0.15,
			DMG = 15,
			WINDOW = 1,
			RANGE = 35,
			ARC = 140,
			HIT_DEBOUNCE = 0.08,
			LOS = true,
			IMPACT_POWER = 10,
			FINISHER_MULTIPLIER = 1,
			FINISHER_Y = 6,
		},
		["Lunge"] = {
			TIME = 0.8,
			HIT_TIME = 0.55,
			COOLDOWN = 0.45,
			COMBO_WINDOW = 0.25,
			DMG = 30,
			WINDOW = 1.1,
			RANGE = 45,
			ARC = 130,
			HIT_DEBOUNCE = 0.12,
			LOS = true,
			FLOAT_VELOCITY = Vector3.new(0, 16, 0),
			FORWARD_VELOCITY = 26,
			GRIP_OUT = CFrame.new(0, 0, -0.75),
			IMPACT_POWER = 18,
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 10,
		},
	},

	["GreatSword"] = {
		SLOT_COST = 3,
		EQUIP_LOAD = 1.8,

		["Equip"] = {
			TIME = 0.45,
			JOINT_C1 = CFrame.new(0, 0, -4, 0, 0, 1, 1, 0, 0, 0, 1, 0),
			CAM_OFFSET = CFrame.new(0.5, 0.1, -1.25),
			CAN_SWAY = true,
			TILT = 4,
			SCALE = 1.35,
		},
		["Attack"] = {
			TIME = 0.75,
			HIT_DELAY = 0.22,
			HIT_TIME = 0.28,
			COOLDOWN = 0,
			CHAIN_RESET = 1.2,
			SPECIAL_COOLDOWN = 1.8,
			DMG = 75,
			WINDOW = 1.5,
			RANGE = 60,
			ARC = 170,
			HIT_DEBOUNCE = 0.2,
			LOS = true,
			IMPACT_POWER = 18,
			FINISHER_MULTIPLIER = 1.2,
			FINISHER_Y = 12,
			SWINGS = {
				{
					ANIM = "Swing1",
					TIME = 0.72,
					HIT_DELAY = 0.18,
					HIT_TIME = 0.26,
					DMG = 60,
					IMPACT_POWER = 15,
					FINISHER_MULTIPLIER = 1.1,
				},
				{
					ANIM = "Swing2",
					TIME = 0.78,
					HIT_DELAY = 0.2,
					HIT_TIME = 0.28,
					DMG = 70,
					IMPACT_POWER = 18,
					FINISHER_MULTIPLIER = 1.2,
				},
				{
					ANIM = "Swing3",
					TIME = 1.05,
					HIT_DELAY = 0.32,
					HIT_TIME = 0.42,
					DMG = 105,
					IMPACT_POWER = 26,
					FINISHER_MULTIPLIER = 1.4,
					FINISHER_Y = 18,
					SPECIAL = true,
				},
			},
		},
	},

	["Revolver"] = {
		EQUIP_LOAD = 0.7, --1.2

		["Equip"] = {
			TIME		= .1,
			JOINT_C1 	= CFrame.new(0,0,0),
			CAM_OFFSET	= CFrame.new(0,0,-1),
			CAN_SWAY	= true,
			TILT		= 10,
		},
		["Shoot"] = {
			PROJ_NAME 	= "Bullet",
			PROJ_RANGE 	= 300,
			--PROJ_VELOCITY = 20,
			PROJ_SHAPfE	= "Sphere",
			PROJ_SIZE	= 1.5,
			FIRE_DELAY	= 0.1, -- delay after equip when the gun can start shooting
			FIRE_RATE 			= 0.5,
			MAX_AMMO 			= 6,
			MAX_MAG 			= 100,
			AUTO_FIRE = false,

			SPEAD = .1,

			FAN_FIRE_RATE = .12,
			FAN_SPREAD = 10,

			MUZZLE_FLASH = true,

			DMG_TABLE = {
				[0] = 60,
				[50] = 40,
				[100] = 20,
			},
			IMPACT_TABLE = {
				[0] = 14,
				[50] = 11,
				[100] = 7,
			},
			FINISHER_MULTIPLIER = 1.15,
			FINISHER_Y = 8,

			KICK 				= Vector3.new(2,2,0), --OOMPH that the gun "feels" instead of the player
			RECOIL 				= Vector3.new(10,0,-100),
			RECOIL_DAMPENER	 	= 0.7 --For supressors, will reduce recoil. 1 is none
		},
		["SecondaryShoot"] = {
			RECOIL_DAMPENER = 1
		},
		["Reload"] = {
			CAN_CANCEL	= true,
		}

	},
}
