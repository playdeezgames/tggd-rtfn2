Imports Metaphor.Provision
Imports TGGD.Provision

Friend Class Location
    Inherits MetaphorEntity
    Implements ILocation

    Private Sub New(world As IWorld, data As WorldData, locationId As Guid)
        MyBase.New(world, data, locationId)
    End Sub

    Public ReadOnly Property Features As IEnumerable(Of IFeature) Implements ILocation.Features
        Get
            Return GetYokage(Yokages.FEATURES).Select(Function(x) Feature.Create(World, _data, x))
        End Get
    End Property

    Public ReadOnly Property HasFeatures As Boolean Implements ILocation.HasFeatures
        Get
            Return GetYokage(Yokages.FEATURES).Any()
        End Get
    End Property

    Public ReadOnly Property Characters As IEnumerable(Of ICharacter) Implements ILocation.Characters
        Get
            Return GetYokage(Yokages.CHARACTERS).Select(Function(x) Character.Create(World, _data, x))
        End Get
    End Property

    Public Property Map As IMap Implements ILocation.Map
        Get
            Return World.GetMap(GetYoke(Yokes.MAP))
        End Get
        Set(value As IMap)
            Map?.RemoveFromYokage(Yokages.LOCATIONS, EntityId)
            If value IsNot Nothing Then
                SetYoke(Yokes.MAP, value.EntityId)
            Else
                ClearYoke(Yokes.MAP)
            End If
            Map?.AddToYokage(Yokages.LOCATIONS, EntityId)
        End Set
    End Property

    Public ReadOnly Property Column As Integer Implements ILocation.Column
        Get
            Return GetCounter(Counters.COLUMN)
        End Get
    End Property

    Public ReadOnly Property Row As Integer Implements ILocation.Row
        Get
            Return GetCounter(Counters.ROW)
        End Get
    End Property

    Protected Overrides ReadOnly Property Data As EntityData
        Get
            Return _data.Entities(EntityId)
        End Get
    End Property

    Public Overrides Sub Remove()
        Throw New NotImplementedException()
    End Sub

    Friend Shared Function Create(world As IWorld, data As WorldData, locationId As Guid?) As ILocation
        Return If(locationId.HasValue, New Location(world, data, locationId.Value), Nothing)
    End Function

    Public Function CreateCharacter(entitySubtype As String, name As String, Optional initialize As CharacterInitializer = Nothing) As ICharacter Implements ILocation.CreateCharacter
        Dim characterId = Guid.NewGuid
        _data.Entities(characterId) = New EntityData With
            {
                .EntityType = EntityTypes.CHARACTER_ENTITY,
                .Yokes = New Dictionary(Of String, Guid) From
                {
                    {Yokes.LOCATION, EntityId}
                },
                .Metadatas = New Dictionary(Of String, String) From
                {
                    {Metadatas.ENTITY_SUBTYPE, entitySubtype},
                    {Metadatas.NAME, name},
                    {Metadatas.DIALOG_MODE, String.Empty}
                }
            }
        AddToYokage(Yokages.CHARACTERS, characterId)
        Dim result = Character.Create(World, _data, characterId)
        initialize?.Invoke(result)
        Return result
    End Function

    Public Function CreateFeature(entitySubtype As String, name As String, Optional initializer As FeatureInitializer = Nothing) As IFeature Implements ILocation.CreateFeature
        Dim featureId = Guid.NewGuid
        _data.Entities(featureId) = New EntityData With
            {
                .EntityType = EntityTypes.FEATURE_ENTITY,
                .Yokes = New Dictionary(Of String, Guid) From
                {
                    {Yokes.LOCATION, EntityId}
                },
                .Metadatas = New Dictionary(Of String, String) From
                {
                    {Metadatas.ENTITY_SUBTYPE, entitySubtype},
                    {Metadatas.NAME, name}
                }
            }
        AddToYokage(Yokages.FEATURES, featureId)
        Dim result As IFeature = Feature.Create(World, _data, featureId)
        initializer?.Invoke(result)
        Return result
    End Function

    Public Function GetOtherCharacters(character As ICharacter) As IEnumerable(Of ICharacter) Implements ILocation.GetOtherCharacters
        Return GetYokage(Yokages.CHARACTERS).
            Where(Function(id) id <> character.EntityId).
            Select(Function(x) Persistence.Character.Create(World, _data, x))
    End Function

    Public Function HasOtherCharacters(character As ICharacter) As Boolean Implements ILocation.HasOtherCharacters
        Return GetYokage(Yokages.CHARACTERS).Any(Function(x) x <> character.EntityId)
    End Function
End Class
