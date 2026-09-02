Imports Metaphor.Provision
Imports TGGD.Provision

Friend Class Map
    Inherits MetaphorEntity
    Implements IMap

    Private Sub New(world As IWorld, data As WorldData, entityId As Guid)
        MyBase.New(world, data, entityId)
    End Sub

    Public ReadOnly Property Size As (Columns As Integer, Rows As Integer) Implements IMap.Size
        Get
            Return (GetCounter(Counters.COLUMNS), GetCounter(Counters.ROWS))
        End Get
    End Property

    Public ReadOnly Property Locations As IEnumerable(Of ILocation) Implements IMap.Locations
        Get
            Return GetYokage(Yokages.LOCATIONS).Select(Function(x) World.GetLocation(x))
        End Get
    End Property

    Protected Overrides ReadOnly Property Data As EntityData
        Get
            Return _data.Entities(EntityId)
        End Get
    End Property

    Public Overrides Sub Remove()
        'TODO: remove locations
    End Sub

    Friend Shared Function Create(world As World, data As WorldData, mapId As Guid?) As IMap
        If Not mapId.HasValue Then
            Return Nothing
        End If
        Return New Map(world, data, mapId.Value)
    End Function

    Public Function CreateLocation(locationType As String, name As String, position As (Column As Integer, Row As Integer), Optional initializer As LocationInitializer = Nothing) As ILocation Implements IMap.CreateLocation
        Dim locationId = Guid.NewGuid
        _data.Entities(locationId) = New EntityData With
            {
                .EntityType = EntityTypes.LOCATION_ENTITY,
                .Metadatas = New Dictionary(Of String, String) From
                {
                    {Metadatas.ENTITY_SUBTYPE, locationType},
                    {Metadatas.NAME, name}
                },
                .Counters = New Dictionary(Of String, Integer) From
                {
                    {Counters.COLUMN, position.Column},
                    {Counters.ROW, position.Row}
                }
            }
        Dim result = World.GetLocation(locationId)
        result.Map = Me
        initializer?.Invoke(result)
        Return result
    End Function

    Public Function GetLocation(column As Integer, row As Integer) As ILocation Implements IMap.GetLocation
        Return Locations.SingleOrDefault(Function(x) x.Column = column AndAlso x.Row = row)
    End Function
End Class
