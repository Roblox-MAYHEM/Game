local TweenService = game:GetService("TweenService")
local Client = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(Client.Packages.Fusion)
local CrateData = require(ReplicatedStorage.Assets.Crates.Data)

local ItemTemplate = require(Client.Components.ItemTemplate)
local CrateSpinnerTemplate = script.Frame

local OpenCrateEvent = ReplicatedStorage.Events.OpenCrate

local REPEAT_COUNT = 4

local Spinner = {}
Spinner.__index = Spinner

function Spinner.new(crateName: string)
	local self = setmetatable({}, Spinner)

	self.CrateName = crateName
	self.Template = CrateSpinnerTemplate
	self.UI = CrateSpinnerTemplate:Clone()
	self.UI.Name = crateName
	self.UI.Visible = true
	self.Scope = Fusion.scoped(Fusion)

	local info = CrateData[crateName]
	if not info then
		warn("Crate not found: " .. crateName)
		return self
	end

	self.ItemHolder = self.UI.ItemHolder
	self.ItemLayer = self.UI.Spinner.ItemLayer
	self.ScrollFrame = self.UI.Spinner
	self.Layout = self.ItemLayer:FindFirstChildOfClass("UIListLayout")

	self.RewardsList = {}
	for rarity, data in pairs(info.CONTENT) do
		for _, weaponName in ipairs(data.REWARDS) do
			table.insert(self.RewardsList, {
				Name = weaponName,
				Rarity = rarity
			})
		end
	end

	self.SpinList = {}
	local layoutIndex = 0

	for i = 1, REPEAT_COUNT do
		for _, reward in ipairs(self.RewardsList) do
			layoutIndex += 1
			local item = ItemTemplate(self.Scope:innerScope(), {
				ItemName = reward.Name,
				Parent = self.ItemLayer,
				LayoutOrder = layoutIndex,
				ShowLevel = false,
			})
			table.insert(self.SpinList, item)
		end
	end

	return self
end

function Spinner:Roll(onFinish: ((string) -> ())?)
	task.spawn(function()
		local _result, confirmedReward = OpenCrateEvent:InvokeServer(self.CrateName)
		if not confirmedReward then
			warn("Server didn't return a reward")
			self.Scope:doCleanup()
			self.UI:Destroy()
			return
		end

		while self.Layout.AbsoluteContentSize.X <= 0 do
			RunService.Heartbeat:Wait()
		end

		local viewWidth = self.ScrollFrame.AbsoluteSize.X
		local contentWidth = self.Layout.AbsoluteContentSize.X
		local loopWidth = contentWidth / REPEAT_COUNT

		local targetOffsetFirst = 0
		local targetWidth = 0

		for i = 1, #self.RewardsList do
			local item = self.SpinList[i]
			local itemWidth = item.AbsoluteSize.X

			if item.Name == confirmedReward then
				targetWidth = itemWidth
				break
			end

			targetOffsetFirst += itemWidth
		end

		local middleLoopIndex = math.floor(REPEAT_COUNT / 2)
		local targetOffsetInFull = targetOffsetFirst + (middleLoopIndex * loopWidth)

		local centerOffset = targetOffsetInFull + (targetWidth / 2) - (viewWidth / 2)
		local finalX = math.clamp(centerOffset, 0, contentWidth - viewWidth)

		local tween = TweenService:Create(
			self.ScrollFrame,
			TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ CanvasPosition = Vector2.new(finalX, 0) }
		)

		tween:Play()
		tween.Completed:Wait()
		
		self.ItemHolder:ClearAllChildren()

		local rewardFrame = ItemTemplate(self.Scope:innerScope(), {
			ItemName = confirmedReward,
			Parent = self.ItemHolder,
			ShowLevel = false,
		})
		rewardFrame.Name = "RewardDisplay"
		rewardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		rewardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		rewardFrame.Visible = true

		if onFinish then
			onFinish(confirmedReward)
		end
		
		task.wait(2)
		self.Scope:doCleanup()
		self.UI:Destroy()
	end)
end

return Spinner
