Imports Metaphor.Persistence

Friend Class FeaturesModel
    Implements IFeaturesModel

    Private ReadOnly location As ILocation

    Private Sub New(location As ILocation)
        Me.location = location
    End Sub

    Public ReadOnly Property AllVisible As IEnumerable(Of IFeatureModel) Implements IFeaturesModel.AllVisible
        Get
            Return location.Features.Select(AddressOf FeatureModel.Create)
        End Get
    End Property

    Friend Shared Function Create(entity As ILocation) As IFeaturesModel
        Return New FeaturesModel(entity)
    End Function
End Class
