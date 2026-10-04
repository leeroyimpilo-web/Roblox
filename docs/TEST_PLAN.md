# Power Islands: Steal the Core — Test Plan

## Minimum setup

Use Roblox Studio multi-client testing with at least two players.

## New-player/tutorial test

1. Both players receive different Core islands.
2. Tutorial says CLAIM YOUR CORE.
3. Claim Core Charge.
4. Confirm +500 tutorial Energy.
5. Evolve the Core once.
6. Tutorial advances to stealing.
7. Steal from the other player.
8. Tutorial advances to escape/bank.
9. Bank the fragment.
10. Confirm tutorial completion reward.

## Core test

- Charge increases over time.
- Charge never exceeds capacity.
- Claiming converts only available/unreserved Charge.
- Core upgrade cost scales.
- Evolution name changes at the configured levels.
- Core skins unlock at the correct requirements.
- Skin changes are cosmetic only.
- Leave/rejoin and confirm Core state persists.
- Simulate time away and confirm offline gain is capped by Core capacity.

## Raid test

- Cannot steal while victim shield is active.
- Cannot steal when victim lacks minimum Charge.
- Cannot carry two fragments.
- Per-target cooldown works.
- Fragment is visibly attached to thief.
- Victim can recover it.
- Death cancels unfinished theft.
- Leaving cancels unfinished theft.
- Thief cannot teleport home while carrying.
- Successful bank removes Charge from victim only at bank time.
- Successful bank awards payout.

## Revenge/WANTED test

- Victim receives revenge target after a completed theft.
- Revenge target highlighting works.
- Revenge heist receives bonus payout.
- Consecutive heists build WANTED streak.
- WANTED marker appears.
- Bounty value increases and respects max cap.
- WANTED state survives reconnect.
- Defender catching a WANTED thief receives bounty.
- Bounty claim resets thief streak.

## Defense test

- Trap Level 0 does not slow.
- Owner can upgrade trap.
- Intruder is slowed when trap fires.
- Owner is never slowed by own trap.
- Trap cooldown prevents repeated rapid triggers.
- Higher levels increase slow duration.
- Trap causes no damage.

## Leaderboard test

- Successful raid adds weekly points.
- Raid score updates server ranking.
- Richest-Core ranking updates.
- Published test experience populates OrderedDataStore weekly/global ranking.
- Hub leaderboard boards update.

## Mega Core test

- Admin `/megacore 120` starts event.
- Central Core activates.
- Drain prompt works.
- Per-player drain cooldown works.
- Drain count decreases.
- Energy reward is granted.
- Weekly points increase.
- Event ends at zero drains or timeout.
- Top drainer receives champion bonus.

## Core Meltdown test

- Admin `/meltdown 180` starts event.
- Personal Core generation multiplier increases.
- HUD displays event.
- Generation returns to normal after event.

## Legacy gameplay

Also test:
- Energy nodes
- Power upgrades
- companions
- Jungle Titan
- six world portals
- rebirths
- daily reward
- codes
- parties
- gifting
- companion trading
- shop prompts
- game passes
- Developer Products
- subscription state

## Data/security failure tests

- Join same account from a second live server and confirm session lock protects data.
- DataStore failure must not silently overwrite a live profile.
- Rapid remote spam is rate-limited.
- Invalid skin IDs are rejected.
- Invalid trade pet UIDs are rejected.
- Developer Product receipt retry does not duplicate rewards.
- Old Phase 1/2 save reconciles new fields safely.

## Device tests

- Android
- iPhone/iPad
- Windows
- small mobile screen
- large desktop screen
- low-end graphics/performance
