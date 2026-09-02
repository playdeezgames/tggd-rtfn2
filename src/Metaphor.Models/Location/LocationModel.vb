Imports Metaphor.Persistence

Friend Class LocationModel
    Implements ILocationModel

    Private ReadOnly location As ILocation

    Private Sub New(location As ILocation)
        Me.location = location
    End Sub

    Public ReadOnly Property AvailableVerbs As IEnumerable(Of IVerbModel) Implements ILocationModel.AvailableVerbs
        Get
            Return location.Verbs.Select(Function(x) LocationVerbModel.Create(location, x))
        End Get
    End Property

    Friend Shared Function Create(location As ILocation) As ILocationModel
        Return New LocationModel(location)
    End Function

    Public ReadOnly Property Ground As IGroundModel Implements ILocationModel.Ground
        Get
            Return GroundModel.Create(location)
        End Get
    End Property

    Public ReadOnly Property Features As IFeaturesModel Implements ILocationModel.Features
        Get
            Return FeaturesModel.Create(location)
        End Get
    End Property

    Public ReadOnly Property Characters As ICharactersModel Implements ILocationModel.Characters
        Get
            Return CharactersModel.Create(location)
        End Get
    End Property

    Public ReadOnly Property LocationType As String Implements ILocationModel.LocationType
        Get
            Return location.EntitySubtype
        End Get
    End Property

    Public ReadOnly Property Column As Integer Implements ILocationModel.Column
        Get
            Return location.Column
        End Get
    End Property

    Public ReadOnly Property Row As Integer Implements ILocationModel.Row
        Get
            Return location.Row
        End Get
    End Property

    Public ReadOnly Property Name As String Implements ILocationModel.Name
        Get
            Return location.Name
        End Get
    End Property
End Class
