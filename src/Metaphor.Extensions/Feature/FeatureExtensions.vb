Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module FeatureExtensions
    Private Delegate Sub FeatureDescriber(feature As IFeature)
    Private ReadOnly describers As New Dictionary(Of String, FeatureDescriber) From
        {
            {FeatureSubtypes.POO_PILE, AddressOf DescribePooPile},
            {FeatureSubtypes.DOOR, AddressOf DescribeDoor},
            {FeatureSubtypes.TAX_FORM, AddressOf DescribeTaxForm}
        }

    Private Sub DescribeTaxForm(feature As IFeature)
        DescribeFeature(feature)
        feature.AddMessage($"Compleness: {feature.GetCounterPercentage(Counters.COMPLETENESS)}")
    End Sub

    Private Sub DescribeDoor(feature As IFeature)
        DescribeFeature(feature)
        If feature.HasTag(Tags.LOCKED) Then
            feature.AddMessage($"{feature.Name} is locked.")
        End If
    End Sub

    Private Sub DescribePooPile(feature As IFeature)
        DescribeFeature(feature)
        feature.AddMessage($"{feature.Name} has {feature.GetCounter(Counters.POO)} poo.")
    End Sub

    Private Sub DescribeFeature(feature As IFeature)
        feature.AddMessage($"This is a {feature.Name}.")
    End Sub
    <Extension>
    Public Sub Describe(feature As IFeature)
        Dim describer As FeatureDescriber = Nothing
        If describers.TryGetValue(feature.EntitySubtype, describer) Then
            describer.Invoke(feature)
        Else
            DescribeFeature(feature)
        End If
    End Sub
#Region "Destination"
    <Extension>
    Friend Sub SetDestination(feature As IFeature, location As ILocation)
        feature.SetYoke(Yokes.DESTINATION, location.EntityId)
    End Sub
    <Extension>
    Friend Function GetDestination(feature As IFeature) As ILocation
        Return feature.World.GetLocation(feature.GetYoke(Yokes.DESTINATION))
    End Function
#End Region
End Module
