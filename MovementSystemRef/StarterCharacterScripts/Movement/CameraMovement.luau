local module = {}

local RS = game:GetService("RunService")
local camera = workspace.CurrentCamera
local Character = script.Parent.Parent

local function IsFirstPerson()
	return (Character.Head.Position - camera.CFrame.Position).Magnitude < 1.4
end

local function bop(axis, speed, fullwave, invert)
	if not IsFirstPerson() then return end

	local amplitudeY = 0.2
	local amplitudeRot = 1
	local time = 0
	local done = false
	local conn

	conn = RS.RenderStepped:Connect(function(delta)
		if done then conn:Disconnect() return end
		time += delta * speed

		local offsetY = math.sin(time) * amplitudeY
		local rot = math.sin(time * 2) * math.rad(amplitudeRot)
		if invert then rot = -rot end

		local camCF = camera.CFrame
		local newPos = camCF.Position + Vector3.new(0, offsetY, 0)

		local tiltCF
		if axis == "X" then
			tiltCF = CFrame.Angles(rot, 0, 0)
		else
			tiltCF = CFrame.Angles(0, 0, rot)
		end

		camera.CFrame = CFrame.new(newPos, newPos + camCF.LookVector) * tiltCF

		local limit = math.pi
		if fullwave then limit *= 2 end
		if time >= limit then done = true end
	end)
end

function module:BopUP(speed, fullwave)
	--bop("X", speed, fullwave, false)
end

function module:BopDOWN(speed, fullwave)
	--bop("X", speed, fullwave, true)
end

function module:BopLEFT(speed, fullwave)
	--bop("Z", speed, fullwave, true)
end

function module:BopRIGHT(speed, fullwave)
	--bop("Z", speed, fullwave, false)
end

return module
