--[[

Animation Module
{
Weapon : {
	{AnimName : Animation {Controller?}, ReplicateToViewmodel}
}
}

]]

return {
	["Pistol"] = {
		["Idle"] 	= {"18878460332", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"111830256722862", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"18878470833", Enum.AnimationPriority.Action2, true},
		["ShootADS"]= {"18878332633", Enum.AnimationPriority.Action2, true},
		["EnterADS"]= {"16885532421", Enum.AnimationPriority.Action2, false},
		["ADS"] 	= {"16885532421", Enum.AnimationPriority.Action2, false},
		["Reload"] 	= {"18878465093", Enum.AnimationPriority.Action2, true},
	},
	
	["DBShotgun"] = {
		["Idle"] 	= {"17488159444", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17488157957", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"17488158950", Enum.AnimationPriority.Action2, true},
		["EnterADS"]= {"16885532421", Enum.AnimationPriority.Action2, false},
		["ADS"] 	= {"17488155495", Enum.AnimationPriority.Action2, false},
		["Reload"] 	= {"17593055965", Enum.AnimationPriority.Action2, true},
	},
	
	["RocketLauncher"] = {
		["Idle"] 	= {"120779348114841", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"114901466646026", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"96636843481410", Enum.AnimationPriority.Action2, true},
		["Reload"] 	= {"117547139062953", Enum.AnimationPriority.Action2, true},
	},
	
	["HandCannon"] = {
		["Idle"] 	= {"120779348114841", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"127249020735464", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"33855276", Enum.AnimationPriority.Action2, true},
		["Reload"] 	= {"117547139062953", Enum.AnimationPriority.Action2, true},
	},
	
	["RPG"] = {
		["Idle"] 	= {"120779348114841", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"127249020735464", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"96636843481410", Enum.AnimationPriority.Action2, true},
		["Reload"] 	= {"117547139062953", Enum.AnimationPriority.Action2, true},
	},
	
	["Dartgun"] = {
		["Idle"] 	= {"18878460332", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"18878336342", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"18878470833", Enum.AnimationPriority.Action2, true},
		["EnterADS"]= {"16885532421", Enum.AnimationPriority.Action2, false},
		["ADS"] 	= {"16885532421", Enum.AnimationPriority.Action2, false},
		["Reload"] 	= {"18878465093", Enum.AnimationPriority.Action2, true},
	},
	
	["Flamethrower"] = {
		["Idle"] 	= {"117910218630073", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"110711613626651", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"76111603261120", Enum.AnimationPriority.Action2, true},
	},
	
	["Umbrella"] = {
		["Idle"] 	= {"122447597742046", "101663799522459", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"86169347570898", "82511750730346", Enum.AnimationPriority.Action2, true},
		["OpenIdle"]= {"108445629121771", "135691907784399", Enum.AnimationPriority.Action2, true},
		["Open"]  	= {"78403920521834", "108496970554213", Enum.AnimationPriority.Action2, true},
		["Lunge"]   = {"106403108926438", "102718542521275", Enum.AnimationPriority.Action3, true},
		["LungeIdle"] = {"78403920521834", "120534391980515", Enum.AnimationPriority.Action2, true},
	},
	
	["Pan"] = {
		["Idle"] 	= {"113010802022760", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17075350395", Enum.AnimationPriority.Action2, true},
		["Swing"] 	= {"101685279085921", Enum.AnimationPriority.Action2, true},
		["Smash"] 	= {"77547851910405", Enum.AnimationPriority.Action2, true},
		["Lunge"] 	= {"72347046257848", Enum.AnimationPriority.Action2, true},
	},
	
	["Rock"] = {
		["Idle"] 	= {"113010802022760", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17075350395", Enum.AnimationPriority.Action2, true},
		["Swing"] 	= {"101685279085921", Enum.AnimationPriority.Action2, true},
		["Smash"] 	= {"77547851910405", Enum.AnimationPriority.Action2, true},
		["Lunge"] 	= {"72347046257848", Enum.AnimationPriority.Action2, true},
	},
	
	["Medkit"] = {
		["Idle"] 	= {"113010802022760", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17075350395", Enum.AnimationPriority.Action2, true},
		["Throw"] 	= {"101685279085921", Enum.AnimationPriority.Action2, true},
	},
	
	["BaseballBat"] = {
		["Idle"] 	= {"17416736486", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17028354492", Enum.AnimationPriority.Action2, true},
		["Windup"] 	= {"113113064721132", Enum.AnimationPriority.Action2, true},
		["WindupIdle"] 	= {"115484133085973", Enum.AnimationPriority.Action3, true},
		["Special"] = {"18543733516", Enum.AnimationPriority.Action2, true},
		["Attack1"] 	= {"16910216739", Enum.AnimationPriority.Action2, true},
		["Attack2"] 	= {"16910212588", Enum.AnimationPriority.Action2, true},
	},
	
	["KBShotgun"] = {
		["Equip"] = {"17488157957", Enum.AnimationPriority.Action, true},
		["Idle"] = {"17488159444", Enum.AnimationPriority.Action2, true},
		["Shoot"] = {"17488158950", Enum.AnimationPriority.Action2, true},
		["EnterADS"] = {"17488157957", Enum.AnimationPriority.Action2, false},
		["ADS"] = {"17488155495", Enum.AnimationPriority.Action2, false},
		["Reload"] = {"17593055965", Enum.AnimationPriority.Action2, true},
	},
	
	["PumpShotgun"] = {
		["Equip"] = {"17488157957", Enum.AnimationPriority.Action, true},
		["Idle"] = {"17488159444", Enum.AnimationPriority.Action2, true},
		["Shoot"] = {"17488158950", Enum.AnimationPriority.Action2, false},
		["EnterADS"] = {"17488157957", Enum.AnimationPriority.Action2, false},
		["ADS"] = {"17488155495", Enum.AnimationPriority.Action2, false},
		["Reload"] = {"17593055965", Enum.AnimationPriority.Action2, true},
	},
	
	["Revolver"] = {
		["Idle"] 	= {"18878460332", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"111830256722862", Enum.AnimationPriority.Action2, true},
		["Shoot"] 	= {"18878470833", Enum.AnimationPriority.Action2, true},
		["FanFire"] 	= {"18878470833", Enum.AnimationPriority.Action2, true},
		["Reload"] 	= {"18878465093", Enum.AnimationPriority.Action2, true},
	},
	
	["ClassicSword"] = {
		["Idle"] 	= {"113010802022760", Enum.AnimationPriority.Action, true},
		["Equip"] 	= {"17075350395", Enum.AnimationPriority.Action2, true},
		["Slash"] 	= {"101685279085921", Enum.AnimationPriority.Action2, true}, -- 522638767, temp
		["Lunge"] 	= {"522638767", Enum.AnimationPriority.Action2, true},
	},
	
	["GreatSword"] = {
		["Idle"] 	= {"83160232608247", Enum.AnimationPriority.Action, true},
		["Run"] 	= {"77194392753771", Enum.AnimationPriority.Action2, true},
		["Equip"] 	= {"17075350395", Enum.AnimationPriority.Action2, true}, 
		["Swing1"] 	= {"110963996573318", Enum.AnimationPriority.Action2, true},
		["Swing2"] 	= {"89804779278247", Enum.AnimationPriority.Action2, true},
		["Swing3"] 	= {"135893471493932", Enum.AnimationPriority.Action2, true},
	},
}
