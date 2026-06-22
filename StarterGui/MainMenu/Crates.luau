local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = game:GetService("RunService")
local Client = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UI: PlayerGui = Player.PlayerGui
local Bindables = Client.Bindables

local MainMenu = UI:WaitForChild("MainMenu")
local CrateFrame = MainMenu:WaitForChild("CrateFrame")
local CrateContainer = CrateFrame.Container

local Events = ReplicatedStorage.Events

local WeaponInfo = require(ReplicatedStorage.Assets.Weapons.Data.Info)
local CrateData = require(ReplicatedStorage.Assets.Crates.Data)
local CrateModels = ReplicatedStorage.Assets.Crates.Models

local OpenAnimation = "rbxassetid://117391872770805"
local OpenHoldAnim = "rbxassetid://124369554461478"

local Fusion = require(Client.Packages.Fusion)
local scoped, peek = Fusion.scoped, Fusion.peek
local Children = Fusion.Children

local scope = scoped(Fusion)
local module = {
	Enabled = scope:Value(false)
}

local crateName, status, thumbnail = scope:Value(""), scope:Value(""), scope:Value("")

scope:Hydrate(CrateFrame) {
	Visible = module.Enabled,
}

scope:Hydrate(CrateContainer) {
	[Children] = {
		scope:Hydrate(CrateContainer.Viewport) {
			[Children] = {
				scope:Hydrate(CrateContainer.Viewport.Icon) {
					Image = scope:Computed(function(use)
						return tostring(use(thumbnail))
					end),
					
					Transparency = scope:Computed(function(use)
						return use(thumbnail) == "" and 1 or 0
					end)
				}
			}
		},

		scope:Hydrate(CrateContainer.CrateName) {
			Text = scope:Computed(function(use)
				return tostring(use(crateName))
			end)
		},

		scope:Hydrate(CrateContainer.Status) {
			Text = scope:Computed(function(use)
				return tostring(use(status))
			end)
		}
	}
}


function module:Init(Properties)
	local Replica = Properties.Replica
	
	module.OpenAllCrates(Replica.Data.Crates)
	Properties.trove:Add(Replica:OnChange(function(action : string, path, p1)
		if action == "TableInsert" and path[1] == "Crates" then
			module.Enabled:set(true)
			module.OpenCrate(p1)
			module.Enabled:set(false)
		end
	end))
end

function module.OpenCrate(crateId : string)
	local crateData = CrateData[crateId]
	local crateModel = CrateModels[crateId]
	
	crateName:set(crateData.NAME)
	status:set("Opening...")
		
	local crate = crateModel:Clone()
	crate.Parent = CrateContainer.Viewport.WorldModel
	
	local anim = Instance.new("Animation")
	anim.AnimationId = OpenAnimation
	local anim2 = Instance.new("Animation")
	anim2.AnimationId = OpenHoldAnim
	
	local track = crate.AnimationController.Animator:LoadAnimation(anim)
	track:Play()
	local openHold = crate.AnimationController.Animator:LoadAnimation(anim2)
		
	local res, weapon = Events.OpenCrate:InvokeServer(crateId)
		
	task.wait(.3)
	openHold:Play()
		
	if weapon and WeaponInfo[weapon] and WeaponInfo[weapon].THUMBNAIL then
		thumbnail:set(WeaponInfo[weapon].THUMBNAIL)
	else
		warn("Missing thumbnail for weapon:", weapon)
		thumbnail:set("") -- ALWAYS a string
	end
	
	if res == "new" then
		status:set(`You got {weapon}!`)
	elseif res == "duplicate" then
		status:set(`You got a duplicate {weapon}. Added 20 xp.`)
	elseif not res then
		status:set("error")
	end
	
	task.wait(1)
	
	crate:Destroy()
	thumbnail:set("")	
end

function module.OpenAllCrates(crates)
	module.Enabled:set(true)
	for _, crate in crates do
		if not peek(module.Enabled) then return end
		module.OpenCrate(crate)
	end
	module.Enabled:set(false)
end

function module.Enable()
	
end

function module.Disable()
	module.Enabled:set(false)
end

return module
