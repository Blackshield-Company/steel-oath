Scriptname SOT_PlayerAliasScript extends ReferenceAlias
{Steel Oath - on the controller quest's Player alias. Forwards the player's
spell casts and equipment changes to the controller, which checks them
against the oaths currently sworn. Event-driven: the only poll is a 3-second
check that runs while a bow is held in a place exempt from the Oath of Close
Quarters, so the bow is put away when the player leaves.}

SOT_OathScript Property Oaths Auto

Event OnSpellCast(Form akSpell)
	Oaths.OnPlayerSpellCast(akSpell)
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	Oaths.OnPlayerEquipped(akBaseObject)
	If Oaths.WatchExemptBow()
		RegisterForSingleUpdate(3.0)
	EndIf
EndEvent

; Only registered while a bow is held in a place exempt from the Oath of Close Quarters.
Event OnUpdate()
	If Oaths.WatchExemptBow()
		RegisterForSingleUpdate(3.0)
	EndIf
EndEvent

Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	Oaths.OnPlayerUnequipped(akBaseObject)
EndEvent
