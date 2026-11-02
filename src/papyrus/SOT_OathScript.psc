Scriptname SOT_OathScript extends Quest
{Steel Oath - controller. Grants the "Swear an Oath" power after Helgen,
runs the oath menus, tracks how long each oath has been kept, grows its
blessing, and applies the oathbreaker penalty and cooldowns.

Timing is event-driven: one real-time poll while waiting to grant the
power, a 3-second single update after the shield leaves the player's arm
(Oath of the Shield), and a single game-time update scheduled for the next
thing that changes (a blessing tier, a cooldown or the penalty ending).}

GlobalVariable Property SOT_PowerGranted Auto
GlobalVariable[] Property ActiveFlags Auto
GlobalVariable[] Property AvailableFlags Auto
GlobalVariable Property SOT_ActiveCount Auto
GlobalVariable Property SOT_CanSwear Auto
GlobalVariable Property SOT_MaxOaths Auto
GlobalVariable Property SOT_OathsKept Auto
GlobalVariable Property SOT_BountyEnabled Auto
GlobalVariable Property SOT_BountyGold Auto
Armor[] Property Tokens Auto
Armor Property SOT_TokenStruck Auto
Location[] Property HoldLocations Auto
Faction[] Property CrimeFactions Auto
Sound Property SOT_SwearSound Auto
Sound Property SOT_BreakSound Auto
Message[] Property LedgerMessages Auto
Quest Property LedgerQuest Auto
GlobalVariable Property SOT_OathsBroken Auto
GlobalVariable Property SOT_LongestOathDays Auto
GlobalVariable Property SOT_Tier2Days Auto
GlobalVariable Property SOT_Tier3Days Auto
GlobalVariable Property SOT_CooldownHours Auto
GlobalVariable Property SOT_PenaltyHours Auto

Spell[] Property Tier1 Auto
Spell[] Property Tier2 Auto
Spell[] Property Tier3 Auto
Spell Property SOT_AbOathbreaker Auto
Spell Property SOT_PowerOath Auto

Quest Property MQ101 Auto
Race Property WerewolfBeastRace Auto
Keyword Property ArmorLight Auto
Keyword Property ArmorShield Auto
Keyword Property WeapTypeBow Auto

Message Property SOT_MsgIntro Auto
Message Property SOT_MsgMainMenu Auto
Message Property SOT_MsgSwearMenu Auto
Message Property SOT_MsgRenounceMenu Auto
Message[] Property ConfirmMessages Auto

; A single real line-feed character (0x0A), filled by the plugin generator.
; Papyrus string literals cannot hold one, and the build compiler does not expand
; backslash escapes (the text would print a literal backslash and letter), so the
; only escape-free way to break a line in a message box is to carry the character
; in this property. Empty (an old save that predates 0.1.2): Br() falls back to a
; plain space. Never write a backslash in a string literal; the build rejects it.
String Property LineBreak Auto

Int Property OATH_STEEL = 0 AutoReadOnly
Int Property OATH_SHIELD = 1 AutoReadOnly
Int Property OATH_IRON = 2 AutoReadOnly
Int Property OATH_ENDURANCE = 3 AutoReadOnly
Int Property OATH_CLOSE = 4 AutoReadOnly
Int Property OATH_COUNT = 5 AutoReadOnly
Float Property SHIELD_GRACE_SECONDS = 3.0 AutoReadOnly

Bool[] active
Int[] tier
Float[] swornAt
Float[] cooldownUntil
Float breakerUntil = 0.0
Int activeCount = 0
Bool shieldCheckPending = False
Bool swornWordReady = False

; ---------------------------------------------------------------------------
; Startup: grant the power once the player is past Helgen
; ---------------------------------------------------------------------------

Event OnInit()
	InitArrays()
	RegisterForSingleUpdate(10.0)
EndEvent

Function InitArrays()
	If active.Length != OATH_COUNT
		active = new Bool[5]
		tier = new Int[5]
		swornAt = new Float[5]
		cooldownUntil = new Float[5]
	EndIf
