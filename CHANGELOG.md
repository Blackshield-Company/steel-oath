# Changelog

All notable changes to this project are documented here. Versions follow [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-11-02

Early beta, not yet playtested in game.

### Added
- Kept words: each swearing counts once, the first time it reaches Unbroken. This holds even if an update skips Steadfast. Swearing again resets it.
- Read the ledger, in the main menu: kept and broken counts, longest days held, and a title earned from kept minus broken. The five titles are Oathbreaker (−2 or lower), No name yet (−1 to 0), Keeps their word (1 to 2), A name in the holds (3 to 5) and Their word is good steel (6 or more).
- Sellsword's Token: an amulet given on the first kept oath. It isn't equipped automatically. At 1 / 3 / 6 / 10 kept oaths it grants Speechcraft +5 / +10 / +15 / +20. A carried token upgrades to the Twice-Stitched, Thrice-Stitched or Oath-Heavy Token and stays equipped if worn.
- Struck Token: breaking an oath while carrying a token replaces it with one that gives Speechcraft −10. Keeping the next oath restores the tier for your kept count. Repeated breaks don't stack struck tokens. Sold, stored or lost tokens are not replaced.
- Wronged hold: breaking an oath inside a Skyrim hold adds 100 non-violent bounty there. Outside a hold there is no bounty. If one action breaks more than one oath, each break adds its own bounty.
- Console tunables `SOT_BountyEnabled` (1, set 0 to disable) and `SOT_BountyGold` (100).
- Original short sound motifs for swearing and for breaking an oath. They are synthesized and released under CC0.

### Changed
- Renouncing still has only the cooldown. It adds no broken count, struck token, bounty or break sound.
- Existing saves keep their oath state. Only new transitions to Unbroken count, so oaths that were already Unbroken before upgrading give no kept credit.
- Still no SKSE. The plugin is still ESL-flagged with Skyrim.esm as its only master, and no vanilla records are edited.

## [0.1.2] - 2026-10-25

Still early beta. Built and checked, but not yet played in game (no Skyrim install is available to the build).

### Fixed
- The oath status box (*My oaths*) printed a literal backslash-n instead of starting a new line. Papyrus text now takes its line breaks from a real line-feed character carried by a `LineBreak` property that the plugin fills, and the build fails if any Papyrus string literal or compiled string constant contains a backslash escape.
- Save-compatible: no scripts, properties or records were renamed, and FormIDs are unchanged.

## [0.1.1] - 2026-10-11

Still early beta, not yet playtested in game.

### Changed
- Oath of Close Quarters: Auriel's Bow no longer breaks the oath during Kindred Judgment (Dawnguard), from "Confront Harkon" until the quest ends (DLC1VQ08 stages 40 to 199). The fight needs the bow to break Harkon's blood shield. This applies when you equip it and when you swear the oath. Any other bow, or Auriel's Bow outside that fight, still breaks it. No effect without Dawnguard.

## [0.1.0] - 2026-10-06

Early beta. First public release. It passes every automated check in the build (Papyrus compile, plugin validation, round trip, FOMOD schema) but has not been playtested in-game yet. Please report problems on the Nexus page or on GitHub.

### Added
- Lesser power "Swear an Oath", granted after Helgen. It opens the oath menu: swear, renounce, and review your oaths.
- Five oaths, each a vow the game can actually detect without SKSE:
  - Oath of Steel: cast no spell from your hands and never ready a scroll (Health).
  - Oath of the Shield: keep a shield on your arm, with a 3-second grace for swapping shields (Block).
  - Oath of Iron: wear no light armor, light shields included (Armor).
  - Oath of Endurance: no potions, food or poisons while in combat (Stamina).
  - Oath of Close Quarters: never equip a bow (One-Handed and Two-Handed).
- Up to three oaths at once (`SOT_MaxOaths`).
- Blessings grow while an oath holds: Sworn, then Steadfast after 3 days, then Unbroken after 7 days.
- Breaking an oath: the blessing is lost, you become an Oathbreaker (Health and Stamina −30) for 24 hours, and the oath can't be sworn again for 72 hours. Renouncing has the cooldown but no penalty.
- Event-driven detection through the player alias (OnSpellCast, OnObjectEquipped, OnObjectUnequipped) and single scheduled game-time updates. No polling loops.
- FOMOD installer with optional Papyrus sources.
