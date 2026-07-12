--[[Baseball bat
Weapon.new(Config) -- Initializes values
Weapon:[_Behavior Name Here_]() -- Runs Weapon
Weapon:Unequip() -- When tool has been unequipped

Weapons will perform certain weapon-specific moves.
Also fires events to server.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")

local WeaponSystem 		= script.Parent.Parent
local Libraries = Client.Libraries
local Modules = WeaponSystem.Modules
local Remotes = ReplicatedStorage.Events
local Bindables = Client.Bindables
local WeaponAssets = ReplicatedStorage.Assets.Weapons

local ClientHitbox = require(Modules.ClientHitbox)

local BaseWeapon = require(WeaponSystem.BaseWeapon)

-- Weapon Class
local Weapon = setmetatable({}, {__index = BaseWeapon})
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Attack",
		[Enum.UserInputType.MouseButton2] = "Windup",
	},
	[Enum.UserInputState.End] = {
		[Enum.UserInputType.MouseButton1] = "StopAttack",
		[Enum.UserInputType.MouseButton2] = "Special",
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
		Windup = false,
		Special = false,
		TriggerHeld = false,
	}

	self.AttackInfo = self.Config.Attack
	self.SpecialInfo = self.Config.Special

	self.Effects:Register("EnableTrail", function(weapon)
		weapon.Primary.Trail.Enabled = true
	end)

	self.Effects:Register("DisableTrail", function(weapon)
		weapon.Primary.Trail.Enabled = false
	end)

	self.Hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = self.AttackInfo.HITBOX_SHAPE,
		Size = self.AttackInfo.HITBOX_SIZE,
		Offset = self.AttackInfo.HITBOX_OFFSET,
		HitBoost = self.AttackInfo.HIT_BOOST,
		HitBoostCap = self.AttackInfo.HIT_BOOST_CAP,
	})
	self.Hitbox:OnHumHit(function(humanoid, result, segment)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent, workspace.CurrentCamera.CFrame.LookVector)
	end)

	return self
end

function Weapon:Equip()	
	if not self:_Equip() then return end --calls weapon base
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

	Remotes.WeaponEvent:FireServer("AttackStart")

	self:_PlayAttackAnimation()
	self:_PlayAttackSound()

	self.Effects:Play("EnableTrail")

	task.wait(self.AttackInfo.TIME)

	self.States.Attacking = false
	self.Hitbox:HitStop()

	self.Effects:Play("DisableTrail")


	-- optional extra cooldown if you have it in config
	if self.AttackInfo.COOLDOWN and self.AttackInfo.COOLDOWN > 0 then
		task.wait(self.AttackInfo.COOLDOWN)
	end

	return true
end

function Weapon:Attack()
	self.States.TriggerHeld = true
	if self.AttackLoop then return end

	self.AttackLoop = task.spawn(function()
		while self.States.TriggerHeld do
			if self.States.Equipped then self:_AttackOnce()
			else task.wait() end
		end

		self.AttackLoop = nil
	end)
end

function Weapon:StopAttack()
	self.States.TriggerHeld = false
end

-- Custom attack animation handler
function Weapon:_PlayAttackAnimation()
	-- Cancel windup if attacking
	self:_CancelWindup()

	-- Stop all attack animations
	self.Animations["Attack1"]:Stop()
	self.Animations["Attack2"]:Stop()

	-- Play random attack animation
	local AnimationsList = {"Attack1", "Attack2"}
	local Selected = self.Animations[AnimationsList[math.random(1, #AnimationsList)]]
	Selected:Play()
end

-- Custom attack sound handler
function Weapon:_PlayAttackSound()
	if self.Sounds.Swing then
		self.Sounds.Swing:Play()
	end
end

function Weapon:Windup()
	if self.States.Attacking or self.States.Special then return end

	self.States.Windup = true
	Remotes.WeaponEvent:FireServer("Windup")

	self.Animations.Windup:Play()
	self._trove:Connect(self.Animations.Windup.Stopped, function()
		if self.States.Windup then
			self.Animations.WindupIdle:Play()
		end
	end)
end

function Weapon:Special()
	if not self.States.Windup then return end

	self.States.Windup = false
	self.Animations.Windup:Stop()
	self.Animations.WindupIdle:Stop()

	self.States.Special = true
	Remotes.WeaponEvent:FireServer("Special")

	self.Animations.Special:Play()
	if self.Sounds.Swing then
		self.Sounds.Swing:Play()
	end

	local totalTime = self.SpecialInfo and self.SpecialInfo.TIME or 1
	local specialTime = self.SpecialInfo and (self.SpecialInfo.HIT_TIME or self.SpecialInfo.DURATION or self.SpecialInfo.TIME) or 1

	self.Hitbox:HitStart(specialTime)
	task.wait(specialTime)
	self.Hitbox:HitStop()

	local remaining = totalTime - specialTime
	if remaining > 0 then
		task.wait(remaining)
	end

	self.States.Special = false
end

function Weapon:_CancelWindup()
	if not self.States.Windup then return end

	self.States.Windup = false
	self.Animations.Windup:Stop()
	self.Animations.WindupIdle:Stop()

	Remotes.WeaponEvent:FireServer("CancelWindup")
end

function Weapon:Unequip()
	self:_Unequip() --calls weapon base

	self:_CancelWindup()
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.Special = false
	self.States.TriggerHeld = false

	for _, v in pairs(self.Animations) do
		if v.IsPlaying then
			v:Stop()
		end
	end

	self.Hitbox:HitStop()
end

return Weapon