EndFunction

Event OnUpdate()
	If SOT_PowerGranted.GetValueInt() == 0
		If CanGrant()
			GrantPower()
		Else
			RegisterForSingleUpdate(30.0)
		EndIf
		Return
	EndIf
	If shieldCheckPending
		shieldCheckPending = False
		CheckShield()
	EndIf
EndEvent

Bool Function CanGrant()
	Actor player = Game.GetPlayer()
	If MQ101 && MQ101.IsRunning() && !MQ101.IsCompleted()
		Return False
	EndIf
	If player.IsInCombat()
		Return False
	EndIf
	If !Game.IsMovementControlsEnabled() || !Game.IsFightingControlsEnabled()
		Return False
	EndIf
	Return True
EndFunction

Function GrantPower()
	SOT_PowerGranted.SetValueInt(1)
	Game.GetPlayer().AddSpell(SOT_PowerOath, False)
	SOT_MsgIntro.Show()
EndFunction

; ---------------------------------------------------------------------------
; Menus
; ---------------------------------------------------------------------------

Function OpenMenu()
	InitSwornWord()
	InitArrays()
	RefreshFlags()
	Bool keepOpen = True
	While keepOpen
		Int choice = SOT_MsgMainMenu.Show(SOT_ActiveCount.GetValue(), SOT_MaxOaths.GetValue(), SOT_OathsBroken.GetValue(), SOT_LongestOathDays.GetValue())
		If choice == 0
			keepOpen = !SwearMenu()
		ElseIf choice == 1
			keepOpen = !RenounceMenu()
		ElseIf choice == 2
			Debug.MessageBox(StatusText())
			keepOpen = False
		ElseIf choice == 3
			ReadLedger()
			keepOpen = False
		Else
			keepOpen = False
		EndIf
	EndWhile
EndFunction

; Returns True when the menu should close.
Bool Function SwearMenu()
	Int choice = SOT_MsgSwearMenu.Show()
	If choice < 0 || choice >= OATH_COUNT
		Return False
	EndIf
	If ConfirmMessages[choice].Show(SOT_Tier2Days.GetValue(), SOT_Tier3Days.GetValue()) != 0
		Return False
	EndIf
	Swear(choice)
	Return True
EndFunction

; Returns True when the menu should close.
Bool Function RenounceMenu()
	Int choice = SOT_MsgRenounceMenu.Show(SOT_CooldownHours.GetValue())
	If choice < 0 || choice >= OATH_COUNT
		Return False
	EndIf
	Renounce(choice)
	Return True
EndFunction

String Function StatusText()
	Float now = Utility.GetCurrentGameTime()
	String text = "YOUR OATHS" + Br()
	Bool any = False
	Int i = 0
	While i < OATH_COUNT
		If active[i]
			any = True
			text += Br() + OathName(i) + ": " + TierName(tier[i]) + ", kept " + DurationText((now - swornAt[i]) * 24.0)
			If tier[i] < 2
				text += ". Next blessing in " + DurationText((swornAt[i] + DaysForTier(tier[i] + 1) - now) * 24.0)
			EndIf
			text += "."
		ElseIf cooldownUntil[i] > now
			any = True
			text += Br() + OathName(i) + ": can be sworn again in " + DurationText((cooldownUntil[i] - now) * 24.0) + "."
		EndIf
		i += 1
	EndWhile
	If breakerUntil > now
		any = True
		text += Br(2) + "Oathbreaker: " + DurationText((breakerUntil - now) * 24.0) + " left."
	EndIf
	If !any
		text += Br() + "You hold no oaths."
	EndIf
	Return text
EndFunction

; aiCount line breaks, for Debug.MessageBox text. Falls back to one space if the
; LineBreak property is empty, so text stays readable and never shows a backslash.
String Function Br(Int aiCount = 1)
	String sep = LineBreak
	If sep == ""
		Return " "
	EndIf
	String result = ""
	Int i = 0
	While i < aiCount
		result += sep
		i += 1
	EndWhile
	Return result
