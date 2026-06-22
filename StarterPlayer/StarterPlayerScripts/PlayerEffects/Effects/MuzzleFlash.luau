local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = game:GetService("StarterPlayer")
local Debris = game:GetService("Debris")
local VFX = Client.Assets.VFX

local function setTransparency(model, val)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = val
		end
	end
end

return {
	Play = function(shootPart: BasePart, spreadDir: Vector3)
		local model: Model = VFX.MuzzleFlash:Clone()
		local attachment = model:FindFirstChild("Attachment", true) -- Find it anywhere in the model
		local frames = {model:FindFirstChild("f1"), model:FindFirstChild("f2"), model:FindFirstChild("f3")}

		local flashOrigin = shootPart.Muzzle.WorldPosition
		--print(flashOrigin)
		-- 1. Create the orientation CFrame
		local targetCFrame = CFrame.lookAt(flashOrigin, flashOrigin + spreadDir.Unit)
		
		model:PivotTo(targetCFrame * CFrame.Angles(0, math.rad(90), 0) * attachment.CFrame:Inverse())

		model.Parent = workspace.Effects

		-- 3. Weld it so it follows the gun during animations
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = shootPart
		weld.Part1 = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
		weld.Parent = model -- Putting the weld in the effect keeps the gun's hierarchy clean

		-- Play the flash
		for _, frame in ipairs(frames) do
			if frame then
				setTransparency(frame, 0)
				task.wait(0.03)
				setTransparency(frame, 1)
			end
		end

		model:Destroy()
	end,
}