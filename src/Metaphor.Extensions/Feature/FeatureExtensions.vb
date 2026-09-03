Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module FeatureExtensions
    Private Delegate Sub FeatureDescriber(feature As IFeature)
    Private ReadOnly describers As New Dictionary(Of String, FeatureDescriber) From
        {
        }
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
