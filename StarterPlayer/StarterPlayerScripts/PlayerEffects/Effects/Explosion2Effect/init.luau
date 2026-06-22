local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Explosion = script.ExplosionLocation.Value

return {
	Play = function(origin : Vector3, radius : number, duration : number)
		local model : Model = Explosion:Clone()
		local originCF = CFrame.new(origin + Vector3.new(0,radius/4,0))

		-- 1. SETUP MODEL CENTER
		local referencePart = model:WaitForChild("OuterExplosion"):WaitForChild("1")
		-- Force the pivot to the center of the reference part so ScaleTo() works perfectly
		model.WorldPivot = referencePart.CFrame 

		local baseSize = referencePart.Size.X / model:GetScale()
		local scaleFactor = (2*radius) / baseSize
		
		-- 2. DURATION MULTIPLIER
		local originalTotalTime = 1.25 
		local m = duration / originalTotalTime 

		model:PivotTo(originCF)
		model.Parent = workspace:WaitForChild("Effects")

		local sw = model:WaitForChild("ShockWaveVFX")
		
		-- PROXY VALUES
		local scaleValue = Instance.new("NumberValue")
		scaleValue.Value = 0.1

		local cframeValue = Instance.new("CFrameValue")
		cframeValue.Value = originCF

		local transparencyValue = Instance.new("NumberValue")
		transparencyValue.Value = 0

		-- LISTENERS
		scaleValue.Changed:Connect(function(val) model:ScaleTo(val) end)
		cframeValue.Changed:Connect(function(val) model:PivotTo(val) end)
		transparencyValue.Changed:Connect(function(val)
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part.Transparency = val
				end
			end
		end)

		--- MATH HELPERS ---
		-- We calculate the offset from the VERY FIRST frame so the animation is relative
		local function getRelativeCF(folderPath)
			local startFrame = folderPath['0']['Values']['0'].Value
			return function(targetFrameValue)
				local offset = startFrame:Inverse() * targetFrameValue
				return originCF * offset
			end
		end

		local modelCFCalc = getRelativeCF(script['1']['CFrame'])
		local swCFCalc = getRelativeCF(script['2']['CFrame'])

		--- TWEENS ---

		-- Shockwave
		local sTweenCFrame1 = TS:Create(sw, TweenInfo.new(0.1), {CFrame = swCFCalc(script['2']['CFrame']['0']['Values']['0'].Value)})
		local sTweenCFrame2 = TS:Create(sw, TweenInfo.new(0.45 * m), {CFrame = swCFCalc(script['2']['CFrame']['27']['Values']['0'].Value)})

		local sTweenSize1 = TS:Create(sw, TweenInfo.new(0.1), {Size = script['2']['Size']['0']['Values']['0'].Value * scaleFactor})
		local sTweenSize2 = TS:Create(sw, TweenInfo.new(1.25 * m, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = script['2']['Size']['75']['Values']['0'].Value * scaleFactor})

		-- Model Scale
		local TweenScale1 = TS:Create(scaleValue, TweenInfo.new(0.1), {Value = script['1']['Scale']['0']['Values']['0'].Value * scaleFactor})
		local TweenScale2 = TS:Create(scaleValue, TweenInfo.new(0.516 * m, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = script['1']['Scale']['31']['Values']['0'].Value * scaleFactor})

		-- Model CFrame (Now using relative calculation)
		local TweenCFrame1 = TS:Create(cframeValue, TweenInfo.new(0.1), {Value = modelCFCalc(script['1']['CFrame']['0']['Values']['0'].Value)})
		local TweenCFrame2 = TS:Create(cframeValue, TweenInfo.new(0.95 * m, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Value = modelCFCalc(script['1']['CFrame']['57']['Values']['0'].Value)})
		local TweenCFrame3 = TS:Create(cframeValue, TweenInfo.new(0.2 * m), {Value = modelCFCalc(script['1']['CFrame']['69']['Values']['0'].Value)})

		-- Model Transparency
		local TweenTransparency1 = TS:Create(transparencyValue, TweenInfo.new(0.1), {Value = script['1']['Transparency']['0']['Values']['0'].Value})
		local TweenTransparency2 = TS:Create(transparencyValue, TweenInfo.new(0.266 * m, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = script['1']['Transparency']['16']['Values']['0'].Value})
		local TweenTransparency3 = TS:Create(transparencyValue, TweenInfo.new(0.766 * m, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Value = script['1']['Transparency']['62']['Values']['0'].Value})

		--- EXECUTION ---		
		TweenScale1:Play()
		sTweenCFrame1:Play()
		TweenCFrame1:Play()
		sTweenSize1:Play()
		TweenTransparency1:Play()
			
		model.ExplosionParticles.Sparks:Emit(5)

		sTweenCFrame1.Completed:Connect(function() sTweenCFrame2:Play() end)
		TweenScale1.Completed:Connect(function() TweenScale2:Play() end)
		sTweenSize1.Completed:Connect(function() sTweenSize2:Play() end)
		TweenCFrame1.Completed:Connect(function() TweenCFrame2:Play() end)
		TweenCFrame2.Completed:Connect(function() TweenCFrame3:Play() end)
		TweenTransparency1.Completed:Connect(function() TweenTransparency2:Play() end)

		TweenTransparency2.Completed:Connect(function() 
			TweenTransparency3:Play()
			TweenTransparency3.Completed:Wait()
			model:Destroy()
			scaleValue:Destroy()
			cframeValue:Destroy()
			transparencyValue:Destroy()
			
		end)
	end,
}