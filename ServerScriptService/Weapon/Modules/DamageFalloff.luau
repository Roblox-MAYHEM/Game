-- DamageByDistance.lua
-- Returns a function that maps a distance to a damage value using interpolation.

export type DamageParams = {
	rampUpStart: number,    -- where ramp-up begins (distance)
	rangeStart: number,     -- start of full damage (end of ramp-up)
	rangeEnd: number,       -- end of full damage (start of falloff)
	falloffEnd: number,     -- where damage reaches minimum
	closeDmg: number,       -- damage at 0 distance
	midDmg: number,         -- full/optimal damage
	farDmg: number,         -- minimum damage at max range
}

return function(distanceDamageTable : {[number] : number} | DamageParams) : (number) -> number
	assert(typeof(distanceDamageTable) == "table", "Expected table of distance-damage pairs or DamageParams")

	if distanceDamageTable.rampUpStart ~= nil then
		local params = distanceDamageTable :: DamageParams

		-- Convert param model to a numeric damage table
		distanceDamageTable = {
			[params.rampUpStart] = params.closeDmg,
			[params.rangeStart]  = params.midDmg,
			[params.rangeEnd]    = params.midDmg,
			[params.falloffEnd]  = params.farDmg,
		}
	else
		distanceDamageTable = distanceDamageTable :: {[number]: number}
	end

	-- Convert to array of {d, dmg} and sort by distance
	local pairsList = {}
	for distance, damage in pairs(distanceDamageTable) do
		table.insert(pairsList, {d = distance, dmg = damage})
	end
	table.sort(pairsList, function(a, b)
		return a.d < b.d
	end)

	return function(distance)
		-- If below or equal to smallest distance
		if distance <= pairsList[1].d then
			return pairsList[1].dmg
		end

		-- If above or equal to largest distance
		if distance >= pairsList[#pairsList].d then
			return pairsList[#pairsList].dmg
		end

		-- Find where this distance fits and linearly interpolate
		for i = 1, #pairsList - 1 do
			local a = pairsList[i]
			local b = pairsList[i + 1]
			if distance >= a.d and distance <= b.d then
				local t = (distance - a.d) / (b.d - a.d)
				return a.dmg + (b.dmg - a.dmg) * t
			end
		end
	end
end