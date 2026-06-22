$ErrorActionPreference = "Stop"

function Read-RepoFile {
	param([string]$Path)
	return Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot "..\$Path")
}

function Assert-Contains {
	param(
		[string]$Content,
		[string]$Needle,
		[string]$Message
	)

	if (-not $Content.Contains($Needle)) {
		throw $Message
	}
}

function Assert-NotContains {
	param(
		[string]$Content,
		[string]$Needle,
		[string]$Message
	)

	if ($Content.Contains($Needle)) {
		throw $Message
	}
}

$config = Read-RepoFile "ReplicatedStorage\Assets\Weapons\Data\Config.luau"
$info = Read-RepoFile "ReplicatedStorage\Assets\Weapons\Data\Info.luau"
$list = Read-RepoFile "ReplicatedStorage\Assets\Weapons\List.luau"
$template = Read-RepoFile "ServerScriptService\Data\Template.luau"
$dataHandler = Read-RepoFile "ServerScriptService\Data\Handler.luau"
$clientClassic = Read-RepoFile "StarterPlayer\Weapon\Weapons\ClassicSword.luau"
$serverClassic = Read-RepoFile "ServerScriptService\Weapon\Weapons\ClassicSword.luau"
$clientGreat = Read-RepoFile "StarterPlayer\Weapon\Weapons\GreatSword.luau"
$serverGreat = Read-RepoFile "ServerScriptService\Weapon\Weapons\GreatSword.luau"
$clientHandler = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Weapon.luau"
$serverHandler = Read-RepoFile "ServerScriptService\Weapon\Handler.luau"
$loadout = Read-RepoFile "StarterGui\MainMenu\Loadout.luau"
$hudHotbar = Read-RepoFile "StarterGui\CharHUD\Hotbar.luau"
$itemTemplate = Read-RepoFile "StarterPlayer\Components\ItemTemplate.luau"

Assert-Contains $config '["ClassicSword"]' "ClassicSword config must exist."
Assert-Contains $config 'GRIP_OUT' "ClassicSword config must expose lunge grip offset."
Assert-Contains $config 'FLOAT_VELOCITY' "ClassicSword config must expose lunge float velocity."
Assert-Contains $config 'COMBO_WINDOW' "ClassicSword config must expose double-click lunge timing."
Assert-Contains $config '["GreatSword"]' "GreatSword config must exist."
Assert-Contains $config 'SLOT_COST = 3' "GreatSword config must consume three slots."
Assert-Contains $info '["ClassicSword"]' "ClassicSword info must exist."
Assert-Contains $info '["GreatSword"]' "GreatSword info must exist."
Assert-Contains $info 'SLOT_COST = 3' "GreatSword info must expose slot cost for UI."
Assert-Contains $list '"ClassicSword"' "ClassicSword must appear in weapon list."
Assert-Contains $list '"GreatSword"' "GreatSword must appear in weapon list."

Assert-Contains $clientClassic 'function Weapon:Lunge()' "ClassicSword client must implement lunge."
Assert-Contains $clientClassic 'self:_SetGrip(self.LungeInfo.GRIP_OUT)' "ClassicSword lunge must set sword-forward grip."
Assert-Contains $clientClassic 'ApplyImpulse' "ClassicSword lunge must float/launch the player locally."
Assert-Contains $clientClassic 'self.States.Equipped = true' "ClassicSword must become equipped before attack input is accepted."
Assert-NotContains $clientClassic 'print(' "ClassicSword client must not keep debug prints."
Assert-Contains $serverClassic 'self.LungeValidator = MeleeValidator.new' "ClassicSword server must use separate lunge validator."
Assert-Contains $serverClassic 'SOURCE = "ClassicSwordLunge"' "ClassicSword lunge must apply identifiable knockback."

Assert-Contains $clientGreat 'function Weapon:CanUnequip()' "GreatSword client must expose unequip lock."
Assert-Contains $clientGreat 'self.States.HeavyAttacking' "GreatSword client must track heavy attack lock."
Assert-Contains $serverGreat 'function Weapon:CanUnequip()' "GreatSword server must expose unequip lock."
Assert-Contains $serverGreat 'self.HeavyAttacking' "GreatSword server must track heavy attack lock."

Assert-Contains $clientHandler 'CanUnequip' "Client weapon handler must respect unequip lock."
Assert-Contains $serverHandler 'getWeaponSlotCost' "Server weapon handler must validate slot-cost hotbars."
Assert-Contains $serverHandler 'CanUnequip' "Server weapon handler must reject locked weapon swaps."
Assert-Contains $serverHandler 'rejectHotbarEdit' "Server must force replica rollback when hotbar edit is rejected."
Assert-NotContains $serverHandler 'print(' "Server weapon handler must not keep hotbar debug prints."
Assert-Contains $loadout 'getSlotCost' "Loadout UI must understand slot-cost weapons."
Assert-Contains $loadout 'dropStart' "Loadout UI must place large weapons by slot span."
Assert-Contains $loadout 'slotWidth(getSlotCost(weaponName))' "Loadout hotbar tiles must visually span their slot cost."
Assert-Contains $loadout 'SlotCost = getSlotCost(weaponName)' "Loadout inventory must show weapon slot cost."
Assert-Contains $loadout 'normalizeHotbar' "Loadout UI must normalize replica hotbar data into visible slots."
Assert-Contains $loadout 'removeHotbarSlot' "Loadout UI must support dragging weapons off the hotbar."
Assert-Contains $loadout 'shakeHotbar' "Loadout UI must shake hotbar on rejected changes."
Assert-Contains $loadout 'pendingHotbar' "Loadout UI must compare pending edits against replica updates."
Assert-Contains $loadout 'dropPreview' "Loadout UI must show where dragged items will land."
Assert-Contains $hudHotbar 'getSlotCost' "HUD hotbar must understand slot-cost weapons."
Assert-Contains $hudHotbar 'slotWidth(getSlotCost(weaponName))' "HUD hotbar tiles must visually span their slot cost."
Assert-Contains $itemTemplate 'SlotCost' "ItemTemplate must accept slot-cost display data."
Assert-Contains $itemTemplate 'Text = slotCostText' "ItemTemplate must show slot-cost badge text."
Assert-Contains $itemTemplate 'typeof(props.SlotCost) == "number"' "ItemTemplate must handle raw numeric slot costs."
Assert-Contains $itemTemplate 'LOCKED' "ItemTemplate must give locked weapons clear feedback."
Assert-Contains $template '["GreatSword"]' "GreatSword must be in default inventory so it can appear in loadout."
Assert-Contains $dataHandler 'ensureWeapon(profile.Data, "GreatSword")' "Existing profiles must receive GreatSword for loadout use."

Write-Host "Sword weapons contract OK"
