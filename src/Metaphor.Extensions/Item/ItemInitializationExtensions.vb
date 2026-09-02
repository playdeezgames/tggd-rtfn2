Imports Metaphor.Persistence

Friend Module ItemInitializationExtensions
    Friend Sub InitializeDagger(item As IItem)
        item.SetCounter(Counters.EQUIP_FLAGS, EquipFlags.MAIN_HAND)
        item.SetTag(Tags.WEAPON)
        item.SetCounter(Counters.ATTACK, 3)
        item.SetCounter(Counters.ATTACK_CAP, 1)
        item.SetCounter(Counters.DEFEND, 0)
        item.SetCounter(Counters.DEFEND_CAP, 0)
        item.CreateVerb(VerbSubtypes.EQUIP, "Equip")
        item.CreateVerb(VerbSubtypes.UNEQUIP, "Unequip")
    End Sub
End Module
