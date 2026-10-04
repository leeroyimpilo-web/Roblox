# Power Islands

Power Islands is a mobile-first Roblox simulator + tycoon + adventure game built around collection, companions, world progression, boss fights, social play, rebirths, live events and legitimate Roblox monetization.

## Status

The planned Phase 1–8 codebase is implemented in this repository.

### Gameplay
- Six worlds: Starter, Jungle, Ice, Volcano, Cyber City and Space
- Energy collection and scaling Power upgrades
- Sequential world unlocks
- Five companion rarities and equip slots
- Visual companion followers
- Jungle Titan co-op boss
- Rebirths and permanent Power Crystal multipliers
- Quests, achievements, promo codes and daily streak rewards
- Rotating live Energy events

### Social
- Friend co-play bonus
- Server parties and party reward bonus
- Party Energy gifting
- Companion trade request / offer / dual-confirm flow

### Monetization
- VIP pass hook
- Double Energy pass hook
- Extra Companion Slots pass hook
- Hoverboard entitlement, speed benefit and visual
- Repeatable Energy products
- Server Boost product
- Instant Rebirth product
- VIP Club subscription hook
- Server-side Developer Product receipt processing

Roblox Creator Hub IDs are intentionally set to placeholders until the published experience and products exist.

### Operations
- Server-side rate limiting and validation
- Persistent player data with backward-compatible reconciliation
- Roblox analytics wrappers
- Admin allow-list and live-event commands
- Launch checklist, test plan, monetization setup and store copy

## Core loop

**Collect → Upgrade → Hatch → Unlock → Fight → Socialize → Rebirth → Repeat**

## Development setup

This is a Rojo-compatible project.

1. Install Roblox Studio.
2. Install Rojo CLI and the Roblox Studio Rojo plugin.
3. Clone this repository.
4. Run `rojo serve` in the repository folder.
5. Open a blank Baseplate in Roblox Studio.
6. Connect using the Rojo plugin.
7. Press **Play**.

For DataStore testing, use a published test experience and enable Studio API access only when appropriate.

## Before publishing

Read:
- `docs/PHASES_COMPLETE.md`
- `docs/MONETIZATION_SETUP.md`
- `docs/LAUNCH_CHECKLIST.md`
- `docs/TEST_PLAN.md`
- `docs/LIVEOPS.md`
- `docs/STORE_COPY.md`

The remaining steps require the Roblox Creator account: publishing the experience, creating passes/products/subscription, inserting their IDs, setting the admin Roblox UserId, configuring private servers/eligible ads, and uploading the final icon/thumbnails.
