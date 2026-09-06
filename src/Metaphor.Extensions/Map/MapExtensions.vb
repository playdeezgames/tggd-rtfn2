Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence
Imports TGGD.Extensions

Friend Module MapExtensions
    <Extension>
    Friend Sub SetDoorCount(map As IMap, doorCount As Integer)
        map.SetCounter(Counters.DOOR_COUNT, doorCount)
    End Sub
    <Extension>
    Friend Function GetDoorCount(map As IMap) As Integer
        Return map.GetCounter(Counters.DOOR_COUNT)
    End Function
    <Extension>
    Friend Function GetMazeColumn(map As IMap) As Integer
        Return map.GetCounter(Counters.MAZE_COLUMN)
    End Function
    <Extension>
    Friend Function GetMazeRow(map As IMap) As Integer
        Return map.GetCounter(Counters.MAZE_ROW)
    End Function
    <Extension>
    Friend Function GetMazeDoorLocation(map As IMap, direction As String) As (Column As Integer, Row As Integer)
        Select Case direction
            Case Directions.NORTH
                Return (map.Size.Columns \ 2, 0)
            Case Directions.EAST
                Return (map.Size.Columns - 1, map.Size.Rows \ 2)
            Case Directions.SOUTH
                Return (map.Size.Columns \ 2, map.Size.Rows - 1)
            Case Directions.WEST
                Return (0, map.Size.Rows \ 2)
            Case Else
                Throw New NotImplementedException()
        End Select
    End Function
    <Extension>
    Friend Function GetMazeDoorDestination(map As IMap, direction As String) As (Column As Integer, Row As Integer)
        Select Case direction
            Case Directions.NORTH
                Return (map.Size.Columns \ 2, map.Size.Rows - 1)
            Case Directions.EAST
                Return (0, map.Size.Rows \ 2)
            Case Directions.SOUTH
                Return (map.Size.Columns \ 2, 0)
            Case Directions.WEST
                Return (map.Size.Columns - 1, map.Size.Rows \ 2)
            Case Else
                Throw New NotImplementedException()
        End Select
    End Function
    <Extension>
    Friend Sub PopulateDoors(map As IMap, mazeCell As MazeCell(Of String))
        For Each direction In mazeCell.Directions
            If mazeCell.GetDoor(direction).Open Then
                Dim directionDeets = WorldExtensions.directionTable(direction)
                Dim nextMap As IMap = map.World.GetMazeRoom(map.GetCounter(Counters.MAZE_COLUMN) + CInt(directionDeets.DeltaX), map.GetCounter(Counters.MAZE_ROW) + CInt(directionDeets.DeltaY))
                Dim destinationPosition = nextMap.GetMazeDoorDestination(direction)
                Dim doorPosition = map.GetMazeDoorLocation(direction)
                Dim door = map.GetLocation(doorPosition.Column, doorPosition.Row).CreateDoor(nextMap.GetLocation(destinationPosition.Column, destinationPosition.Row))
                If nextMap.GetDoorCount() = 1 Then
                    door.SetTag(Tags.LOCKED)
                End If
            End If
        Next
    End Sub
End Module
