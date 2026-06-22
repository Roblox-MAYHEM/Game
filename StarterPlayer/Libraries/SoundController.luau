local RunService		= game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService		= game:GetService("SoundService")
local TweenService 		= game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages

local Trove = require(Packages.Trove)
local Metatables = require(ReplicatedStorage.Utils.Metatables)

local SoundController = {}
SoundController.__index = SoundController

function SoundController.new(Source: Sound | string | number, Parent: Instance?, Name: string?)
	local self = {}
	self._trove = Trove.new()
	
	if typeof(Source) == "Instance" and Source:IsA("Sound") then
		self.Source = Source
	else
		self.Source = { id = tostring(Source) }
	end
	
	if Parent and Parent:IsA("Player") then
		self.Parent = Parent.Character or Parent.CharacterAdded:Wait()
	elseif typeof(Parent) == "Instance" then
		self.Parent = Parent
	else
		self.Parent = SoundService
    end
	
    self.Name = self.Source.Name or Name

	self._cache = {}
	
	return Metatables.inherit(self, self.Source, SoundController)
end

-- Internal: get or create a free Sound clone
function SoundController:_getAvailable()
    -- search cache
	for i, sound in ipairs(self._cache) do
		if not sound.IsPlaying then
			return i, sound
        end
    end
    -- none free: create new
    local newSound
    if typeof(self.Source) == "Instance" then
        newSound = self._trove:Clone(self.Source)
    else
        newSound = self._trove:Add(Instance, "Sound")
        newSound.SoundId = self.Source.id:match("^%d+$") and ("rbxassetid://"..self.Source.id) or self.Source.id
    end
    newSound.Name = self.Name
    newSound.Parent = self.Parent

    table.insert(self._cache, newSound)
	return #self._cache, newSound
end

function SoundController:Play()
	local index, sound = self:_getAvailable()
	sound:Play()
	return index
end

function SoundController:Stop(index: number?)
	if index then
		self._cache[index]:Stop()
		return
	end

	for _, sound in ipairs(self._cache) do
		sound:Stop()
	end
end

function SoundController:_tweenVolume(sound: Sound, targetVolume: number, duration: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(sound, tweenInfo, { Volume = targetVolume })
	tween:Play()
	return tween
end

function SoundController:FadeIn(duration: number)
	local index, sound = self:_getAvailable()
	sound.Volume = 0
	sound:Play()
	self:_tweenVolume(sound, 1, duration)
	
	return index
end

function SoundController:FadeOut(duration: number, index: number?)
	if index then
		local sound = self._cache[index]
		
		local tween = self:_tweenVolume(sound, 0, duration)
		tween.Completed:Once(function()
			sound:Stop()
			sound.Volume = 1
		end)
		
		return
	end
	
	for _, sound in ipairs(self._cache) do
		if sound.IsPlaying then
			local tween = self:_tweenVolume(sound, 0, duration)
			tween.Completed:Once(function()
				sound:Stop()
				sound.Volume = 1
			end)
		end
	end
end

function SoundController:PlayAtPosition(position)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(1,1,1)
    part.Position = position
    part.Parent = workspace

    local sound
    if typeof(self.Source) == "Instance" then
		sound = self._trove:Clone(self.Source)
    else
		sound = self._trove:Add(Instance, "Sound")
		sound.SoundId = self.Source.id:match("^%d+$") and ("rbxassetid://"..self.Source.id) or self.Source.id
    end
	sound.Name = self.Name or sound.Name
	sound.Parent = part
	
	sound:Play()
	sound.Ended:Once(function()
        self._trove:Remove(sound)
	end)
	sound.Stopped:Once(function()
		self._trove:Remove(sound)
	end)
end

function SoundController:ClearCache()
	self._trove:Remove(self._cache)
	self._cache = {}
end

function SoundController:Destroy()
	self._trove:Destroy()
end

return SoundController
