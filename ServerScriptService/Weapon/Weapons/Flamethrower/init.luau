--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Behaviors will perform certain weapon-specific moves.
Modularized for easier reuse and combination.
]]

local ServerStorage = game:GetService("ServerStorage")
local RunService	= game:GetService("RunService")

local WeaponSystem	= script.Parent.Parent
local Modules		= WeaponSystem.Modules

local BaseWeapon = require(WeaponSystem.BaseWeapon)
local DamageHandler = require(Modules.DamageHandler)
local DamageFalloff = require(Modules.DamageFalloff)
local StatusBurn = require(script.StatusBurn)
local HBXCollision = require(script.HitboxCollision)

local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

local function init(self)
	--Creates cast Weapon
	self.Hitboxes = {}
	self.HitboxOffsets = {} -- : {CFrame}

	for i, v in self.WeaponModel:GetChildren() do
		if v:HasTag("Hitbox") then
			--Gets last element of hitbox name as an identifier
			local Tag = tonumber(string.sub(v.Name, -1))
			self.Hitboxes[Tag] = v
			--Get Hitbox's CFrame relative to weapon model's shoot part
			self.HitboxOffsets[Tag] = self.WeaponModel.Shoot.CFrame:ToObjectSpace(v.CFrame)
		end
	end
end

function Weapon.new(WeaponModel : Model, player : Player)
	local self = BaseWeapon.new({
		["Player"] 		= player,
		["WeaponModel"] 	= WeaponModel,
		["Name"]		= WeaponModel.Name,
	})
	
	setmetatable(self, Weapon)
	
	self.BurnInfo = self.Config.Burn
	self.AfterBurnInfo = self.Config.AfterBurn
	
	self.GetDmgFallOff = DamageFalloff(self.BurnInfo.DAMAGE_TABLE)
	self.GetDmgMultiplier = DamageFalloff(self.BurnInfo.DAMAGE_FALLOFF)

	self.hitHumanoids = {} -- {Humanoid : {number, number}}
	self.wishPositions = {}	
	
	init(self)
	return self
end

function Weapon:EnterFlames(ShootPosition : CFrame)
	for i, v in ipairs(self.HitboxOffsets) do
		--Get Hitbox's CFrame relative to weapon model's shoot part
		self.Hitboxes[i].CFrame = ShootPosition:ToWorldSpace(v)
		self.wishPositions[i] = ShootPosition:ToWorldSpace(v)
	end

	self.HitboxDetection = RunService.Heartbeat:Connect(function(...)
		self:_UpdateFlameCollisions(...)
	end)
end

function Weapon:_UpdateFlameCollisions(dt : number)
	--Get Collisions
	for _, hitbox in ipairs(self.Hitboxes) do
		local collisions = HBXCollision.GetCollisionsInPart(hitbox)

		--Insert humanoids into collision list (debounce)
		for _, human in ipairs(collisions) do
			if not self.hitHumanoids[human] then
				self.hitHumanoids[human] = {0,0}
			end
			
			if self.hitHumanoids[human][2] >= self.BurnInfo.DAMAGE_TIME then
				self.hitHumanoids[human][2] = 0
				local distance = (human.Parent.HumanoidRootPart.Position - self.Character.HumanoidRootPart.Position).Magnitude

				local dmg = self.GetDmgMultiplier(self.hitHumanoids[human][1]) * self.GetDmgFallOff(distance) * self.BurnInfo.BASE_DMG
				DamageHandler.DamageHumanoid(human, self.Player, dmg)
			end
			
			self.hitHumanoids[human][1] += dt
			self.hitHumanoids[human][2] += dt
			
			StatusBurn.ApplyBurn(
				self.Player, human,
				self.AfterBurnInfo.BASE_DMG, self.AfterBurnInfo.DAMAGE_TIME, self.AfterBurnInfo.BURN_DUR)
				
		end
	end

	--Lerp hitbox positions
	self.Hitboxes[1].CFrame = self.Hitboxes[1].CFrame:Lerp(self.wishPositions[1], 0.9)
	self.Hitboxes[2].CFrame = self.Hitboxes[2].CFrame:Lerp(self.wishPositions[2], 0.4)
	self.Hitboxes[3].CFrame = self.Hitboxes[3].CFrame:Lerp(self.wishPositions[3], 0.25)

end

function Weapon:UpdateFlames(ShootPosition : CFrame)
	--Gets actual wish CFrame given offset relative to viewmodel shoot position
	for i, v in ipairs(self.HitboxOffsets) do
		self.wishPositions[i] = ShootPosition:ToWorldSpace(v)
	end
end

function Weapon:ExitFlames()
	self.HitboxDetection:Disconnect()
end

function Weapon:Equip()
	self:_Equip()
end

function Weapon:Unequip()
	self:_Unequip()
end

function Weapon:Shoot(...)
	self.ProjectileCaster:Fire(...)
end

return Weapon
