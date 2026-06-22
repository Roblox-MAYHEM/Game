local FRAME_TIME = 0.07

return function(viewModel : Model, getCancelToken) -- inject a function that returns the latest token
	local WeaponFrames = { "Primary", "UmbrellaHalfOpen", "UmbrellaOpen" }
	local currentToken = nil
	local currentFrame = 1

	local function safeWeaponModel()
		if not viewModel then return nil end
		local w = viewModel.Weapon
		return (w and w.Parent) and w or nil
	end

	local function NextFrame(frame : number)
		currentFrame = frame
		local weaponModel = safeWeaponModel()
		if not weaponModel then return false end

		for i, name in ipairs(WeaponFrames) do
			local part = weaponModel:FindFirstChild(name)
			if not part then return false end
			part.Transparency = (i == frame) and 0 or 1
		end
		return true
	end

	local function Open()
		task.spawn(function()
			local localToken = {}
			currentToken = localToken

			local weaponModel = safeWeaponModel()
			if not weaponModel then return end

			local first = weaponModel:FindFirstChild(WeaponFrames[1])
			if not first then return end
			first.Transparency = 0

			for i = currentFrame, #WeaponFrames do
				-- external cancel?
				if getCancelToken and currentToken ~= localToken or
					getCancelToken and localToken ~= getCancelToken() then
					return
				end
				if not NextFrame(i) then return end
				task.wait(FRAME_TIME)
			end
		end)
	end

	local function Close()
		task.spawn(function()
			local localToken = {}
			currentToken = localToken

			local weaponModel = safeWeaponModel()
			if not weaponModel then return end

			local last = weaponModel:FindFirstChild(WeaponFrames[#WeaponFrames])
			if not last then return end
			last.Transparency = 0

			for i = currentFrame, 1, -1 do
				if getCancelToken and currentToken ~= localToken or
					getCancelToken and localToken ~= getCancelToken() then
					return
				end
				if not NextFrame(i) then return end
				task.wait(FRAME_TIME)
			end
		end)
	end

	local function Reset()
		currentToken = nil
		local weaponModel = safeWeaponModel()
		if weaponModel then
			for _, name in ipairs(WeaponFrames) do
				local part = weaponModel:FindFirstChild(name)
				if part then part.Transparency = 1 end
			end
		end
		currentFrame = 1
	end

	return Open, Close, Reset
end
