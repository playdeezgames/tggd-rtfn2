Imports Metaphor.Persistence

Friend Module FeatureInitializationExtensions
    Friend Sub InitializeBlueRoomChest(feature As IFeature)
        feature.Inventory.CreateItem(ItemSubtypes.DAGGER, "Dagger", AddressOf ItemInitializationExtensions.InitializeDagger)
    End Sub
End Module
