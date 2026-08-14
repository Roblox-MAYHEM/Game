local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local Remotes = ReplicatedStorage.Events
local ClientHitbox = require(WeaponSystem.Modules.ClientHitbox)
local BaseWeapon = require(WeaponSystem.BaseWeapon)

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Attack",
		[Enum.UserInputType.MouseButton2] = "Windup",
	},
	[Enum.UserInputState.End] = {
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
	self.Hitbox:OnHumHit(function(humanoid, firstHit)
		if firstHit then
			local strength = self.States.Special and 1.5 or 0.8
			self.Camera:CameraShake("ShakeOnce", strength, 10, 0, 0.12)
			self.ViewModel:AdjustSpring("gunSpring", Vector3.new(0.12, -0.08, 0) * strength)
		end
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)

	return self
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.Hitbox:Reconcile()
	self.States.Equipping = true
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()
	if not self.States.Equipping then return end

	self.States.Equipping = false
	self.States.Equipped = true
	self.Animations.Idle:Play()
end

function Weapon:_FinishHit(action, info, serverAction: string?)
	task.wait(info.HIT_DELAY)
	if self.Action ~= action then return false end

	if serverAction then Remotes.WeaponEvent:FireServer(serverAction) end
	self.Hitbox:HitStart(info.HIT_TIME)
	task.wait(info.HIT_TIME)
	if self.Action ~= action then return false end

	self.Hitbox:HitStop()
	self.Effects:Play("DisableTrail")
	return true
end

function Weapon:Attack()
	if not self.States.Equipped or self.States.Attacking or self.States.Windup or self.States.Special then return end

	local action = {}
	self.Action = action
	self.States.Attacking = true
	self.Animations.Attack1:Stop()
	self.Animations.Attack2:Stop()
	self.Animations[math.random(2) == 1 and "Attack1" or "Attack2"]:Play()
	if self.Sounds.Swing then self.Sounds.Swing:Play() end
	self.Effects:Play("EnableTrail")

	task.spawn(function()
		if not self:_FinishHit(action, self.AttackInfo, "AttackStart") then return end
		task.wait(math.max(self.AttackInfo.TIME - self.AttackInfo.HIT_DELAY - self.AttackInfo.HIT_TIME, 0))
		if self.Action ~= action then return end
		task.wait(self.AttackInfo.COOLDOWN)
		if self.Action == action then
			self.Action = nil
			self.States.Attacking = false
		end
	end)
end

function Weapon:Windup()
	if not self.States.Equipped or self.States.Attacking or self.States.Special or self.States.Windup then return end

	self.States.Windup = true
	Remotes.WeaponEvent:FireServer("Windup")
	self.Animations.Windup:Play()
	self.Animations.Windup.Stopped:Once(function()
		if self.States.Windup then self.Animations.WindupIdle:Play() end
	end)
end

function Weapon:Special()
	if not self.States.Windup then return end

	local action = {}
	self.Action = action
	self.States.Windup = false
	self.States.Special = true
	self.Animations.Windup:Stop()
	self.Animations.WindupIdle:Stop()
	self.Animations.Special:Play()
	if self.Sounds.Swing then self.Sounds.Swing:Play() end
	self.Effects:Play("EnableTrail")
	Remotes.WeaponEvent:FireServer("Special")

	task.spawn(function()
		if not self:_FinishHit(action, self.SpecialInfo, "SpecialStart") then return end
		task.wait(math.max(self.SpecialInfo.TIME - self.SpecialInfo.HIT_DELAY - self.SpecialInfo.HIT_TIME, 0))
		if self.Action ~= action then return end
		task.wait(self.SpecialInfo.COOLDOWN)
		if self.Action == action then
			self.Action = nil
			self.States.Special = false
		end
	end)
end

function Weapon:_CancelWindup()
	if not self.States.Windup then return end
	self.States.Windup = false
	self.Animations.Windup:Stop()
	self.Animations.WindupIdle:Stop()
	Remotes.WeaponEvent:FireServer("CancelWindup")
end

function Weapon:Unequip()
	self:_CancelWindup()
	self:_Unequip()
	self.Action = nil
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.Attacking = false
	self.States.Special = false
	self.Hitbox:HitStop()
	self.Effects:Play("DisableTrail")
	for _, animation in self.Animations do
		if animation.IsPlaying then animation:Stop() end
	end
end

return Weapon
