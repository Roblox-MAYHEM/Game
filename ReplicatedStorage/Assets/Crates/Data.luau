--[[
	Data Module
	{
		Crates : {
			CrateName : {
				NAME : string,
				THUMBNAIL : string,
				CATEGORY : string,
				DESCRIPTION : string,
				CONTENT : {
					Rarity : {
						CHANCE: number,
						REWARDS: {WeaponName},
					}
				}
			}
		}
	}
]]

return {
	["StarterCrate"] = {
		NAME = "Starter Crate",
		THUMBNAIL = "http://www.roblox.com/asset/?id=5649884808",
		CATEGORY = "Crate",
		DESCRIPTION = "A simple crate with beginner weapons.",
		CONTENT = {
			Common = {
				CHANCE = 60,
				REWARDS = {
					"BaseballBat",
					"Pan",
					"Pistol",
					"Revolver",
					"Medkit",
					"Flamethrower",
				},
			},
			Rare = {
				CHANCE = 30,
				REWARDS = {
					"Umbrella",
					"DBShotgun",
				},
			},
			Epic = {
				CHANCE = 10,
				REWARDS = {
					"RocketLauncher",
				},
			},
		}
	},

	["PowerCrate"] = {
		NAME = "Power Crate",
		THUMBNAIL = "",
		CATEGORY = "Crate",
		DESCRIPTION = "Contains powerful weapons with lower drop rates.",
		CONTENT = {
			Common = {
				CHANCE = 50,
				REWARDS = {
					"Pistol",
					"BaseballBat",
				},
			},
			Rare = {
				CHANCE = 35,
				REWARDS = {
					"DBShotgun",
					"Umbrella",
				},
			},
			Legendary = {
				CHANCE = 15,
				REWARDS = {
					"Flamethrower",
					"Pan",
				},
			},
		}
	},
}
