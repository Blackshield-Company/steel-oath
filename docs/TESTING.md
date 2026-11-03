# In-game test checklist (v0.2.1, early beta)

v0.2.1 ships as an early beta. It passed every automated build check but hasn't been played in-game yet. This checklist is for players and testers who want to confirm everything works, and for the next round of fixes.

Open the console with `~`. Commands that take a quest or global accept the EditorID directly. `player.addspell` needs a full FormID, which depends on your load order, so look it up first:

```
help "Swear an Oath" 4         -> e.g. SPEL: (FE01581E) 'Swear an Oath'
```

ESL-flagged plugins show up as `FE` + a 3-digit slot (`xxx`) + the record's own 3 digits. The record IDs are:

| Record | Local ID | Full FormID |
|---|---|---|
| Swear an Oath (lesser power) | 81E | `FExxx81E` |
| Blessings, Sworn: Steel, Shield, Iron, Endurance, Close Quarters | 81F to 823 | `FExxx81F` … |
| Blessings, Steadfast | 824 to 828 | `FExxx824` … |
| Blessings, Unbroken | 829 to 82D | `FExxx829` … |
| Oathbreaker | 82E | `FExxx82E` |

Globals: `SOT_ActiveSteel`, `SOT_ActiveShield`, `SOT_ActiveIron`, `SOT_ActiveEndurance`, `SOT_ActiveClose`, `SOT_ActiveCount`, `SOT_OathsBroken`, `SOT_LongestOathDays`, plus the tunables `SOT_MaxOaths`, `SOT_Tier2Days`, `SOT_Tier3Days`, `SOT_PenaltyHours`, `SOT_CooldownHours`.

**Turn on Papyrus logging before testing.** Add this to `Skyrim.ini` (under Proton: `.../compatdata/489830/pfx/drive_c/users/steamuser/Documents/My Games/Skyrim Special Edition/Skyrim.ini`):

```ini
[Papyrus]
bEnableLogging=1
bEnableTrace=1
bLoadDebugInformation=1
```

The log is written to `.../My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`. After each session, run `grep -n "SOT_" Papyrus.0.log` and report anything it finds.

Tip: to fast-forward game time, `set timescale to 2000` for a few seconds, then `set timescale to 20`. Or wait/sleep.

---

## 0. Plugin loads
- [ ] `SteelOath.esp` is enabled and the game reaches the main menu.
- [ ] Load a save past Helgen. Within about a minute, the "weight of old vows" message appears and **Swear an Oath** is in Magic > Powers. `sqv SOT_OathQuest` shows the quest running.
- [ ] New game: the power does not arrive during Helgen, and arrives soon after.
- [ ] With the other mods in the series installed, all plugins load.

## 1. Menus
- [ ] Cast the power. The menu shows active 0 / 3, broken 0, longest 0 days, and *Swear an oath / My oaths / Read the ledger / Close*. *Renounce* is hidden.
- [ ] *Swear an oath* lists all five oaths and *Back*. Each opens a confirmation with the vow and blessing (days filled in as 3 and 7). *Back* returns.
- [ ] *My oaths* says "You hold no oaths."

## 2. Swearing
- [ ] Swear the **Oath of Steel**. "You swear the Oath of Steel." appears, *Oath of Steel (Sworn)* is in Active Effects (Health +20), and it's gone from the swear list.
- [ ] With no shield, choose **Oath of the Shield**: refused with a message. Equip a shield and it works.
- [ ] Wearing any light armor (or a light shield), **Oath of Iron** is refused. In heavy armor or clothes, it works.
- [ ] With a bow equipped, **Oath of Close Quarters** is refused.
- [ ] With three oaths active, *Swear an oath* is hidden in the main menu.

## 3. Breaking each oath
For each: confirm the "Oath broken: …" notification, the blessing disappears from Active Effects, **Oathbreaker** (Health −30, Stamina −30) appears, and `show SOT_OathsBroken` goes up by one.

- [ ] **Steel**: cast a spell from either hand → broken. Separately: shouting, using a lesser power (e.g. a racial power), using a staff, drinking a potion do **not** break it. Equipping a scroll breaks it.
- [ ] **Shield**: unequip the shield → broken about 3 seconds later. Swapping directly to another shield does **not** break it. Equipping a two-handed weapon (which removes the shield) breaks it.
- [ ] **Iron**: put on a light armor piece → broken. Heavy pieces and clothes don't.
- [ ] **Endurance**: drink a potion or eat food in combat → broken. Outside combat, nothing happens. Also try applying a poison in combat and report whether it broke the oath.
- [ ] **Close Quarters**: equip a bow → broken. Swords, axes, daggers and staves don't.

