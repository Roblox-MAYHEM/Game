--[[
	Animation Controller
	1. Loads animations on viewmodel and character
	2. If server, fires to client
	3. Replicate animations on viewmodel from char
]]

local RunService = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")

-- TODO: implement server functionality
if RunService:IsServer() then
	return {
		new = function()
			return nil
		end,
	}
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Metatables = require(ReplicatedStorage.Utils.Metatables)

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local Player = game:GetService("Players").LocalPlayer

local Bindables = Client.Bindables

local Viewmodel
local LoadedAnimations: {AnimationTrack} = {}
local PlayingAnimations : {AnimationTrack} = {}

local function timeMult()
	return _G.TimeMult or 1
end

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController:Init(vm)
	Viewmodel = vm
	Bindables.TimeChanged.Event:Connect(function()
		for _, anim in LoadedAnimations do
			anim:_ApplySpeed()
		end
	end)
end

function AnimationController.new(AnimationIDOrKeyframeSequence: number | KeyframeSequence, priority : Enum.AnimationPriority, replicateToVM : boolean, AnimVM : number? | KeyframeSequence?)
	local CharAnimTrac, VMAnimTrac = AnimationController:LoadAnims(AnimationIDOrKeyframeSequence, priority, replicateToVM, AnimVM)

	local self = {
		CharAnim = CharAnimTrac,
		VMAnim = VMAnimTrac,
		AnimationId = AnimationIDOrKeyframeSequence,
		replicateToVM = replicateToVM,
		priority = CharAnimTrac.Priority,
		Duration = false,
		LengthConnections = {},
	}

	table.insert(LoadedAnimations, self)
	
	return Metatables.inherit(self, self.CharAnim, AnimationController)
end

function AnimationController:LoadAnims(AnimationIDOrKeyframeSequence: number | KeyframeSequence, priority: Enum.AnimationPriority?, replicateToVM : boolean?, AnimVM : number? | KeyframeSequence?)
	if RunService:IsStudio() and typeof(AnimationIDOrKeyframeSequence) == "Instance" then
		AnimationIDOrKeyframeSequence = string.gsub(KeyframeSequenceProvider:RegisterKeyframeSequence(AnimationIDOrKeyframeSequence), "rbxassetid://", "")
	elseif typeof(AnimationIDOrKeyframeSequence) == "number" or typeof(AnimationIDOrKeyframeSequence) == "string" then
		AnimationIDOrKeyframeSequence = "rbxassetid://"..AnimationIDOrKeyframeSequence
		if AnimVM then
			AnimVM = "rbxassetid://"..AnimVM
		end
	end

	local Animation = Instance.new("Animation")

	Animation.AnimationId = AnimationIDOrKeyframeSequence

	local CharAnimTrac: AnimationTrack = Player.Character:WaitForChild("Humanoid").Animator:LoadAnimation(Animation)
	CharAnimTrac.Priority = priority
	local VMAnimTrac
	if replicateToVM then
		local VMAnimation
		if AnimVM then
			VMAnimation = Instance.new("Animation")
			VMAnimation.AnimationId = AnimVM
			VMAnimTrac = Viewmodel.vAnimator:LoadAnimation(VMAnimation)
			VMAnimTrac.Priority = priority
		else
			VMAnimTrac = Viewmodel.vAnimator:LoadAnimation(Animation)
			VMAnimTrac.Priority = priority
		end
			
		
	end
	
	return CharAnimTrac, VMAnimTrac
end

--TODO: make it return a promise to allow chaining
function AnimationController:Play()
	--print(`Playing: {self.AnimationId}`)
	
	self.CharAnim:Play()
	if self.VMAnim then
		self.VMAnim:Play()
	end
	
	table.insert(PlayingAnimations, self)
	self:_ApplySpeed()
end

function AnimationController:Stop()
	--print(`Stopping: {self.AnimationId}`)
	local pos = table.find(PlayingAnimations, self)
	if pos then table.remove(PlayingAnimations, pos) end
	
	self.CharAnim:Stop()
	if self.VMAnim then
		self.VMAnim:Stop()
	end
end

function AnimationController:SetPriority(priority : Enum.AnimationPriority)
	self.CharAnim.Priority = priority
	if self.VMAnim then
		self.VMAnim.Priority = priority
	end
end

function AnimationController:AdjustWeight(val : number)
	self.CharAnim:AdjustWeight(val)
	if self.VMAnim then
		self.VMAnim:AdjustWeight(val)
	end
end

function AnimationController:AdjustSpeed(val : number)
	self.CharAnim:AdjustSpeed(val)
	if self.VMAnim then
		self.VMAnim:AdjustSpeed(val)
	end
end

function AnimationController:_SpeedFor(track: AnimationTrack)
	if not self.Duration or self.Duration <= 0 or track.Length <= 0 then
		return timeMult()
	end

	return (track.Length / self.Duration) * timeMult()
end

function AnimationController:_WatchLength(track: AnimationTrack, key: string)
	if not self.Duration or track.Length > 0 or self.LengthConnections[key] then return end

	self.LengthConnections[key] = track:GetPropertyChangedSignal("Length"):Once(function()
		self.LengthConnections[key] = nil
		self:_ApplySpeed()
	end)
end

function AnimationController:_ApplySpeed()
	self.CharAnim:AdjustSpeed(self:_SpeedFor(self.CharAnim))
	self:_WatchLength(self.CharAnim, "Char")

	if self.VMAnim then
		self.VMAnim:AdjustSpeed(self:_SpeedFor(self.VMAnim))
		self:_WatchLength(self.VMAnim, "VM")
	end
end

function AnimationController:SetDuration(duration : number)
	self.Duration = duration
	self:_ApplySpeed()
end

function AnimationController:Destroy()
	for _, connection in self.LengthConnections do
		connection:Disconnect()
	end

	self.CharAnim:Destroy()
	if self.VMAnim then
		self.VMAnim:Destroy()
	end	
end

return AnimationController
