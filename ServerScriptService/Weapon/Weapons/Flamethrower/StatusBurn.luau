--[[
	General Function
 - Applies burn status effect to player
 - Fires clients to replicate burn vfx
 - Can cancel active burns?? -- dousing
]]

local DamageModule = require(script.Parent.Parent.Parent.Modules.DamageHandler)

local Burn = {
	HitHumans = {} :: {Humanoid}
}

function Burn.ApplyBurn(Sender : Player, Reciever : Humanoid, Base_DMG : number, DMG_TIME : number, DUR : number)
	if table.find(Burn.HitHumans, Reciever) then return end
		
	task.spawn(function()
		table.insert(Burn.HitHumans, Reciever)
		local timeElapsed = 0

		repeat
			DamageModule.DamageHumanoid(Reciever, Sender, Base_DMG, false)
			task.wait(DMG_TIME)
			timeElapsed += DMG_TIME
		until timeElapsed >= DUR
		
		table.remove(Burn.HitHumans, table.find(Burn.HitHumans, Reciever))
	end)
end

return Burn
