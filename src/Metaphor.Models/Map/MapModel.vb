Imports Metaphor.Persistence

Friend Class MapModel
    Implements IMapModel

    Private ReadOnly map As IMap

    Private Sub New(map As IMap)
        Me.map = map
    End Sub

    Public ReadOnly Property Columns As Integer Implements IMapModel.Columns
        Get
            Return map.Size.Columns
        End Get
    End Property

    Public ReadOnly Property Rows As Integer Implements IMapModel.Rows
        Get
            Return map.Size.Rows
        End Get
    End Property

    Public ReadOnly Property Locations As IEnumerable(Of ILocationModel) Implements IMapModel.Locations
        Get
            Return map.Locations.Select(AddressOf LocationModel.Create)
        End Get
    End Property

    Friend Shared Function Create(map As IMap) As IMapModel
        Return New MapModel(map)
    End Function
End Class
