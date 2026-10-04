# Power Islands Test Plan

## Smoke test

1. Start a two-player local server.
2. Confirm both players spawn on Starter Island.
3. Collect an Energy node and confirm HUD updates.
4. Spam the prompt and confirm cooldown prevents duplicate rapid rewards.
5. Buy a Power upgrade.
6. Hatch a companion.
7. Open PETS and unequip/re-equip it.
8. Confirm the follower appears.
9. Complete the three starter quests.
10. Redeem LAUNCH twice; the second attempt must fail.
11. Claim the daily reward twice; the second attempt must fail.
12. Reach 5,000 Energy and unlock Jungle.
13. Return to Starter without being charged.
14. Continue through Ice, Volcano, Cyber and Space unlocks.
15. Confirm each later world awards more Energy.
16. Attack the Jungle Titan from outside range; no damage should occur.
17. Defeat the Titan with two players; both participants should receive the reward.
18. Create a party and verify party multiplier.
19. Gift 100 Energy to a party member.
20. Request a companion trade, offer one pet each and confirm from both sides.
21. Cancel a second trade and verify ownership stays unchanged.
22. Rebirth and confirm Energy/Power/world unlock reset while companions and crystals persist.
23. Start each admin event and verify multipliers/banners.
24. Leave and rejoin; verify persistence.
25. Test every configured pass/product/subscription in a published test experience.

## Failure cases

Test:
- DataStore API unavailable
- Player leaves during a trade
- Player leaves during boss fight
- Purchase prompt cancelled
- Product receipt retry
- Party leader leaves
- No other players in server
- Player with no companions
- Max companion slots reached
- Invalid promo code
- Rapid remote spam
