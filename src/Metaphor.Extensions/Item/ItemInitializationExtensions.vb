Imports Metaphor.Persistence
Imports TGGD.Extensions

Friend Module ItemInitializationExtensions
    Friend Sub InitializeFood(item As IItem)
        item.SetCounter(Counters.STOMACH, RNG.RollDice("4d6"))
        item.CreateVerb(VerbSubtypes.EAT, "Eat")
    End Sub

    Friend Sub InitializeKey(item As IItem)
    End Sub
End Module
