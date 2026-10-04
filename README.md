# Power Islands: Steal the Core

**Build. Charge. Raid. Escape. Evolve.**

Power Islands is now built around a social heist loop: every player owns a floating island with a visible Power Core. The Core generates stealable Charge while the player is online. Rivals can cross the raid bridges, steal a fragment, and try to escape home while the owner chases them and attempts to recover it.

## Viral loop

1. Spawn on your personal floating island.
2. Your Power Core generates Charge every second.
3. Claim Charge safely for Energy or spend Energy evolving the Core.
4. Cross the bridges to another player's island.
5. Hold the steal prompt on their Core.
6. A bright stolen fragment becomes visibly attached to you.
7. The owner is alerted and can chase you.
8. If the owner reaches the fragment, they can recover it.
9. If you reach your own green bank pad first, you bank the fragment for bonus Energy.
10. Higher-level Cores generate faster and hold more, making rich islands more tempting raid targets.

## Current systems

- Personal floating islands and connected raid hub
- Persistent evolving Power Cores
- Core generation, capacity and safe claiming
- Core shields and per-target raid cooldowns
- Visible stolen-fragment carry state
- Defender recovery interaction
- Successful-heist bank multiplier
- First-heist quest and achievements
- CORE MELTDOWN live event with accelerated Core generation
- Six adventure worlds
- Companions and pet bonuses
- Jungle Titan boss
- Rebirths and Power Crystals
- Daily rewards, achievements and promo codes
- Parties, friend bonuses, gifting and companion trading
- Game-pass / Developer Product / subscription hooks
- Server-authoritative economy, rate limiting and analytics

## Development setup

This is a Rojo-compatible project.

1. Install Roblox Studio.
2. Install Rojo CLI and the Roblox Studio Rojo plugin.
3. Clone this repository.
4. Run `rojo serve`.
5. Open a blank Baseplate in Roblox Studio.
6. Connect with the Rojo plugin.
7. Press **Play**.

The server dynamically generates both the adventure worlds and the Core Raid Arena.

## First multiplayer test

Use Roblox Studio's multi-client test with at least two players.

- Both players should receive different personal islands.
- Wait for both Cores to accumulate at least 25 Charge.
- Player A crosses to Player B's island.
- Player A steals a Core fragment.
- Player B should see the server-wide theft alert.
- Player B can approach the carried fragment and use **RECOVER CORE**.
- If Player A escapes to their own green bank pad first, the heist completes and Energy is awarded.
- A thief cannot use the Return Home teleport while carrying stolen loot.

See `docs/STEAL_THE_CORE.md` for the full mechanic and `docs/TEST_PLAN.md` for launch QA.

## Monetization

All monetization IDs remain placeholders until the published Roblox experience and products exist. Do not promise players free Robux; purchases are for optional in-game benefits only.
