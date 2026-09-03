Imports Metaphor.Persistence

Friend Module MapInitializationExtensions
#Region "Blue Room"

    Private Sub InitializeBlueWall(location As ILocation)
        location.SetTag(Tags.BLOCKED)
    End Sub

    Friend Sub InitializeBlueRoom(map As IMap)
        InitializeRoom(map)
        map.GetLocation(map.Size.Columns \ 2, 0).Remove()
        map.CreateLocation(LocationSubtypes.FLOOR, "floor", (map.Size.Columns \ 2, 0))
        Dim size = map.Size
        map.GetLocation(size.Columns \ 2, size.Rows \ 2).CreateCharacter(CharacterSubtypes.N00B, map.World.GetMetadata(Metadatas.CHOSEN_NAME), AddressOf CharacterInitializationExtensions.InitializeN00b)
    End Sub

    Private Sub InitializeRoom(map As IMap)
        Dim size = map.Size
        For Each column In Enumerable.Range(0, size.Columns)
            For Each row In Enumerable.Range(0, size.Rows)
                If column = 0 OrElse row = 0 OrElse column = size.Columns - 1 OrElse row = size.Rows - 1 Then
                    map.CreateLocation(LocationSubtypes.WALL, "wall", (column, row), AddressOf InitializeBlueWall)
                Else
                    map.CreateLocation(LocationSubtypes.FLOOR, "floor", (column, row))
                End If
            Next
        Next
    End Sub

    Friend Function InitializeOtherBlueRoom(blueRoom As IMap) As MapInitializer
        Return Sub(map)
                   InitializeRoom(map)
                   blueRoom.GetLocation(blueRoom.Size.Columns \ 2, 0).CreateFeature(FeatureSubtypes.DOOR, "door")
                   map.GetLocation(map.Size.Columns \ 2, map.Size.Rows - 1).CreateFeature(FeatureSubtypes.DOOR, "door")
               End Sub
    End Function
#End Region
End Module
