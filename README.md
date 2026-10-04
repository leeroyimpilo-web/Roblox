# Power Islands: Steal the Core

**Build. Charge. Raid. Escape. Evolve.**

Power Islands is a social Roblox heist-simulator built around personal floating islands and stealable Power Cores.

## Core loop

1. Spawn on your own floating island.
2. Your Power Core generates Charge.
3. Claim Charge safely for Energy.
4. Evolve the Core so it produces faster and stores more.
5. Cross the bridges to another player's island.
6. Steal part of their Core.
7. Escape while they chase you.
8. Bank the stolen fragment at your own island.
9. Build raid streaks, become WANTED, trigger revenge targets, climb weekly rankings, and repeat.

## Viral systems implemented

- Personal floating islands
- Persistent evolving Power Cores
- Offline Core generation with a cap
- Server-validated Core theft
- Visible carried fragments
- Defender recovery prompt
- Revenge targets with bonus payout
- Persistent WANTED streaks and bounties
- Non-damaging upgradeable Pulse Traps
- Cosmetic Core skins with deterministic unlocks
- Server raid leaderboard
- Richest-Core leaderboard
- Persistent all-time global raid leaderboard
- Weekly raid championship
- Central timed Mega Core event
- CORE MELTDOWN live event
- First-session guided tutorial
- Six adventure worlds
- Companions, boss, quests, daily rewards, achievements, codes
- Parties, friend bonuses, gifting and companion trading
- Rebirths and Power Crystals
- Game-pass, Developer Product and subscription hooks
- Session-locked DataStore saves
- Idempotent Developer Product receipt handling
- Server-side analytics, rate limiting and validation
- Admin/live-ops commands

## Development

This repository is Rojo-compatible.

1. Install Roblox Studio.
2. Install Rojo CLI and the Studio plugin.
3. Clone this repository.
4. Run `rojo serve`.
5. Open a blank Baseplate in Studio.
6. Connect with the Rojo plugin.
7. Use Studio multi-client testing with at least two players.

The server dynamically creates the raid arena, player islands and adventure worlds.

## Creator-account steps still required

Code is complete, but these must be done from the Roblox Creator account:

- Publish the experience
- Create the real passes and Developer Products
- Paste their IDs into `GameConfig.lua`
- Add the owner's numeric Roblox UserId to `AdminUserIds`
- Create the optional subscription and insert its ID
- Configure private servers / eligible ads
- Upload final icon and thumbnails
- Perform Studio/device testing

See the files in `docs/` for monetization, testing, live ops and launch setup.