## 4. Growth, penalty, cooldown
- [ ] `set SOT_Tier2Days to 0.1` and `set SOT_Tier3Days to 0.2`, swear an oath, then wait 3 hours. "The blessing grows: Steadfast" appears and the Active Effects entry updates. Wait 2 more hours: Unbroken. (Set them back to 3 and 7 afterwards.)
- [ ] After breaking an oath, *My oaths* shows the cooldown and the oathbreaker time left. Wait 24 hours: "The oathbreaker's shame fades." and the debuff is gone. The oath shows up in the swear list again after 72 hours.
- [ ] Breaking a second oath while still an oathbreaker resets the penalty to a fresh 24 hours (it doesn't stack twice).
- [ ] *Renounce an oath*: lists only active oaths. Renouncing removes the blessing with no Oathbreaker effect, and the cooldown applies.
- [ ] `show SOT_LongestOathDays` reflects your longest-held oath in whole days.

## 5. Werewolf (if available)
- [ ] With the Shield oath, transform into a werewolf. The oath is not broken.

## 6. Persistence
- [ ] Save with active oaths, a cooldown and the penalty running. Quit to desktop, reload. Blessings stay, the next tier still arrives, and the penalty still ends on time.

## 7. v0.1.2 checks (not yet run in game)
- [ ] Swear two oaths, break a third (so a cooldown and the oathbreaker penalty run), then open *My oaths*: the title, each oath and cooldown, and the oathbreaker line each sit on their own line, with a blank line before the oathbreaker line. No `\n` or backslash text anywhere.
- [ ] With no oaths and no cooldowns, *My oaths* shows the title and "You hold no oaths." on separate lines.
- [ ] If the box shows one long line instead, the `LineBreak` property is empty (a save from before 0.1.2 that kept the old script). The text is still readable; please report it.

## Stuck? Reset commands
```
player.removespell FExxx82E       (remove Oathbreaker)
set SOT_MaxOaths to 3
stopquest SOT_OathQuest           (then startquest SOT_OathQuest: resets all oath state;
                                   remove leftover blessings with player.removespell)
```


## 8. Kept words and ledger
- [ ] On a fresh save, Read the ledger shows kept 0, broken 0, longest 0 and “No name yet”. All numbers render, with no literal Global tags.
- [ ] With tier days 0.1 / 0.2, reach Unbroken: kept increments once. Wait longer, reopen the menu, save/reload: no extra credit. Renounce, wait cooldown, swear again and reach Unbroken: exactly one more credit.
- [ ] Wait directly past both tiers: one kept credit. Keep three simultaneous oaths: one credit per oath.
- [ ] Breaking or renouncing before Unbroken gives no kept credit. Breaking after Unbroken leaves the earned count intact.
- [ ] For title boundaries, set kept/broken to produce net −3, −2, −1, 0, 1, 2, 3, 5, 6, 7. Reopen the ledger each time; compare the DESIGN title table. Restore real counts afterwards.
- [ ] Hold an Unbroken oath for further whole days and read the ledger: longest updates even with no further tier timer.
- [ ] Upgrade 0.1.1 and 0.1.2 saves: existing blessings remain, new transitions count once, already Unbroken oaths do not gain retroactive credit. Open the ledger before and after a reload; all three numbers resolve. Test swearing, breaking in a nested hold location, bounty, sounds, and the first token award without restarting the controller quest.

## 9. Tokens
Use a disposable save and short tier/cooldown tunables. To reach boundaries quickly,
set kept to one below the boundary, then keep a newly sworn oath (console count edits
alone do not award tokens).
- [ ] First kept oath: one Sellsword's Token appears with an inventory notification; it is not auto-equipped. Inspect, drop and pick it up: vanilla necklace model is visible.
- [ ] Equip it: amulet slot, Speechcraft +5. Another necklace replaces it normally.
- [ ] Reach kept 3, 6, 10: old token is removed, correct token added, Speechcraft +10/+15/+20. Test worn and unworn upgrades; only worn upgrades re-equip.
- [ ] Break with each token carried: Struck Token replaces it; if worn, remains worn with Speechcraft −10. Repeated breaks never duplicate it.
- [ ] Keep another oath: struck becomes the proper tier for current kept, with worn state preserved. Repeat restoration below and across a tier boundary.
- [ ] Sell a token to a jewelry merchant without the Merchant perk. Store, sell or drop the token, then keep/break: no replacement appears and stored token is untouched.
- [ ] Renounce with a token: no strike or other token changes.

## 10. Wronged holds and motif
- [ ] In each of the nine holds, note its current non-violent bounty, swear then break an oath. Only that hold gains 100; notification names the hold. Test a city interior and a nested dungeon as well as outdoors.
- [ ] Test a location outside the nine holds (and a location-less test cell): no bounty and no hold notification.
- [ ] Set bounty gold to 25: next break adds 25. Set enabled to 0: no bounty/hold notification, but token strike, broken count and penalty still happen. Restore defaults 100 / 1.
- [ ] Renounce: no bounty, strike or break sound. Failed swearing: no swear sound.
- [ ] Successful swear plays the swear motif once; actual break plays the break motif once. Listen for clipping or excessive volume alongside normal SFX; test with SFX volume reduced.
- [ ] Inspect installed archive: both WAVs under `00 Core/Sound/fx/SteelOath/`, installed by required core. Save/reload with a worn struck token: effect persists and next kept oath restores it.
