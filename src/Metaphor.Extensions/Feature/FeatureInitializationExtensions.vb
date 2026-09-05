Imports Metaphor.Persistence

Friend Module FeatureInitializationExtensions
    Friend Sub InitializePooPile(feature As IFeature)
        feature.InitializeCounter(Counters.POO, 0, 0, Integer.MaxValue)
    End Sub
End Module
