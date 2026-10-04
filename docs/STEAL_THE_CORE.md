# Steal the Core — Final Gameplay Design

## Product hook

Every player owns a floating island with a visible Power Core. The Core produces Charge while the player is online and generates a capped amount while they are away.

Players can safely claim their own Charge, evolve the Core, or raid somebody else.

## The heist

A thief crosses the raid bridges and holds **STEAL FRAGMENT** on another player's Core.

The stolen fragment becomes visibly attached to the thief.

The victim receives an alert and can chase the thief. If the victim gets close enough, they can use **RECOVER CORE** on the carried fragment.

If the thief reaches their green **BANK** pad first, the theft becomes permanent and pays bonus Energy.

## Protection

- New/respawned players receive a temporary Core shield.
- Only part of a Core's current Charge is stealable.
- There is a per-thief/per-target cooldown.
- A thief can carry only one fragment.
- Return-home teleport is blocked while carrying loot.
- Death/leaving cancels unfinished thefts.
- Victim loss occurs only after the thief successfully banks.
- Pulse Traps slow intruders but do no damage.

## Revenge

After a successful heist, the victim receives a temporary revenge target against the thief.

A successful revenge heist pays a multiplier and clears the target.

The revenge target is highlighted locally for the player who owns the revenge contract.

## WANTED system

Successful heists build a raid streak.

At the configured threshold the player becomes **WANTED**.

Wanted players receive a visible world marker and an Energy bounty. Their streak/bounty persists across reconnects.

If a defender catches a WANTED thief while recovering their own fragment, the defender earns the bounty and the thief's WANTED streak resets.

## Power Core evolution

- Spark Core
- Reactor Core
- Plasma Core
- Dragon Core
- Black Hole Core
- Galaxy Core

Higher levels increase generation rate and capacity.

## Cosmetic Core skins

Deterministic unlocks:
- Neon Blue — starter
- Solar Gold — Core Level 5
- Toxic Green — 5 successful raids
- Void Purple — Core Level 20
- Galaxy Pink — Core Level 50

Skins are cosmetic only.

## Pulse Trap

Each personal island contains an upgradeable Pulse Trap.

It is a non-damaging defense that slows intruders temporarily. Higher levels increase the slow duration. It has a server cooldown so it cannot repeatedly trap somebody every physics frame.

## Leaderboards

The game tracks:
- server raid leaders
- richest Cores in the current server
- all-time global raid score
- weekly raid championship score

Successful heists and Mega Core drains add championship points.

## Mega Core

A giant central Mega Core becomes active on a timer.

Players race to the hub and drain it for:
- Energy
- weekly championship points

The player with the most drains during that Mega Core event receives an extra Energy prize.

## Core Meltdown

CORE MELTDOWN temporarily multiplies personal Core generation, creating a short server-wide period where all islands become richer raid targets.

## First-session tutorial

New players are guided through:
1. Claim their Core
2. Evolve the Core
3. Steal a fragment
4. Escape and bank it

Tutorial progress is server-verified and logged through onboarding analytics.

## Saving and security

- session-locked player saves
- capped offline Core generation
- server-authoritative rewards
- rate-limited remote actions
- validated distances and ownership
- receipt idempotency for Developer Products
