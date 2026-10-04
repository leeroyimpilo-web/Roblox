# Power Islands: Steal the Core — Final Build

## Viral Core Loop

- Personal floating island for each player.
- Persistent Power Core that generates Charge.
- Safe Core claiming for Energy.
- Core evolution from Spark to Galaxy.
- Visible rival islands connected to a raid hub.
- Stealable Core fragments.
- Thief must physically escape home.
- Victim can recover the fragment before it is banked.
- Per-target raid cooldowns and spawn/theft shields.
- Revenge targets after successful thefts.
- Wanted raid streaks and public Energy bounties.
- Bounty payouts for catching/raiding wanted players.
- Visible revenge markers.
- Raid score progression.

## Island Defense

- Persistent Pulse Trap level.
- In-world trap upgrade pad.
- Intruders are slowed when the trap triggers.
- Upgrade costs and duration scale by level.
- Trap activations are recorded in player statistics.

## Competitive Systems

- Server raid leaderboard.
- Richest Core ranking.
- Global all-time ordered leaderboard.
- Weekly raid championship.
- Weekly points from heists and Mega Core participation.

## Mega Core Event

- Giant timed Mega Core in the central raid hub.
- Server-wide warning before activation.
- Limited number of drains per event.
- Per-player drain cooldown.
- Energy payouts.
- Weekly championship points.
- Bonus for the top event participant.
- Admin command: /megacore [seconds].

## Core Meltdown Event

- Rotating live event.
- Multiplies personal Core generation.
- Makes every island more valuable at once.
- Admin command: /meltdown [seconds].

## Tutorial / First Session

The onboarding sequence guides the player through:
1. Claim Core Charge.
2. Evolve the Core.
3. Steal a rival fragment.
4. Escape and bank the stolen fragment.

Tutorial completion awards Energy and a Power Crystal.

## Cosmetics

Unlockable Core skins:
- Neon Blue
- Solar Gold
- Toxic Green
- Void Purple
- Galaxy Pink

Unlocks depend on Core level and successful raids.

## Existing Game Systems Retained

- Six adventure worlds.
- Energy and Power progression.
- Companions.
- Jungle Titan boss.
- Rebirths and Power Crystals.
- Daily rewards.
- Achievements.
- Promo codes.
- Parties and friend bonuses.
- Energy gifting.
- Companion trading.
- Live events.
- Monetization hooks.
- Analytics.
- Admin tools.
- Rate limiting and server-authoritative validation.

## Account-side tasks still required

These cannot be completed in source code alone:
- Publish the Roblox experience.
- Create the real Game Passes.
- Create Developer Products.
- Create the optional subscription.
- Paste the actual IDs into GameConfig.
- Add the owner's numeric Roblox UserId to AdminUserIds.
- Upload icon and thumbnails.
- Configure private servers and eligible ads.
- Perform Roblox Studio/runtime tests.
