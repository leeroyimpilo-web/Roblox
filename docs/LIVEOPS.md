# Live Ops and Admin

Admin chat commands work only for numeric Roblox UserIds listed in `GameConfig.AdminUserIds`.

## Commands

`/event PowerSurge 300`  
Starts a Power Surge for 300 seconds.

`/event LuckyRush 300`  
Starts Lucky Rush.

`/event MegaCharge 300`  
Starts Mega Charge.

`/giveenergy 5000`  
Grants Energy to the admin for testing.

`/announce Your message here`  
Displays a server-wide announcement banner.

`/boss`  
Immediately respawns the Jungle Titan.

`/rebirth`  
Forces an admin rebirth for testing.

## Promo codes

Configured launch codes:
- LAUNCH
- JUNGLE
- POWERUP

Codes are case-insensitive and can be redeemed once per player.

## Automatic events

A random event starts on the configured interval:
- Power Surge — x2 Energy
- Lucky Rush — x1.5 Energy
- Mega Charge — x3 Energy

Change timing and multipliers in `GameConfig.LiveEvents`.

## Recommended operating rhythm

- Weekly: review retention, funnel and economy metrics.
- Every 1–2 weeks: content or balance update.
- Major updates: add a new code and limited live event.
- Never change saved-data field meaning without a migration/reconciliation plan.
