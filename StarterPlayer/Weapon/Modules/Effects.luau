local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")
local Player 			= game:GetService("Players").LocalPlayer

local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

local Effects = {}
Effects.__index = Effects

function Effects.new(weapon : {Model})
	local self = {
		_weapon = weapon,
		tbl = {},
	}

	return setmetatable(self, Effects)
end

function Effects:RemoveAll()
	for _, v in self._weapon[1]:GetDescendants() do
		if v:isA("Trail") or v:isA("ParticleEmitter") or v:isA("Beam") then
			v.Enabled = false
		end
	end
end

function Effects:Play(effect : name)
	if not self.tbl[effect] then return end
	--print(self._weapon[1].Parent)
	self.tbl[effect](self._weapon[1])
end

function Effects:Register(effect : name, func : (weapon : Model) -> any)
	self.tbl[effect] = func
end


return Effects
