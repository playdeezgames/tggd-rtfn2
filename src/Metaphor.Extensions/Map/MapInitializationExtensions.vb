Imports Metaphor.Persistence
Imports TGGD.Extensions

Friend Module MapInitializationExtensions
    Private Sub InitializeBlueWall(location As ILocation)
        location.SetTag(Tags.BLOCKED)
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
    Friend Function InitializeMazeRoom(mazeCell As MazeCell(Of String), mazeColumn As Integer, mazeRow As Integer) As MapInitializer
        Return Sub(map)
                   InitializeRoom(map)
                   map.SetCounter(Counters.MAZE_COLUMN, mazeColumn)
                   map.SetCounter(Counters.MAZE_ROW, mazeRow)
                   map.World.AddToYokage(Yokages.MAZE_ROOMS, map.EntityId)
                   For Each direction In mazeCell.Directions
                       If mazeCell.GetDoor(direction).Open Then
                           Dim doorLocation = map.GetMazeDoorLocation(direction)
                           map.GetLocation(doorLocation.Column, doorLocation.Row).Remove()
                           map.CreateLocation(LocationSubtypes.FLOOR, "floor", (doorLocation.Column, doorLocation.Row))
                       End If
                   Next
               End Sub
    End Function
End Module
