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


			DMG_TABLE = {
				[0]  = 0, 
				[15] = 9, 
				[20] = 9, 
				[30] = 0,
			},

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

			BULLET_KB			= 20, --Strength of impulse applied to enemies hit with bullet
			BULLET_KB_TOTAL		= 40,

			FIRE_RATE 			= 0.5,
			MAX_AMMO 			= 4,
			MAX_MAG 			= 100,
			FIRE_DELAY			= 0.3,
			AUTO_FIRE = false,


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
			KNOCKBACK_FORCE = 60,
			KNOCKBACK_Y = 18,
			KNOCKBACK_YMAX = 28,
			KNOCKBACK_DURATION = 0.35,
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
			DURATION = 1,
			COOLDOWN = 5, --1.5
			WIND_MULT = 0.5,
			TIME = 2,
			HIT_TIME = 0.75,
			KNOCKBACK = true,
			KNOCKBACK_FORCE = 95,
			KNOCKBACK_CHARGE_MULT = 0.6,
			KNOCKBACK_Y = 24,
			KNOCKBACK_YMAX = 32,
			KNOCKBACK_DURATION = 0.45,
			DAZE_DURATION = 1.0,
			WALL_SPEED_MIN = 24,
		}
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
