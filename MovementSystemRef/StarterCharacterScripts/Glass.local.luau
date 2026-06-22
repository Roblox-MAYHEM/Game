local Character = script.Parent
local Humanoid = Character:FindFirstChildOfClass('Humanoid')
local Rootpart : BasePart = Character:WaitForChild('HumanoidRootPart')

local DB = false

local SFX1 = script.SFX1
local SFX2 = script.SFX2
local SFX3 = script.SFX3

local CurrentSfx = 1

local CamShaker = require(game.ReplicatedStorage:WaitForChild('Modules'):WaitForChild('CamShaker'))

function Main(Glass)
	DB = true
	
	if typeof(Glass) == "Instance" then
		local GlassModel : Model = Glass
		local GlassPart = GlassModel.PrimaryPart or GlassModel:FindFirstChildOfClass('BasePart')
		print("GLASS")
		print(GlassPart)

		if Rootpart.AssemblyLinearVelocity.Magnitude > 47 then
			local Transparency = GlassPart.Transparency
			Glass:RemoveTag("Glass")
			local Shards = GlassModel:FindFirstChild("Shards")
			game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('BreakGlass'):FireServer(Shards,Transparency)
			GlassPart:Destroy()
			
			if CurrentSfx == 1 then
				SFX1:Play()
				CurrentSfx = 2
			elseif CurrentSfx == 2 then
				SFX2:Play()
				CurrentSfx = 3
			elseif CurrentSfx == 3 then
				SFX3:Play()
				CurrentSfx = 1
			end
			
			local camShake = CamShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
				workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCFrame
			end)

			camShake:Start()
			
			camShake:Shake(CamShaker.Presets.Explosion)
		end
	end
end

Humanoid.Touched:Connect(function(Hit)
	if DB then return end
	if Hit.Parent:HasTag('Glass') or Hit.Parent.Parent:HasTag("Glass") then
		local Glass = Hit.Parent:HasTag('Glass') and Hit.Parent or Hit.Parent.Parent:HasTag('Glass') and Hit.Parent.Parent
		Main(Glass)
	end
	DB = false
end)