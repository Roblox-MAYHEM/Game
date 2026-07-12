local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local ImpactDisplay = {}

local function impactColor(impact: number, primed: boolean): Color3
	if primed then
		return Color3.fromRGB(255, 70, 90)
	end

	local alpha = math.clamp(impact / 100, 0, 1)
	return Color3.fromRGB(95, 220, 255):Lerp(Color3.fromRGB(255, 190, 55), alpha)
end

local function pipText(character: Model): string
	if character:GetAttribute("ImpactPrimed") ~= true then
		return ""
	end

	return string.rep("● ", character:GetAttribute("ImpactPips") or 0)
end

local function connectImpact(character: Model, trove, update)
	for _, attribute in ipairs({ "Impact", "ImpactPrimed", "ImpactPips", "ImpactProtected", "Dead" }) do
		trove:Connect(character:GetAttributeChangedSignal(attribute), update)
	end
	update()
end

local function createPips(parent: Instance): TextLabel
	local pips = Instance.new("TextLabel")
	pips.Name = "ImpactPips"
	pips.AnchorPoint = Vector2.new(1, 0.5)
	pips.Position = UDim2.new(1, -8, 0.5, 0)
	pips.Size = UDim2.fromOffset(62, 20)
	pips.BackgroundTransparency = 1
	pips.Font = Enum.Font.GothamBold
	pips.TextColor3 = Color3.new(1, 1, 1)
	pips.TextSize = 13
	pips.TextXAlignment = Enum.TextXAlignment.Right
	pips.ZIndex = 4
	pips.Parent = parent
	return pips
end

local function bindLocalMeter(ui: ScreenGui, trove)
	local healthBar = ui:WaitForChild("HealthBar")
	local impactBar = healthBar:Clone()
	impactBar.Name = "ImpactBar"
	impactBar.Position = healthBar.Position - UDim2.fromOffset(0, 54)
	impactBar.Parent = ui
	trove:Add(impactBar)

	local display = impactBar:WaitForChild("HealthDisplay")
	local fill = display:WaitForChild("Health") :: Frame
	local count = impactBar:WaitForChild("HealthCount") :: TextLabel
	local pips = createPips(impactBar)

	local function bindCharacter(character: Model)
		local characterTrove = trove:Extend()

		connectImpact(character, characterTrove, function()
			local impact = character:GetAttribute("Impact") or 0
			local primed = character:GetAttribute("ImpactPrimed") == true
			local protected = character:GetAttribute("ImpactProtected") == true
			fill.Size = UDim2.new(math.clamp(impact / 100, 0, 1), 0, 1, 0)
			fill.BackgroundColor3 = impactColor(impact, primed)
			fill.BackgroundTransparency = if protected then 0.35 else 0
			count.Text = tostring(math.round(impact))
			pips.Text = pipText(character)
		end)
	end

	if LocalPlayer.Character then
		bindCharacter(LocalPlayer.Character)
	end
	trove:Connect(LocalPlayer.CharacterAdded, bindCharacter)
end

local function createOverheadMeter(character: Model, trove)
	if character == LocalPlayer.Character then return end

	local adornee = character:FindFirstChild("Head") or character:WaitForChild("HumanoidRootPart", 5)
	if not adornee then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ImpactDisplay"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 220
	billboard.Size = UDim2.fromOffset(116, 28)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	billboard.Parent = adornee
	trove:Add(billboard)

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 0.58)
	background.Position = UDim2.fromScale(0, 0.42)
	background.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
	background.BorderSizePixel = 0
	background.ClipsDescendants = true
	background.Parent = billboard

	local teamAccent = Instance.new("UIStroke")
	local characterPlayer = Players:GetPlayerFromCharacter(character)
	teamAccent.Color = if characterPlayer and characterPlayer.Team then characterPlayer.Team.TeamColor.Color else Color3.new(1, 1, 1)
	teamAccent.Thickness = 1.5
	teamAccent.Transparency = 0.15
	teamAccent.Parent = background

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = impactColor(0, false)
	fill.BorderSizePixel = 0
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.fromScale(1, 1)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.GothamBold
	count.TextColor3 = Color3.new(1, 1, 1)
	count.TextSize = 13
	count.TextStrokeTransparency = 0.45
	count.ZIndex = 3
	count.Parent = background

	local pips = Instance.new("TextLabel")
	pips.Name = "Pips"
	pips.Size = UDim2.fromScale(1, 0.42)
	pips.BackgroundTransparency = 1
	pips.Font = Enum.Font.GothamBold
	pips.TextColor3 = Color3.fromRGB(255, 90, 105)
	pips.TextSize = 12
	pips.TextStrokeTransparency = 0.4
	pips.Parent = billboard

	local highlight = Instance.new("Highlight")
	highlight.Name = "ImpactPrimedHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Color3.fromRGB(255, 50, 75)
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = Color3.fromRGB(255, 225, 110)
	highlight.OutlineTransparency = 0.05
	highlight.Enabled = false
	highlight.Parent = character
	trove:Add(highlight)

	connectImpact(character, trove, function()
		local impact = character:GetAttribute("Impact") or 0
		local primed = character:GetAttribute("ImpactPrimed") == true
		local protected = character:GetAttribute("ImpactProtected") == true
		fill.Size = UDim2.new(math.clamp(impact / 100, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = impactColor(impact, primed)
		fill.BackgroundTransparency = if protected then 0.35 else 0
		count.Text = tostring(math.round(impact))
		pips.Text = pipText(character)
		highlight.Enabled = primed
		billboard.Enabled = character:GetAttribute("Dead") ~= true
	end)
end

function ImpactDisplay:Init(properties)
	local trove = properties.Trove:Extend()
	local boundCharacters = {}

	bindLocalMeter(properties.UI, trove)

	local function bindCharacter(character: Model)
		if boundCharacters[character] then return end
		boundCharacters[character] = true

		local characterTrove = trove:Extend()
		characterTrove:Add(function()
			boundCharacters[character] = nil
		end)
		characterTrove:Connect(character.Destroying, function()
			characterTrove:Destroy()
		end)

		createOverheadMeter(character, characterTrove)
	end

	local function watchPlayer(player: Player)
		trove:Connect(player.CharacterAdded, bindCharacter)
		if player.Character then
			bindCharacter(player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	trove:Connect(Players.PlayerAdded, watchPlayer)
end

return ImpactDisplay
