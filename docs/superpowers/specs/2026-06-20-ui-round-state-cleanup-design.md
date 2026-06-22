# UI Round State Cleanup Design

## Goal

Make round UI, menu UI, death UI, and leaderboard updates smaller, more predictable, and easier to maintain without redesigning the visible UI.

## Scope

This pass covers the UI bootstrap/lifecycle layer and the server round-state write contract. It does not redesign screens, replace Fusion, or rebuild movement/weapon systems.

## Current Problems

- `MainMenu`, `CharHUD`, `GameHUD`, and `GlobalUI` repeat the same replica wait and loader setup.
- UI props are inconsistent: some modules receive `Scope`, some receive `Fusion`, and cleanup uses lowercase `trove` while `Loader` checks uppercase `Trove`.
- Global UI state is split across menu code, death code, remotes, and round replica data.
- Several UI event connections are not owned by a cleanup object.
- Leaderboard writes are inconsistent: some go through `RoundStateWrite`, while one path writes directly to the replica.
- Leaderboard sorting uses entries as indexes and writes a `sorted` field that does not represent sorted player rows.

## Architecture

Add a small shared UI bootstrap helper in `StarterPlayer/Libraries/UIBootstrap.luau`. Each top-level `StarterGui` handler uses it to create one `Trove`, one Fusion scope, wait for player and round replicas, and call `Loader.Load` with a stable props table.

Patch `Loader.Load` to understand both `Trove` and `trove`, keeping old modules working while allowing a cleaner convention. Modules that create connections should use the provided cleanup object or their local Fusion scope.

Patch round state writes so leaderboard mutation goes through `RoundStateWrite`. The write lib owns leaderboard insert/remove/increment/sort behavior. UI can react to replica writes and full replica changes instead of relying on mixed server writes.

## Data Flow

Server round code writes round phase, scores, winner, movement, player enable state, and leaderboard through `RoundStateWrite`.

Top-level UI handlers receive:

- `Player`
- `Shared`
- `Client`
- `UI`
- `Scope`
- `Fusion`
- `Replica`
- `RoundReplica`
- `Trove`
- `trove`

Feature modules render from these props. Menu/death deploy buttons may invoke `DeployRequest`, but cleanup and screen state must be idempotent.

## Error Handling

Bootstrap waits for replicas with `task.wait()` and always calls `Replica.RequestData()`. Death UI uses a per-enable token so old countdowns and click handlers cannot affect a newer death screen. Disconnect helpers check for nil connections before disconnecting.

Round write functions validate team/player inputs and no-op on bad data rather than mutating malformed leaderboard state.

## Testing

No Roblox test runner is present in this repo. Verification for this pass is static:

- search for stale duplicate bootstrap patterns
- search for unsafe direct leaderboard writes
- search for known stale `CrateSpinner` API mismatch
- inspect changed files for consistent props and cleanup names

Runtime verification still needs Roblox Studio:

- join/deploy/die/respawn/return to menu
- open leaderboard before and after kills
- complete countdown/round/end flow
- open existing crate flow if crates are available
