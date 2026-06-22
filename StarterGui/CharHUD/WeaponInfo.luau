local Client = game:GetService("StarterPlayer")

local Fusion = require(Client.Packages.Fusion)
local Children = Fusion.Children

local WeaponObserver = require(script.Parent.Utils.WeaponObserver)

local module = {}

function module:Init(Properties: { Scope: Fusion.Scope, UI: ScreenGui })
	local scope = Properties.Scope:innerScope()
	local UI = Properties.UI

	local weaponNameRaw = scope:Value("")
	local ammoRaw = scope:Value(nil :: number?)
	local magRaw = scope:Value(nil :: number?)

	local ammoText = scope:Computed(function(use)
		local ammo = use(ammoRaw)
		return ammo ~= nil and tostring(ammo) or "0"
	end)

	local magText = scope:Computed(function(use)
		local mag = use(magRaw)
		return mag ~= nil and tostring(mag) or "0"
	end)

	local showAmmo = scope:Computed(function(use)
		return use(ammoRaw) ~= nil
	end)

	WeaponObserver.observe(scope, {
		onReset = function()
			weaponNameRaw:set("")
			ammoRaw:set(nil)
			magRaw:set(nil)
		end,

		onWeapon = function(localScope, weapon)
			weaponNameRaw:set(weapon.Name)

			WeaponObserver.bindValue(localScope, weapon, "Ammo", function(value)
				ammoRaw:set(tonumber(value))
			end)

			WeaponObserver.bindValue(localScope, weapon, "Mag", function(value)
				magRaw:set(tonumber(value))
			end)
		end,
	})

	local WeaponHUD = UI:WaitForChild("WeaponHUD")
	local WeaponNameLabel = WeaponHUD:WaitForChild("WeaponName")
	local AmmoBar = WeaponHUD:WaitForChild("AmmoBar")

	scope:Hydrate(WeaponHUD) {
		[Children] = {
			scope:Hydrate(WeaponNameLabel) {
				Text = weaponNameRaw,
			},

			scope:Hydrate(AmmoBar) {
				Visible = showAmmo,
				[Children] = {
					scope:Hydrate(AmmoBar.Ammo) {
						Text = ammoText,
					},
					scope:Hydrate(AmmoBar.Mag) {
						Text = magText,
					},
				},
			},
		},
	}

	return scope
end

return module