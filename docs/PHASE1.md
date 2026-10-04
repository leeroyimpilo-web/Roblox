# Phase 1: Starter Island vertical slice

## Player flow

1. Spawn on Starter Island.
2. Walk to glowing Energy nodes and collect them.
3. Each node rewards `BaseReward × Power` Energy.
4. Visit the orange Power Station.
5. Spend Energy to increase Power.
6. Higher Power increases every future node reward.

This creates the first complete progression loop without any paid requirement.

## Server authority

All profile state lives on the server. Proximity prompts fire on the server, collection distance is checked again, and each player/node pair has a cooldown. The client receives a sanitized state snapshot for UI only.

## Data

Player data includes Energy, Power Crystals, Power, Rebirths, unlocked worlds, companions, daily streak fields, playtime and lifetime statistics. Missing fields are reconciled against the current default profile when old saves load.

## Next implementation target

Build the companion system and Jungle Island unlock so the first 10–20 minutes have collection, upgrades, a world target, and a meaningful reward reveal.
