--[[
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Weapons will perform certain weapon-specific moves.
Also fires events to server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem 		= script.Parent.Parent
local Modules 		= WeaponSystem.Modules
local Remotes 		= ReplicatedStorage.Events

local ClientHitbox = require(Modules.ClientHitbox)
local ProjectileHitbox = require(ReplicatedStorage.Packages.ProjectileHitbox)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

-- Weapon Class
local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Attack",
	},
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton1] = "StopAttack", 
	},
}

function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
	})
	setmetatable(self, Weapon)
	self:_init()

	self.States = {
		Equipped = false,
		Equipping = false,
		Attacking = false,
	}

	self.next = 1

	self.AttackInfo = self.Config.Attack
	self.HitboxPart = self.WeaponModel[1]:WaitForChild("Hitbox")

	self.Hitbox = ClientHitbox.new(self.HitboxPart)
	self.Hitbox:OnHumHit(function(humanoid, result, segment)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	self.ProjectileHitbox = ProjectileHitbox.new(self.Player, self.AttackInfo.DEFLECT_RADIUS, self.AttackInfo.DEFLECT_OFFSET, self.Projectile)

	self.ProjectileHitbox.Hit:Connect(function(cast)
		local id = cast.UserData.ProjectileId
		local speed = cast:GetVelocity().Magnitude

		local camera = workspace.CurrentCamera
		local cameraLookDir = camera.CFrame.LookVector
		local deflectDir = cameraLookDir.Unit

		self.Projectile.RequestUpdate(id, nil, deflectDir * speed)
	end)

	return self
end

function Weapon:Equip()
	if not self:_Equip() then return end

	self.Hitbox:Reconcile()

	self.States.Equipping = true
	if self.Animations.Equip then
		self.Animations.Equip:Play()
		self.Animations.Equip.Stopped:Wait()
	else
		task.wait(self.Config.Equip.TIME)
	end

	if not self.States.Equipping then return end

	self.States.Equipping = false
	self.States.Equipped = true
	self.Animations.Idle:Play()
end

function Weapon:_AttackOnce()
	if self.States.Attacking or self.States.Windup or self.States.Special then return end
	if not self.States.Equipped then return end

	self.States.Attacking = true
	self.AttackStartTime = tick()

	self.Hitbox:HitStart(self.AttackInfo.TIME)
	self.ProjectileHitbox:HitStart(self.AttackInfo.TIME)

	Remotes.WeaponEvent:FireServer("AttackStart")

	self:_PlayAttackAnimation()
	self:_PlayAttackSound()

	task.wait(self.AttackInfo.TIME)

	self.States.Attacking = false
	self.Hitbox:HitStop()
	self.ProjectileHitbox:HitStop()

	-- optional extra cooldown if you have it in config
	if self.AttackInfo.COOLDOWN and self.AttackInfo.COOLDOWN > 0 then
		task.wait(self.AttackInfo.COOLDOWN)
	end

	return true
end

function Weapon:Attack()
	-- if already holding, ignore repeat Begin events
	if self.States.TriggerHeld then return end
	self.States.TriggerHeld = true

	task.spawn(function()
		while self.States.TriggerHeld do
			local ok = self:_AttackOnce()
			if not ok then
				-- Couldn't start an attack (maybe mid-windup/special/etc.)
				-- Small wait to avoid tight loop
				task.wait(0.05)
			end
		end
	end)
end

function Weapon:StopAttack()
	self.States.TriggerHeld = false
end

function Weapon:_PlayAttackAnimation()
	self.Animations["Swing"]:Stop()
	self.Animations["Lunge"]:Stop()
	self.Animations["Smash"]:Stop()

	self.AnimList = {"Swing", "Lunge", "Smash"}
	local Selected = self.Animations[self.AnimList[self.next]]
	Selected:Play()

	self.next = (self.next % #self.AnimList) + 1
end

function Weapon:_PlayAttackSound()
	if self.Sounds.Swing then
		self.Sounds.Swing:Play()
	end
end

function Weapon:Unequip()
	self:_Unequip()
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.TriggerHeld = false

	for _, v in pairs(self.Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end

	self.Hitbox:HitStop()
	self.ProjectileHitbox:HitStop()
end

return Weapon
