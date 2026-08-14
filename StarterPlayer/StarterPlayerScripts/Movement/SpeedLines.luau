local SpeedLines = {}
SpeedLines.__index = SpeedLines

local MIN_SPEED = 20
local OFFSET = 10

function SpeedLines.new(asset)
	local self = setmetatable({}, SpeedLines)
	self.Model = asset:Clone()
	self.Emitter = self.Model.Attachment.ParticleEmitter
	self.Model.Parent = workspace.CurrentCamera
	return self
end

function SpeedLines:Update(camera, speed)
	self.Model.CFrame = camera.CFrame + camera.CFrame.LookVector * (OFFSET / camera.FieldOfView * 70)
	self.Emitter.Enabled = speed >= MIN_SPEED
end

function SpeedLines:Destroy()
	self.Model:Destroy()
end

return SpeedLines
