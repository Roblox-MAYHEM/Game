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

$handler = Read-RepoFile "ServerScriptService\Data\Handler.luau"
$uiBootstrap = Read-RepoFile "StarterPlayer\Libraries\UIBootstrap.luau"
$characterHandler = Read-RepoFile "StarterPlayer\StarterPlayerScripts\CharacterHandler.local.luau"

Assert-Contains $handler 'local PlayerDataToken = ReplicaServer.Token("PlayerData")' "Server data handler must define one reusable PlayerData replica token."
Assert-Contains $handler "Token = PlayerDataToken," "Player data replicas must reuse PlayerDataToken instead of making per-player tokens."
Assert-Contains $handler "Tags = { UserId = plr.UserId }," "Player data replicas must identify owner with Tags.UserId."
Assert-NotContains $handler 'ReplicaServer.Token("Player_"' "Per-player ReplicaServer.Token calls cause duplicate token errors on same-server rejoin."

Assert-Contains $uiBootstrap 'Replica.OnNew("PlayerData", function(rep)' "UI bootstrap must observe shared PlayerData token."
Assert-Contains $uiBootstrap "if rep.Tags.UserId == Player.UserId then" "UI bootstrap must filter PlayerData replicas by local UserId tag."
Assert-NotContains $uiBootstrap 'Replica.OnNew(`Player_{Player.UserId}`' "UI bootstrap must not wait on old per-user token."

Assert-Contains $characterHandler 'Replica.OnNew("PlayerData", function(rep)' "Character handler must observe shared PlayerData token."
Assert-Contains $characterHandler "if rep.Tags.UserId == Player.UserId then" "Character handler must filter PlayerData replicas by local UserId tag."
Assert-NotContains $characterHandler 'Replica.OnNew(`Player_{Player.UserId}`' "Character handler must not wait on old per-user token."

Write-Host "Player data replica contract OK"
