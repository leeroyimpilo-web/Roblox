# Monetization Setup

The monetization code is installed, but Roblox-specific IDs must come from the published experience in Creator Hub.

## 1. Publish the experience first

Publish the Power Islands place to the Roblox account/group that will own the experience.

## 2. Create passes

Create these passes and paste each numeric pass ID into `GameConfig.Monetization.Passes`:

- `VIP` — code benefit: +20% Energy
- `DoubleEnergy` — code benefit: x2 Energy
- `ExtraCompanionSlots` — code benefit: +2 equipped companion slots
- `Hoverboard` — code benefit: faster movement plus hoverboard visual

Do not use asset IDs where Roblox expects the pass ID.

## 3. Create developer products

Create these repeatable Developer Products and paste their numeric IDs into `GameConfig.Monetization.Products`:

- `Energy5K` — grants 5,000 Energy
- `Energy50K` — grants 50,000 Energy
- `ServerBoost` — activates a ten-minute Power Surge
- `InstantRebirth` — performs a rebirth immediately

Developer Products are granted through the server-side receipt callback. Do not grant them from a purchase-finished client event.

## 4. Create optional VIP Club subscription

Create a subscription and paste its string ID, for example `EXP-12345678`, into:

```lua
GameConfig.Monetization.SubscriptionId = "EXP-12345678"
```

The current benefit is +10% Energy while subscribed. Subscription status is checked server-side and refreshed when Roblox reports a status change.

## 5. Private servers

Configure private server availability and pricing in Creator Hub. No custom code is required for basic Roblox private-server sales.

## 6. Shop / pricing

Start with simple, understandable offers. Do not promise free Robux. Power Islands sells in-game benefits and progression only.

Use Roblox's product analytics and price optimization after the game has enough real purchase data.

## 7. Ads

Rewarded video and immersive ad availability depends on experience/account eligibility and Roblox-side setup. Enable these only after the experience is eligible and the placement can be tested without disrupting the core loop.

## Receipt testing

Before launch:
- Test each configured product in a published test experience.
- Verify the reward is granted once.
- Rejoin and confirm persistent rewards are saved.
- Test cancelled prompts.
- Test a server restart after purchase.
- Review Developer Product analytics in Creator Hub.
