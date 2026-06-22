# UI Round State Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make UI lifecycle and round leaderboard updates predictable while preserving current screens.

**Architecture:** Add a shared UI bootstrap helper, make loader cleanup prop names consistent, harden menu/death lifecycle cleanup, and route leaderboard mutation through `RoundStateWrite`.

**Tech Stack:** Roblox Luau, Fusion, Trove, Replica, StarterGui LocalScripts, ServerScriptService round modules.

---

## File Structure

- Create `StarterPlayer/Libraries/UIBootstrap.luau`: shared local UI bootstrap helper.
- Modify `StarterGui/MainMenu/Handler.local.luau`: replace duplicate bootstrap setup.
- Modify `StarterGui/CharHUD/Handler.local.luau`: replace duplicate bootstrap setup and preserve death cleanup.
- Modify `StarterGui/GameHUD/Handler.local.luau`: replace duplicate bootstrap setup.
- Modify `StarterGui/GlobalUI/Handler.local.luau`: replace duplicate bootstrap setup.
- Modify `ReplicatedStorage/Utils/Loader.luau`: accept `Trove` and `trove`.
- Modify `StarterGui/MainMenu/MenuHandler.luau`: own UI connections via Trove and guard map camera lookup.
- Modify `StarterGui/GameHUD/DeathHandler.luau`: make click/countdown cleanup idempotent.
- Modify `StarterGui/CharHUD/Vignette.luau`: own hill event connection via scope.
- Modify `StarterGui/CharHUD/ViewportCharacterHandler.luau`: own character descendant connections via scope.
- Modify `StarterGui/GlobalUI/KillFeed/Handler.luau`: own kill event connection via props trove when available.
- Modify `StarterGui/GlobalUI/ExpFeed/Handler.luau`: own exp event connection via props trove when available.
- Modify `ReplicatedStorage/Packages/Replica/RoundStateWrite.luau`: fix leaderboard sort and add safe entry helpers.
- Modify `ServerScriptService/Round/Handler.luau`: remove direct leaderboard replica write.

## Task 1: Shared UI Bootstrap

- [ ] Create `StarterPlayer/Libraries/UIBootstrap.luau` with `Bootstrap(script, options)` that waits for both replicas, builds stable props, and calls `Loader.Load`.
- [ ] Replace four top-level `StarterGui` handlers with calls to `UIBootstrap`.
- [ ] Static verify no top-level UI handler still has duplicated `repeat wait() until replica and roundReplica`.

## Task 2: Loader And Cleanup Props

- [ ] Patch `Loader.Load` to derive cleanup from `shared.Trove or shared.trove`.
- [ ] Keep both `Scope` and `Fusion` aliases in bootstrap props.
- [ ] Static verify modules using `Properties.Scope`, `Properties.Fusion`, `Properties.trove`, and `Properties.Trove` can still receive values.

## Task 3: UI Lifecycle Hardening

- [ ] In `MenuHandler`, use `Properties.Trove` for deploy/menu/shop/remote/map connections.
- [ ] In `DeathHandler`, replace raw `ClickConnection` lifetime with `disconnectClick` and a death token.
- [ ] In CharHUD/GlobalUI modules, put unowned remote/character connections into scope or trove.
- [ ] Static verify known raw connection patterns are reduced in changed files.

## Task 4: Round Leaderboard Contract

- [ ] Fix `RoundStateWrite.SortTeam` to sort entry rows directly by kills, deaths, and user id.
- [ ] Make `InsertLeaderboardEntry` idempotent and bump revision.
- [ ] Make `RemoveLeaderboardEntry` bump revision only when an entry is removed.
- [ ] Replace direct `roundReplica:SetValue` leaderboard write in round handler with `roundReplica:Write("InsertLeaderboardEntry", ...)`.
- [ ] Static verify no direct leaderboard `SetValue` remains in round code.

## Task 5: Stale Component Patch

- [ ] Patch `StarterPlayer/Components/CrateSpinner.luau` so it uses current crate data path and current `ItemTemplate(scope, props)` signature, or leaves a clear no-crash path.
- [ ] Static verify no global `finalX` assignment remains.

## Task 6: Verification

- [ ] Run `rg` checks for stale bootstrap, direct leaderboard writes, cleanup prop drift, and known component mismatch.
- [ ] Report that Roblox Studio runtime verification is still required for deploy/death/menu/round flow.
