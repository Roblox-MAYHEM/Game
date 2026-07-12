local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponSystem = script.Parent.Parent
local ClientHitbox = require(WeaponSystem.Modules.ClientHitbox)
local BaseWeapon = require(WeaponSystem.BaseWeapon)
local Remotes = ReplicatedStorage.Events

local Weapon = setmetatable({}, { __index = BaseWeapon })
Weapon.__index = Weapon

Weapon.Binds = {
	[Enum.UserInputState.Begin] = {
		[Enum.UserInputType.MouseButton1] = "Attack",
	},
	[Enum.UserInputState.End] = {},
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

	self.AttackInfo = self.Config.Attack
	self.StompInfo = self.Config.Stomp
	self.States = { Equipped = false, Attacking = false, Stomping = false }

	self.Hitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = self.AttackInfo.HITBOX_SHAPE,
		Size = self.AttackInfo.HITBOX_SIZE,
		Offset = self.AttackInfo.HITBOX_OFFSET,
		HitBoost = self.AttackInfo.HIT_BOOST,
		HitBoostCap = self.AttackInfo.HIT_BOOST_CAP,
	})
	self.Hitbox:OnHumHit(function(humanoid)
		Remotes.WeaponEvent:FireServer("ProcessHit", humanoid.Parent, workspace.CurrentCamera.CFrame.LookVector)
	end)

	self.StompHitbox = ClientHitbox.new({
		Character = self.Character,
		Movement = self.Movement,
		Shape = "Block",
		Size = self.StompInfo.DIRECT_SIZE,
		Offset = self.StompInfo.DIRECT_OFFSET,
	})
	self.StompHitbox:OnHumHit(function(humanoid)
		self:_FinishStomp(humanoid.Parent, self:_DownwardSpeed())
	end)

	self._trove:Connect(self.Movement.StompLanded, function(speed)
		self:_FinishStomp(nil, speed)
	end)
	return self
end

function Weapon:_DownwardSpeed()
	return math.max(-self.HRP.AssemblyLinearVelocity:Dot(self.Movement.CM.UpDirection), 0)
end

function Weapon:_FinishStomp(target, speed)
	if not self.States.Stomping then return end
	self.States.Stomping = false
	self.StompHitbox:HitStop()
	Remotes.WeaponEvent:FireServer("Stomp", self.HRP.Position, target, speed)

	if target then
		self.Movement:StopAction("Direct stomp")
		self.Movement:ApplyImpulse(self.Movement.CM.UpDirection, self.StompInfo.REBOUND_STRENGTH)
	end
end

function Weapon:Equip()
	if not self:_Equip() then return end
	self.States.Equipped = true
	self.Hitbox:Reconcile()
	self.StompHitbox:Reconcile()

	if self.Movement:StartStomp(self.StompInfo) then
		self.States.Stomping = true
		self.StompHitbox:HitStart()
	end
end

function Weapon:Attack()
	if not self.States.Equipped or self.States.Attacking or self.States.Stomping then return end
	self.States.Attacking = true
	Remotes.WeaponEvent:FireServer("AttackStart")
	self.Hitbox:HitStart(self.AttackInfo.TIME)
	task.delay(self.AttackInfo.TIME, function()
		self.Hitbox:HitStop()
		self.States.Attacking = false
	end)
end

function Weapon:Unequip()
	self:_Unequip()
	self.States.Equipped = false
	self.States.Attacking = false
	self.States.Stomping = false
	self.Hitbox:HitStop()
	self.StompHitbox:HitStop()
	if self.Movement.ActiveAction and self.Movement.ActiveAction.Name == "Stomp" then
		self.Movement:StopAction("Boots unequipped")
	end
end

return Weapon