EndFunction

String Function DurationText(Float afHours)
	If afHours < 0.0
		afHours = 0.0
	EndIf
	Int total = Math.Ceiling(afHours)
	Int days = total / 24
	Int hours = total - days * 24
	If days > 0
		Return days + "d " + hours + "h"
	EndIf
	Return hours + "h"
EndFunction

; ---------------------------------------------------------------------------
; Swearing, breaking, renouncing
; ---------------------------------------------------------------------------

Function Swear(Int i)
	InitSwornWord()
	Actor player = Game.GetPlayer()
	If active[i]
		Return
	EndIf
	If activeCount >= SOT_MaxOaths.GetValueInt()
		Debug.MessageBox("You already hold as many oaths as you can keep.")
		Return
	EndIf
	If i == OATH_SHIELD && !player.GetEquippedShield()
		Debug.MessageBox("You need a shield on your arm to swear the Oath of the Shield.")
		Return
	ElseIf i == OATH_IRON && player.WornHasKeyword(ArmorLight)
		Debug.MessageBox("Take off your light armor (light shields included) before you swear the Oath of Iron.")
		Return
	ElseIf i == OATH_CLOSE && HoldsBow(player)
		Debug.MessageBox("Put away your bow before you swear the Oath of Close Quarters.")
		Return
	EndIf
	SOT_SwearSound.Play(player)
	active[i] = True
	tier[i] = 0
	swornAt[i] = Utility.GetCurrentGameTime()
	player.AddSpell(Tier1[i], False)
	RefreshFlags()
	ScheduleTick()
	Debug.Notification("You swear the " + OathName(i) + ".")
EndFunction

Function BreakOath(Int i, String asReason)
	InitSwornWord()
	If !IsActive(i)
		Return
	EndIf
	EndOath(i)
	Float now = Utility.GetCurrentGameTime()
	cooldownUntil[i] = now + SOT_CooldownHours.GetValue() / 24.0
	Float penaltyEnd = now + SOT_PenaltyHours.GetValue() / 24.0
	If penaltyEnd > breakerUntil
		breakerUntil = penaltyEnd
	EndIf
	Actor player = Game.GetPlayer()
	If !player.HasSpell(SOT_AbOathbreaker)
		player.AddSpell(SOT_AbOathbreaker, False)
	EndIf
	SOT_OathsBroken.Mod(1)
	SOT_BreakSound.Play(player)
	ReplaceToken(SOT_TokenStruck, False)
	WrongedHold()
	RefreshFlags()
	ScheduleTick()
	Debug.Notification("Oath broken: " + asReason)
	Debug.Notification("You are an oathbreaker. The " + OathName(i) + " is lost.")
EndFunction

Function Renounce(Int i)
	If !IsActive(i)
		Return
	EndIf
	EndOath(i)
	cooldownUntil[i] = Utility.GetCurrentGameTime() + SOT_CooldownHours.GetValue() / 24.0
	RefreshFlags()
	ScheduleTick()
	Debug.Notification("You renounce the " + OathName(i) + ".")
EndFunction

; Removes the oath and its blessing, and records how long it was kept.
Function EndOath(Int i)
	Actor player = Game.GetPlayer()
	player.RemoveSpell(Tier1[i])
	player.RemoveSpell(Tier2[i])
	player.RemoveSpell(Tier3[i])
	UpdateLongest(Utility.GetCurrentGameTime() - swornAt[i])
	active[i] = False
	tier[i] = 0
EndFunction

Function UpdateLongest(Float afDays)
	Int days = Math.Floor(afDays)
	If days > SOT_LongestOathDays.GetValueInt()
		SOT_LongestOathDays.SetValueInt(days)
	EndIf
EndFunction

; ---------------------------------------------------------------------------
; Game-time schedule: blessing tiers, cooldowns, penalty
; ---------------------------------------------------------------------------

