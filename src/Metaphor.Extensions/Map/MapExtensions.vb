Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Friend Module MapExtensions
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
                Return (map.Size.Columns \ 2, map.Size.Rows - 2)
            Case Directions.EAST
                Return (1, map.Size.Rows \ 2)
            Case Directions.SOUTH
                Return (map.Size.Columns \ 2, 1)
            Case Directions.WEST
                Return (map.Size.Columns - 2, map.Size.Rows \ 2)
            Case Else
                Throw New NotImplementedException()
        End Select
    End Function
End Module
