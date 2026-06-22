local char = script.Parent

for i = 1,3,1 do
	char:SetAttribute("ShiftRotate", not char:GetAttribute("ShiftRotate"))
	task.wait(0.1)
end

char:SetAttribute("ShiftRotate", true)