Event OnUpdateGameTime()
	InitSwornWord()
	Float now = Utility.GetCurrentGameTime()
	Actor player = Game.GetPlayer()
	Int i = 0
	While i < OATH_COUNT
		If active[i]
			Float kept = now - swornAt[i]
			Int want = 0
			If kept >= SOT_Tier3Days.GetValue()
				want = 2
			ElseIf kept >= SOT_Tier2Days.GetValue()
				want = 1
			EndIf
			If want > tier[i]
				player.RemoveSpell(TierSpell(tier[i], i))
				player.AddSpell(TierSpell(want, i), False)
				tier[i] = want
				If want == 2
					SOT_OathsKept.Mod(1)
					RewardToken()
				EndIf
				Debug.Notification("Your " + OathName(i) + " holds. The blessing grows: " + TierName(want) + ".")
			EndIf
			UpdateLongest(kept)
		EndIf
		i += 1
	EndWhile
	If breakerUntil > 0.0 && now >= breakerUntil
		breakerUntil = 0.0
		player.RemoveSpell(SOT_AbOathbreaker)
		Debug.Notification("The oathbreaker's shame fades.")
	EndIf
	RefreshFlags()
	ScheduleTick()
EndEvent

; Registers one game-time update for the next moment something changes.
Function ScheduleTick()
	Float now = Utility.GetCurrentGameTime()
	Float nextAt = 0.0
	Int i = 0
	While i < OATH_COUNT
		Float t = 0.0
		If active[i]
			If tier[i] < 2
				t = swornAt[i] + DaysForTier(tier[i] + 1)
			EndIf
		ElseIf cooldownUntil[i] > now
			t = cooldownUntil[i]
		EndIf
		If t > 0.0 && (nextAt == 0.0 || t < nextAt)
			nextAt = t
		EndIf
		i += 1
	EndWhile
	If breakerUntil > 0.0 && (nextAt == 0.0 || breakerUntil < nextAt)
		nextAt = breakerUntil
	EndIf
	If nextAt > 0.0
		Float hours = (nextAt - now) * 24.0
		If hours < 0.05
			hours = 0.05
		EndIf
		RegisterForSingleUpdateGameTime(hours)
	EndIf
EndFunction

Function RefreshFlags()
	Float now = Utility.GetCurrentGameTime()
	Int count = 0
	Bool anyAvailable = False
	Int i = 0
	While i < OATH_COUNT
		If active[i]
			count += 1
			ActiveFlags[i].SetValueInt(1)
			AvailableFlags[i].SetValueInt(0)
		Else
			ActiveFlags[i].SetValueInt(0)
			If cooldownUntil[i] <= now
				AvailableFlags[i].SetValueInt(1)
				anyAvailable = True
			Else
				AvailableFlags[i].SetValueInt(0)
			EndIf
		EndIf
		i += 1
	EndWhile
	activeCount = count
	SOT_ActiveCount.SetValueInt(count)
	If anyAvailable && count < SOT_MaxOaths.GetValueInt()
		SOT_CanSwear.SetValueInt(1)
	Else
		SOT_CanSwear.SetValueInt(0)
	EndIf
EndFunction

; ---------------------------------------------------------------------------
; Detection (called by SOT_PlayerAliasScript)
; ---------------------------------------------------------------------------

Function OnPlayerSpellCast(Form akSpell)
	If activeCount == 0 || !IsActive(OATH_STEEL)
		Return
	EndIf
	If akSpell as Scroll
		BreakOath(OATH_STEEL, "you read a scroll.")
		Return
	EndIf
	Spell cast = akSpell as Spell
	If cast
		; Only spells cast from the hands count. Powers and shouts use the
		; voice slot, staves cast enchantments, and potions are not spells.
		Actor player = Game.GetPlayer()
		If cast == player.GetEquippedSpell(0) || cast == player.GetEquippedSpell(1)
			BreakOath(OATH_STEEL, "you cast a spell.")
		EndIf
	EndIf
EndFunction

