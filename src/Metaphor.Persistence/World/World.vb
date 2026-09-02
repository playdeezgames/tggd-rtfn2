Imports System.Text.Json
Imports Metaphor.Provision
Imports TGGD.Persistence
Imports TGGD.Provision

Public Class World
    Inherits Entity
    Implements IWorld

    Private Sub New(data As WorldData, persister As IPersister)
        Me.worldData = data
        Me.Data = data
        Me.persister = persister
    End Sub

    Public Overrides Sub Clear()
        MyBase.Clear()
        ClearMessages()
        worldData.Entities.Clear()
        worldData.AdFinishes = Nothing
    End Sub

    Private ReadOnly worldData As WorldData
    Protected Overrides ReadOnly Property Data As EntityData

    Public ReadOnly Property Messages As IEnumerable(Of IMessage) Implements IWorld.Messages
        Get
            Return Enumerable.
                Range(0, worldData.Messages.Count).
                Select(Function(x) TGGD.Persistence.Message.Create(Function() worldData.Messages(x)))
        End Get
    End Property

    Public Property Avatar As ICharacter Implements IWorld.Avatar
        Get
            Return Character.Create(Me, worldData, GetYoke(Yokes.AVATAR))
        End Get
        Set(value As ICharacter)
            If value Is Nothing Then
                ClearYoke(Yokes.AVATAR)
            Else
                SetYoke(Yokes.AVATAR, value.EntityId)
            End If
        End Set
    End Property

    Public Property AdFinish As DateTimeOffset? Implements IWorld.AdFinish
        Get
            Return worldData.AdFinishes
        End Get
        Set(value As DateTimeOffset?)
            worldData.AdFinishes = value
        End Set
    End Property

    Private ReadOnly persister As IPersister

    Public Async Function Save(filename As String) As Task Implements IWorld.Save
        Await persister.SaveAsync(filename, JsonSerializer.Serialize(Data))
    End Function

    Public Shared Async Function Load(filename As String, persister As IPersister) As Task(Of IWorld)
        Return New World(JsonSerializer.Deserialize(Of WorldData)(Await persister.LoadAsync(filename)), persister)
    End Function

    Public Shared Function Create(data As WorldData, persister As IPersister) As IWorld
        Return New World(data, persister)
    End Function

    Public Sub ClearMessages() Implements IWorld.ClearMessages
        worldData.Messages.Clear()
    End Sub

    Public Sub AddMessage(
                         text As String,
                         Optional hints As IDictionary(Of String, String) = Nothing) Implements IWorld.AddMessage
        Dim messageData As New MessageData With
            {
                .Text = text
            }
        If hints IsNot Nothing Then
            messageData.Hints = hints.ToDictionary(Function(x) x.Key, Function(x) x.Value)
        End If
        worldData.Messages.Add(messageData)
    End Sub

    Public Function CreateLocation(entitySubtype As String, name As String, Optional initializer As LocationInitializer = Nothing) As ILocation Implements IWorld.CreateLocation
        Dim locationId = Guid.NewGuid
        worldData.Entities(locationId) = New EntityData With
            {
                .EntityType = EntityTypes.LOCATION_ENTITY,
                .Metadatas = New Dictionary(Of String, String) From
                {
                    {Metadatas.ENTITY_SUBTYPE, entitySubtype},
                    {Metadatas.NAME, name}
                }
            }
        Dim result = Location.Create(Me, worldData, locationId)
        initializer?.Invoke(result)
        Return result
    End Function

    Public Function GetLocation(locationId As Guid?) As ILocation Implements IWorld.GetLocation
        Return Location.Create(Me, worldData, locationId)
    End Function

    Public Function GetCharacter(characterId As Guid?) As ICharacter Implements IWorld.GetCharacter
        Return Character.Create(Me, worldData, characterId)
    End Function

    Public Function GetFeature(featureId As Guid?) As IFeature Implements IWorld.GetFeature
        Return Feature.Create(Me, worldData, featureId)
    End Function

    Public Function CreateMap(entitySubtype As String, name As String, size As (Columns As Integer, Rows As Integer), Optional initializer As MapInitializer = Nothing) As IMap Implements IWorld.CreateMap
        Dim mapId = Guid.NewGuid
        worldData.Entities(mapId) = New EntityData With
            {
                .EntityType = EntityTypes.MAP_ENTITY,
                .Metadatas = New Dictionary(Of String, String) From
                {
                    {Metadatas.ENTITY_SUBTYPE, entitySubtype},
                    {Metadatas.NAME, name}
                },
                .Counters = New Dictionary(Of String, Integer) From
                {
                    {Counters.COLUMNS, size.Columns},
                    {Counters.ROWS, size.Rows}
                }
            }
        Dim result = Map.Create(Me, worldData, mapId)
        initializer?.Invoke(result)
        Return result
    End Function

    Public Function GetMap(mapId As Guid?) As IMap Implements IWorld.GetMap
        Return Map.Create(Me, worldData, mapId)
    End Function

    Public Function GetItem(itemId As Guid?) As IItem Implements IWorld.GetItem
        Return Item.Create(Me, worldData, itemId)
    End Function
End Class
