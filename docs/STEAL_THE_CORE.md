# Steal the Core

## Product hook

Every player owns a floating island with a Power Core that visibly grows in value. Other players can steal only a controlled portion of its current Charge. The thief must physically escape back to their island while carrying a highly visible fragment.

The design goal is to create repeatable social stories:
- theft
- chase
- recovery
- revenge
- rich-island envy
- server-wide events

## Core progression

Evolution names:
- Level 1+: Spark Core
- Level 5+: Reactor Core
- Level 10+: Plasma Core
- Level 20+: Dragon Core
- Level 35+: Black Hole Core
- Level 50: Galaxy Core

Core level increases generation rate and storage capacity.

Players safely convert their own Core Charge to Energy using the Claim prompt. Evolving a Core costs Energy.

## Raid rules

- New/respawned players receive temporary shield protection.
- A thief can carry only one fragment.
- A Core must have enough unreserved Charge before it can be robbed.
- A theft reserves Charge rather than permanently removing it immediately.
- The victim can chase and use RECOVER CORE on the carried fragment.
- The actual victim loss happens only when the thief successfully banks the fragment.
- Each thief has a cooldown before repeatedly targeting the same player.
- Return-home teleporting is disabled while carrying stolen loot.
- Leaving/dying cancels an unfinished raid rather than granting free loot.

## Economy

A successful bank pays more Energy than the raw Charge removed from the victim. This makes raiding exciting while keeping victim loss controlled.

Balance values live under `GameConfig.Raid`.

## Core Meltdown

CORE MELTDOWN is a rotating live event that multiplies Power Core generation. The intention is to create a short server-wide window where every island becomes more valuable at once.

## Next viral layer

After the first multiplayer play-test is stable:
- central timed Mega Core event
- island traps and non-damaging defenses
- revenge target marker
- raid streaks / wanted status
- cosmetic Core skins
- server richest-Core leaderboard
- weekly raid championship