Function OnPlayerEquipped(Form akBaseObject)
	If activeCount == 0 || !akBaseObject
		Return
	EndIf
	If IsActive(OATH_STEEL) && (akBaseObject as Scroll)
		BreakOath(OATH_STEEL, "you readied a scroll.")
	EndIf
	If IsActive(OATH_IRON) && (akBaseObject as Armor) && akBaseObject.HasKeyword(ArmorLight)
		BreakOath(OATH_IRON, "you put on light armor.")
	EndIf
	If IsActive(OATH_ENDURANCE) && (akBaseObject as Potion) && Game.GetPlayer().IsInCombat()
		BreakOath(OATH_ENDURANCE, "you took a potion, food or poison in combat.")
	EndIf
	If IsActive(OATH_CLOSE) && (akBaseObject as Weapon) && akBaseObject.HasKeyword(WeapTypeBow) && !IsExemptBow(akBaseObject)
		BreakOath(OATH_CLOSE, "you took up a bow.")
	EndIf
EndFunction

Function OnPlayerUnequipped(Form akBaseObject)
	If activeCount == 0 || !akBaseObject
		Return
	EndIf
	If IsActive(OATH_SHIELD) && (akBaseObject as Armor) && akBaseObject.HasKeyword(ArmorShield)
		; Give the player a moment to swap shields before judging.
		shieldCheckPending = True
		RegisterForSingleUpdate(SHIELD_GRACE_SECONDS)
	EndIf
EndFunction

Function CheckShield()
	If !IsActive(OATH_SHIELD)
		Return
	EndIf
	Actor player = Game.GetPlayer()
	If player.GetRace() == WerewolfBeastRace
		Return
	EndIf
	If !player.GetEquippedShield()
		BreakOath(OATH_SHIELD, "your shield left your arm.")
	EndIf
EndFunction

; ---------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------

; 0.1.1: Kindred Judgment (Dawnguard DLC1VQ08) needs Auriel's Bow to break Harkon's blood shield.
; Auriel's Bow does not break the Oath of Close Quarters while that quest is at stage 40 to 199.
; Without Dawnguard both lookups return None and nothing is exempt.
Bool Function IsExemptBow(Form akWeapon)
	Form auriel = Game.GetFormFromFile(0x000800, "Dawnguard.esm")
	If !auriel || akWeapon != auriel
		Return False
	EndIf
	Quest kj = Game.GetFormFromFile(0x007C25, "Dawnguard.esm") as Quest
	If !kj || !kj.IsRunning()
		Return False
	EndIf
	Int st = kj.GetStage()
	Return st >= 40 && st < 200
EndFunction

Bool Function IsActive(Int i)
	Return active.Length == OATH_COUNT && active[i]
EndFunction

Bool Function HoldsBow(Actor akActor)
	Weapon w = akActor.GetEquippedWeapon(False)
	Return w && w.HasKeyword(WeapTypeBow) && !IsExemptBow(w)
EndFunction

Spell Function TierSpell(Int aiTier, Int i)
	If aiTier == 0
		Return Tier1[i]
	ElseIf aiTier == 1
		Return Tier2[i]
	EndIf
	Return Tier3[i]
EndFunction

Float Function DaysForTier(Int aiTier)
	If aiTier == 1
		Return SOT_Tier2Days.GetValue()
	EndIf
	Return SOT_Tier3Days.GetValue()
EndFunction

String Function TierName(Int aiTier)
	If aiTier == 0
		Return "Sworn"
	ElseIf aiTier == 1
		Return "Steadfast"
	EndIf
	Return "Unbroken"
EndFunction

String Function OathName(Int i)
	If i == OATH_STEEL
		Return "Oath of Steel"
	ElseIf i == OATH_SHIELD
		Return "Oath of the Shield"
	ElseIf i == OATH_IRON
		Return "Oath of Iron"
	ElseIf i == OATH_ENDURANCE
		Return "Oath of Endurance"
	EndIf
	Return "Oath of Close Quarters"
EndFunction

; ---------------------------------------------------------------------------
; The sworn word: ledger, charm and the wronged hold
; ---------------------------------------------------------------------------

