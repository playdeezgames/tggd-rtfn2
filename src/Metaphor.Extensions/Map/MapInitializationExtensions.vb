Imports Metaphor.Persistence

Friend Module MapInitializationExtensions
#Region "Blue Room"
    Private ReadOnly blueRoom As String() =
        {
            "####################",
            "#..................#",
            "#..c............r..#",
            "#..................#",
            "#..................#",
            "#..................#",
            "#..................#",
            "#.........@........#",
            "#..................#",
            "#..................#",
            "#..................#",
            "#..................#",
            "#..................#",
            "#..................#",
            "####################"
        }
    Private ReadOnly blueRoomDeets As New Dictionary(Of
            Char,
                (Subtype As String,
                Name As String,
                LocationInitializer As LocationInitializer)) From
        {
            {"#"c, (LocationSubtypes.WALL, "Wall", AddressOf InitializeBlueWall)},
            {"."c, (LocationSubtypes.FLOOR, "Floor", Nothing)},
            {"@"c, (LocationSubtypes.FLOOR, "Floor", AddressOf InitializeAvatar)},
            {"c"c, (LocationSubtypes.FLOOR, "Floor", AddressOf InitializeChest)},
            {"r"c, (LocationSubtypes.FLOOR, "Floor", AddressOf InitializeRat)}
        }

    Private Sub InitializeRat(location As ILocation)
        location.CreateCharacter(CharacterSubtypes.RAT, "Rat", AddressOf CharacterInitializationExtensions.InitializeRat)
    End Sub

    Private Sub InitializeChest(location As ILocation)
        location.CreateFeature(FeatureSubtypes.CHEST, "Chest", AddressOf FeatureInitializationExtensions.InitializeBlueRoomChest)
    End Sub

    Private Sub InitializeAvatar(location As ILocation)
        location.CreateCharacter(CharacterSubtypes.N00B, location.World.GetMetadata(Metadatas.CHOSEN_NAME), AddressOf CharacterInitializationExtensions.InitializeN00b)
    End Sub

    Private Sub InitializeBlueWall(location As ILocation)
        location.SetTag(Tags.BLOCKED)
    End Sub

    Friend Sub InitializeBlueRoom(map As IMap)
        Dim row = 0
        For Each line In blueRoom
            Dim column = 0
            For Each character In line
                Dim deets = blueRoomDeets(character)
                Dim location = map.CreateLocation(deets.Subtype, deets.Name, (column, row), deets.LocationInitializer)
                column += 1
            Next
            row += 1
        Next
    End Sub
#End Region
End Module
