# Mayhem

- Combat builds Impact, then creates launches and ring-out opportunities. Position and recovery matter more than stun.
- Movement uses Roblox controllers and impulses. `Handler` owns normal locomotion; `Actions` own temporary movement such as vault, wallrun, knockback, lunge, and stomp.
- Weapons own their feel and data. Shared bases only load data, equip, and route events.
- Keep APIs direct. Add a system only when a current caller needs it.

## Cleanup

- Camera is the only FOV writer; movement supplies its speed boost.
- Movement owns speed lines. PlayerEffects owns hit feedback and effect playback.
- Effects may be a module or a folder with `init`.
- Keep shared data and UI setup single-source.
