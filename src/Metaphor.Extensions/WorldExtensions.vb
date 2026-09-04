Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence
Imports TGGD.Extensions

Public Module WorldExtensions
#Region "Maze"
    Private ReadOnly directionTable As New Dictionary(Of String, MazeDirection(Of String)) From
        {
            {Directions.NORTH, New MazeDirection(Of String)(Directions.SOUTH, 0, -1)},
            {Directions.EAST, New MazeDirection(Of String)(Directions.WEST, 1, 0)},
            {Directions.SOUTH, New MazeDirection(Of String)(Directions.NORTH, 0, 1)},
            {Directions.WEST, New MazeDirection(Of String)(Directions.EAST, -1, 0)}
        }
    <Extension>
    Private Sub CreateMaze(world As IWorld)
        Dim mazeColumns = world.GetCounter(Counters.MAZE_COLUMNS)
        Dim mazeRows = world.GetCounter(Counters.MAZE_ROWS)
        Dim maze As New Maze(Of String)(mazeColumns, mazeRows, directionTable)
        maze.Generate()
        For Each mazeColumn In Enumerable.Range(0, mazeColumns)
            For Each mazeRow In Enumerable.Range(0, mazeRows)
                world.CreateMazeRoom(maze.GetCell(mazeColumn, mazeRow), mazeColumn, mazeRow)
            Next
        Next

        Dim map = world.GetMap(world.GetYokage(Yokages.MAZE_ROOMS).First())
        map.GetLocation(map.Size.Columns \ 2, map.Size.Rows \ 2).CreateCharacter(CharacterSubtypes.N00B, map.World.GetMetadata(Metadatas.CHOSEN_NAME), AddressOf CharacterInitializationExtensions.InitializeN00b)

    End Sub
    <Extension>
    Private Function CreateMazeRoom(world As IWorld, mazeCell As MazeCell(Of String), mazeColumn As Integer, mazeRow As Integer) As IMap
        Return world.CreateMap(
            MapSubtypes.MAZE_ROOM,
            "maze room",
            (Grimoire.ROOM_COLUMNS, Grimoire.ROOM_ROWS),
            MapInitializationExtensions.InitializeMazeRoom(mazeCell, mazeColumn, mazeRow))
    End Function
#End Region
    <Extension>
    Public Sub Initialize(
                         world As IWorld,
                         chosenName As String,
                         mazeSize As (Columns As Integer, Rows As Integer))
        world.Clear()
        world.SetMetadata(Metadatas.CHOSEN_NAME, chosenName)
        world.SetCounter(Counters.MAZE_COLUMNS, mazeSize.Columns)
        world.SetCounter(Counters.MAZE_ROWS, mazeSize.Rows)
        world.CreateMaze()

        world.AddMessage("Welcome to Feretory of SPLORR!!")
        world.Avatar.Look()
    End Sub
End Module
