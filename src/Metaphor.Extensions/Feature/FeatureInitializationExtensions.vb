Imports Metaphor.Persistence

Friend Module FeatureInitializationExtensions
    Friend Sub InitializePooPile(feature As IFeature)
        feature.InitializeCounter(Counters.POO, 0, 0, Integer.MaxValue)
    End Sub

    Friend Sub InitializeTaxForm(feature As IFeature)
        feature.InitializeCounter(Counters.COMPLETENESS, 0, 0, 100)
        feature.CreateVerb(VerbSubtypes.FILL_OUT, "Fill Out")
        feature.CreateVerb(VerbSubtypes.SIGN, "Sign")
    End Sub
End Module
