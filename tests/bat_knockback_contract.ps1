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

$knockback = Read-RepoFile "ServerScriptService\Weapon\Modules\Knockback.luau"
$explosion = Read-RepoFile "ServerScriptService\Weapon\Modules\Explosion.luau"
$movement = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\Handler.luau"
$knockbackState = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\States\Knockback.luau"
$dazedState = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\States\Dazed.luau"
$stateMachine = Read-RepoFile "StarterPlayer\StarterPlayerScripts\Movement\StateMachine.luau"
$batServer = Read-RepoFile "ServerScriptService\Weapon\Weapons\BaseballBat.luau"
$batClient = Read-RepoFile "StarterPlayer\Weapon\Weapons\BaseballBat.luau"
$weaponConfig = Read-RepoFile "ReplicatedStorage\Assets\Weapons\Data\Config.luau"
$meleeValidator = Read-RepoFile "ServerScriptService\Weapon\Modules\MeleeValidator.luau"

Assert-Contains $knockback "FLAT: boolean?" "Knockback params must expose FLAT for bat-only flattened launch."
Assert-Contains $knockback "local force = params.FORCE or params.IMPULSE or 0" "Knockback API must use minimal FORCE/IMPULSE power."
Assert-Contains $knockback "if params.FLAT then" "Knockback must flatten direction only when requested."
Assert-Contains $knockback "velocity += Vector3.yAxis * params.Y" "Knockback Y must add upward velocity instead of replacing direction Y."
Assert-Contains $knockback "if params.YMAX and velocity.Y > params.YMAX then" "YMAX must only cap upward velocity."
Assert-Contains $knockback "root:ApplyImpulse(velocity * root.AssemblyMass)" "NPC fallback must scale velocity by mass."
Assert-NotContains $knockback "DebugVisualize" "Server knockback must not spawn debug visuals in runtime path."
Assert-NotContains $knockback "print(" "Server knockback must not print in runtime path."
Assert-NotContains $knockback "ControlLock" "Minimal knockback API must not keep ControlLock complexity."

Assert-Contains $explosion "Knockback(Character, rawDirection" "Explosion must pass raw direction into knockback."
Assert-Contains $explosion "YMAX = ExplosionInfo.Y_MAX" "Explosion must cap vertical velocity through YMAX."
Assert-NotContains $explosion "FLAT = true" "Explosion knockback must not flatten direction."
Assert-NotContains $explosion "DebugVisualize" "Explosion runtime path must not require debug visuals."
Assert-NotContains $explosion "print(" "Explosion runtime path must not print damage debug."

Assert-Contains $movement "function Movement:ApplyKnockback(packet)" "Movement must receive knockback packets."
Assert-Contains $movement 'trove:Connect(Events.Knockback.OnClientEvent, function(packet)' "Movement must route knockback remote through Trove."
Assert-Contains $movement 'self.StateMachine:Change("Knockback", data)' "Movement must enter Knockback state."
Assert-NotContains $movement "ControlLock" "Movement knockback packet handling must stay minimal."

Assert-Contains $knockbackState "self.BlockParentInput = true" "Knockback must block parent input while active."
Assert-Contains $knockbackState "self.fsm.CM.ActiveController = self.fsm.AirController" "Knockback must force AirController while active."
Assert-Contains $knockbackState "self.fsm.GroundController.Friction = 0" "Knockback must suppress ground friction while active."
Assert-Contains $knockbackState "segmentSpeed" "Wall daze must use movement segment speed."
Assert-Contains $knockbackState 'self.fsm.StateMachine:Change("Dazed"' "Special wall impact must enter Dazed state."
Assert-NotContains $knockbackState "ControlLock" "Knockback state must not keep ControlLock complexity."

Assert-Contains $dazedState "self.BlockParentInput = true" "Dazed must block parent input."
Assert-Contains $stateMachine "parentInputBlocked" "StateMachine must honor blocked parent input."

Assert-Contains $batServer "FLAT = true" "Bat knockback must request flat horizontal direction."
Assert-Contains $batServer "WALL_DAZE = isSpecial" "Only bat special knockback should enable wall daze."
Assert-Contains $batServer "self.AttackValidator:Cleanup()" "Bat unequip must close validator state."
Assert-NotContains $batServer "print(ok, reason)" "Bat server must not print every hit validation."

Assert-Contains $batClient "[Enum.UserInputType.MouseButton1] = `"StopAttack`"" "Bat M1 release must stop attack loop."
Assert-Contains $batClient "self.SpecialToken" "Bat special waits must guard against stale coroutines."

Assert-Contains $weaponConfig "KNOCKBACK_CHARGE_MULT" "Weapon config must expose special knockback charge scaling."
Assert-Contains $weaponConfig "DAZE_DURATION" "Weapon config must expose daze duration."
Assert-Contains $weaponConfig "WALL_SPEED_MIN" "Weapon config must expose wall daze speed threshold."

Assert-Contains $meleeValidator "self.cfg.Debounce" "Melee validator must use configured debounce."
Assert-NotContains $meleeValidator "Debouncece" "Melee validator debounce typo must be fixed."

Write-Host "Minimal bat knockback contract OK"
