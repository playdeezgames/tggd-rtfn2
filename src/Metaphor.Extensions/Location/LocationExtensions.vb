Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module LocationExtensions
#Region "Description"
    Private Delegate Sub LocationDescriber(location As ILocation)
    Private ReadOnly describers As New Dictionary(Of String, LocationDescriber) From
        {
        }
    <Extension>
    Friend Sub Describe(location As ILocation)
        Dim describer As LocationDescriber = Nothing
        If describers.TryGetValue(location.EntitySubtype, describer) Then
            describer(location)
        End If
        If location.Inventory.HasItems Then
            location.AddMessage("There is stuff on the ground.")
        End If
    End Sub
#End Region
#Region "N00b"
    <Extension>
    Friend Function CreateN00b(location As ILocation, name As String) As ICharacter
        Return location.CreateCharacter(CharacterSubtypes.N00B, name, AddressOf CharacterInitializationExtensions.InitializeN00b)
    End Function
#End Region
#Region "Ink Well"
    <Extension>
    Friend Function CreateInkWell(location As ILocation) As IFeature
        Return location.CreateFeature(FeatureSubtypes.INK_WELL, "Ink Well", AddressOf ItemInitializationExtensions.InitializeInkWell)
    End Function
#End Region
#Region "Door"
    <Extension>
    Friend Function CreateDoor(fromLocation As ILocation, toLocation As ILocation, Optional initializer As FeatureInitializer = Nothing) As IFeature
        Dim feature = fromLocation.CreateFeature(FeatureSubtypes.DOOR, "door", initializer)
        feature.SetDestination(toLocation)
        feature.CreateVerb(VerbSubtypes.ENTER, "Enter")
        feature.CreateVerb(VerbSubtypes.UNLOCK, "Unlock")
        Return feature
    End Function
#End Region
#Region "Key"
    <Extension>
    Friend Function CreateKey(location As ILocation) As IItem
        Return location.Inventory.CreateItem(ItemSubtypes.KEY, "key", AddressOf ItemInitializationExtensions.InitializeKey)
    End Function
#End Region
#Region "Poo Pile"
    <Extension>
    Friend Function GetPooPile(location As ILocation) As IFeature
        Dim feature = location.Features.SingleOrDefault(Function(x) x.EntitySubtype = FeatureSubtypes.POO_PILE)
        If feature Is Nothing Then
            feature = location.CreateFeature(FeatureSubtypes.POO_PILE, "poo pile", AddressOf FeatureInitializationExtensions.InitializePooPile)
        End If
        Return feature
    End Function
#End Region
#Region "Tax Form"
    <Extension>
    Friend Function CreateTaxForm(location As ILocation) As IFeature
        Return location.CreateFeature(FeatureSubtypes.TAX_FORM, "Tax Form", AddressOf FeatureInitializationExtensions.InitializeTaxForm)
    End Function
#End Region
End Module
