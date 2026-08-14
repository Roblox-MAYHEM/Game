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
		[Enum.UserInputType.MouseButton2] = "Lunge",
	},
}

local function makeHitbox(self, info, feedbackStrength)
	local hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = info.HITBOX_SHAPE,
		Size = info.HITBOX_SIZE,
		Offset = info.HITBOX_OFFSET,
		HitBoost = info.HIT_BOOST,
		HitBoostCap = info.HIT_BOOST_CAP,
	})
	hitbox:OnHumHit(function(humanoid, firstHit)
		if firstHit then
			self.Camera:CameraShake("ShakeOnce", feedbackStrength, 10, 0, 0.12)
			self.ViewModel:AdjustSpring("gunSpring", Vector3.new(0.12, -0.08, 0) * feedbackStrength)
		end
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent)
	end)
	return hitbox
end

function Weapon.new(opts)
	local self = BaseWeapon.new({
		Name = opts.Name,
		WeaponModel = opts.WeaponModel,
		Binds = Weapon.Binds,
		Context = opts.Context,
	})
	setmetatable(self, Weapon)
	self:_init()

	self.States = { Equipped = false, Equipping = false, Acting = false }
	self.AttackInfo = self.Config.Attack
	self.LungeInfo = self.Config.Lunge
	self.BaseGrip = CFrame.new()
	self.AttackHitbox = makeHitbox(self, self.AttackInfo, 0.7)
	self.LungeHitbox = makeHitbox(self, self.LungeInfo, 1.1)
	return self
end

function Weapon:_SetGrip(offset: CFrame?)
	local grip = offset and self.BaseGrip * offset or self.BaseGrip
	self.ViewModel.Joint.C1 = grip
	local worldGrip = self.Character["Right Arm"].Grip
	worldGrip.C1 = grip
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.AttackHitbox:Reconcile()
	self.LungeHitbox:Reconcile()
	self.BaseGrip = self.ViewModel.Joint.C1
	self.States.Equipping = true
	self.Animations.Equip:Play()
	self.Animations.Equip.Stopped:Wait()
	if not self.States.Equipping then return end

	self.States.Equipping = false
	self.States.Equipped = true
	self.Animations.Idle:Play()
end

function Weapon:_RunHit(action, info, hitbox, serverAction)
	task.wait(info.HIT_DELAY)
	if self.Action ~= action then return false end

	Remotes.WeaponEvent:FireServer(serverAction)
	hitbox:HitStart(info.HIT_TIME)
	task.wait(info.HIT_TIME)
	if self.Action ~= action then return false end
	hitbox:HitStop()

	task.wait(math.max(info.TIME - info.HIT_DELAY - info.HIT_TIME, 0))
	return self.Action == action
end

function Weapon:Attack()
	if not self.States.Equipped or self.States.Acting then return end
	local action = {}
	self.Action = action
	self.States.Acting = true
	self.Animations.Slash:SetDuration(self.AttackInfo.TIME)
	self.Animations.Slash:Play()
	if self.Sounds.Swing then self.Sounds.Swing:Play() end

	task.spawn(function()
		if not self:_RunHit(action, self.AttackInfo, self.AttackHitbox, "AttackStart") then return end
		task.wait(self.AttackInfo.COOLDOWN)
		if self.Action == action then
			self.Action = nil
			self.States.Acting = false
		end
	end)
end

function Weapon:Lunge()
	if not self.States.Equipped or self.States.Acting then return end
	local action = {}
	self.Action = action
	self.States.Acting = true
	self:_SetGrip(self.LungeInfo.GRIP_OUT)
	self.Animations.Lunge:SetDuration(self.LungeInfo.TIME)
	self.Animations.Lunge:Play()
	if self.Sounds.Swing then self.Sounds.Swing:Play() end
	self.Movement:StartLunge(workspace.CurrentCamera.CFrame.LookVector, {
		Duration = self.LungeInfo.TIME,
		Gain = self.LungeInfo.FORWARD_GAIN,
		MaxSpeed = self.LungeInfo.FORWARD_CAP,
		SteeringScale = 0.08,
	})
	local float = self.LungeInfo.FLOAT_VELOCITY
	self.Movement:ApplyImpulse(float.Unit, float.Magnitude)

	task.spawn(function()
		if not self:_RunHit(action, self.LungeInfo, self.LungeHitbox, "Lunge") then return end
		self:_SetGrip()
		task.wait(self.LungeInfo.COOLDOWN)
		if self.Action == action then
			self.Action = nil
			self.States.Acting = false
		end
	end)
end

function Weapon:Unequip()
	self:_Unequip()
	self.Action = nil
	self.States.Equipping = false
	self.States.Equipped = false
	self.States.Acting = false
	self.AttackHitbox:HitStop()
	self.LungeHitbox:HitStop()
	self:_SetGrip()
	for _, animation in self.Animations do
		if animation.IsPlaying then animation:Stop() end
	end
end

return Weapon