; Existing quest instances in saves can retain None for newly added properties.
; Resolve only the v0.2 forms lazily, without resetting any saved oath state.
Function InitSwornWord()
	If swornWordReady
		Return
	EndIf
	SOT_OathsKept = Game.GetFormFromFile(0x000838, "SteelOath.esp") as GlobalVariable
	SOT_BountyEnabled = Game.GetFormFromFile(0x000839, "SteelOath.esp") as GlobalVariable
	SOT_BountyGold = Game.GetFormFromFile(0x00083A, "SteelOath.esp") as GlobalVariable
	SOT_TokenStruck = Game.GetFormFromFile(0x000849, "SteelOath.esp") as Armor
	SOT_SwearSound = Game.GetFormFromFile(0x00084B, "SteelOath.esp") as Sound
	SOT_BreakSound = Game.GetFormFromFile(0x00084D, "SteelOath.esp") as Sound
	LedgerQuest = Game.GetFormFromFile(0x000853, "SteelOath.esp") as Quest
	Tokens = new Armor[4]
	Tokens[0] = Game.GetFormFromFile(0x00083D, "SteelOath.esp") as Armor
	Tokens[1] = Game.GetFormFromFile(0x000840, "SteelOath.esp") as Armor
	Tokens[2] = Game.GetFormFromFile(0x000843, "SteelOath.esp") as Armor
	Tokens[3] = Game.GetFormFromFile(0x000846, "SteelOath.esp") as Armor
	LedgerMessages = new Message[5]
	LedgerMessages[0] = Game.GetFormFromFile(0x00084E, "SteelOath.esp") as Message
	LedgerMessages[1] = Game.GetFormFromFile(0x00084F, "SteelOath.esp") as Message
	LedgerMessages[2] = Game.GetFormFromFile(0x000850, "SteelOath.esp") as Message
	LedgerMessages[3] = Game.GetFormFromFile(0x000851, "SteelOath.esp") as Message
	LedgerMessages[4] = Game.GetFormFromFile(0x000852, "SteelOath.esp") as Message
	HoldLocations = new Location[9]
	HoldLocations[0] = Game.GetFormFromFile(0x016772, "Skyrim.esm") as Location
	HoldLocations[1] = Game.GetFormFromFile(0x01676A, "Skyrim.esm") as Location
	HoldLocations[2] = Game.GetFormFromFile(0x01676C, "Skyrim.esm") as Location
	HoldLocations[3] = Game.GetFormFromFile(0x016770, "Skyrim.esm") as Location
	HoldLocations[4] = Game.GetFormFromFile(0x016769, "Skyrim.esm") as Location
	HoldLocations[5] = Game.GetFormFromFile(0x01676D, "Skyrim.esm") as Location
	HoldLocations[6] = Game.GetFormFromFile(0x01676F, "Skyrim.esm") as Location
	HoldLocations[7] = Game.GetFormFromFile(0x01676E, "Skyrim.esm") as Location
	HoldLocations[8] = Game.GetFormFromFile(0x01676B, "Skyrim.esm") as Location
	CrimeFactions = new Faction[9]
	CrimeFactions[0] = Game.GetFormFromFile(0x0267EA, "Skyrim.esm") as Faction
	CrimeFactions[1] = Game.GetFormFromFile(0x0267E3, "Skyrim.esm") as Faction
	CrimeFactions[2] = Game.GetFormFromFile(0x02816B, "Skyrim.esm") as Faction
	CrimeFactions[3] = Game.GetFormFromFile(0x029DB0, "Skyrim.esm") as Faction
	CrimeFactions[4] = Game.GetFormFromFile(0x02816C, "Skyrim.esm") as Faction
	CrimeFactions[5] = Game.GetFormFromFile(0x02816E, "Skyrim.esm") as Faction
	CrimeFactions[6] = Game.GetFormFromFile(0x028170, "Skyrim.esm") as Faction
	CrimeFactions[7] = Game.GetFormFromFile(0x02816D, "Skyrim.esm") as Faction
	CrimeFactions[8] = Game.GetFormFromFile(0x02816F, "Skyrim.esm") as Faction
	swornWordReady = True
