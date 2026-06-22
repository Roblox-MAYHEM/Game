local Module = {}

function Module:Jump(ControllerManager, HumanoidRootPart, Power)
	print("Jump!")

	local JumpImpulse = Vector3.new(0, Power * 20, 0)
	ControllerManager.RootPart:ApplyImpulse(JumpImpulse)
end

return Module
