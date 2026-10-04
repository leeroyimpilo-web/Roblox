# Live Ops and Admin

Admin commands work only for numeric Roblox UserIds listed in `GameConfig.AdminUserIds`.

## Commands

`/event PowerSurge 300`  
Start Power Surge.

`/event LuckyRush 300`  
Start Lucky Rush.

`/event MegaCharge 300`  
Start Mega Charge.

`/event CoreMeltdown 180`  
Start Core Meltdown.

`/meltdown 180`  
Shortcut for Core Meltdown.

`/megacore 120`  
Activate the central Mega Core for 120 seconds.

`/giveenergy 5000`  
Grant Energy to the admin for testing.

`/announce Your message here`  
Show a server-wide announcement.

`/boss`  
Respawn Jungle Titan.

`/rebirth`  
Force an admin rebirth for testing.

## Automatic live systems

Rotating Energy/Core events run from `GameConfig.LiveEvents`.

Mega Core runs on its own timer from `GameConfig.Raid.MegaCore`.

## Weekly championship

Successful heists add weekly points.

Mega Core drains also add points.

OrderedDataStore rankings are refreshed periodically and shown in the raid hub and RANKS UI.

## Suggested operating rhythm

- Weekly: review retention, raid completion, tutorial completion and purchase conversion.
- Weekly: promote championship standings.
- Every 1–2 weeks: balance or content update.
- Major update: add a promo code and themed event.
- Avoid aggressive monetization changes until retention is healthy.