EndFunction

Function ReadLedger()
	InitSwornWord()
	If !LedgerQuest.IsRunning()
		LedgerQuest.Start()
	EndIf
	; Refresh longest even when no further tier update is scheduled.
	Int i = 0
	While i < OATH_COUNT
		If active[i]
			UpdateLongest(Utility.GetCurrentGameTime() - swornAt[i])
		EndIf
		i += 1
	EndWhile
	LedgerQuest.UpdateCurrentInstanceGlobal(SOT_OathsKept)
	LedgerQuest.UpdateCurrentInstanceGlobal(SOT_OathsBroken)
	LedgerQuest.UpdateCurrentInstanceGlobal(SOT_LongestOathDays)
	Int net = SOT_OathsKept.GetValueInt() - SOT_OathsBroken.GetValueInt()
	Int title = 1
	If net <= -2
		title = 0
	ElseIf net >= 6
		title = 4
	ElseIf net >= 3
		title = 3
	ElseIf net >= 1
		title = 2
	EndIf
	LedgerMessages[title].Show()
EndFunction

Function RewardToken()
	Int kept = SOT_OathsKept.GetValueInt()
	Int rank = 0
	If kept >= 10
		rank = 3
	ElseIf kept >= 6
		rank = 2
	ElseIf kept >= 3
		rank = 1
	EndIf
	ReplaceToken(Tokens[rank], kept == 1)
EndFunction

; Lost or sold charms are not replaced. A carried struck charm is restored
; on the next kept oath. Preserve equipment only when a charm was worn.
Function ReplaceToken(Armor akNew, Bool abFirst)
	Actor player = Game.GetPlayer()
	Bool held = False
	Bool worn = False
	Int i = 0
	While i < Tokens.Length
		If Tokens[i] != akNew && player.GetItemCount(Tokens[i]) > 0
			held = True
			If player.IsEquipped(Tokens[i])
				worn = True
			EndIf
			player.RemoveItem(Tokens[i], player.GetItemCount(Tokens[i]), True)
		EndIf
		i += 1
	EndWhile
	If SOT_TokenStruck != akNew && player.GetItemCount(SOT_TokenStruck) > 0
		held = True
		If player.IsEquipped(SOT_TokenStruck)
			worn = True
		EndIf
		player.RemoveItem(SOT_TokenStruck, player.GetItemCount(SOT_TokenStruck), True)
	EndIf
	If held || abFirst
		If player.GetItemCount(akNew) == 0
			player.AddItem(akNew, 1, False)
		EndIf
		If worn
			player.EquipItem(akNew, False, True)
		EndIf
	EndIf
EndFunction

Function WrongedHold()
	If SOT_BountyEnabled.GetValueInt() == 0
		Return
	EndIf
	Location here = Game.GetPlayer().GetCurrentLocation()
	If !here
		Return
	EndIf
	Int i = 0
	While i < HoldLocations.Length
		; IsChild asks whether THIS location descends from the supplied hold.
		If here == HoldLocations[i] || here.IsChild(HoldLocations[i])
			CrimeFactions[i].ModCrimeGold(SOT_BountyGold.GetValueInt(), False)
			Debug.Notification("Word travels. " + HoldName(i) + " has put a price on you.")
			Return
		EndIf
		i += 1
	EndWhile
EndFunction

String Function HoldName(Int i)
	If i == 0
		Return "Whiterun"
	ElseIf i == 1
		Return "Eastmarch"
	ElseIf i == 2
		Return "the Rift"
	ElseIf i == 3
		Return "Haafingar"
	ElseIf i == 4
		Return "the Reach"
	ElseIf i == 5
		Return "the Pale"
	ElseIf i == 6
		Return "Falkreath"
	ElseIf i == 7
		Return "Hjaalmarch"
	EndIf
	Return "Winterhold"
EndFunction
