Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence
Imports TGGD.Extensions

Public Module WorldExtensions
#Region "Maze"
    Friend ReadOnly directionTable As New Dictionary(Of String, MazeDirection(Of String)) From
        {
            {Directions.NORTH, New MazeDirection(Of String)(Directions.SOUTH, 0, -1)},
            {Directions.EAST, New MazeDirection(Of String)(Directions.WEST, 1, 0)},
            {Directions.SOUTH, New MazeDirection(Of String)(Directions.NORTH, 0, 1)},
            {Directions.WEST, New MazeDirection(Of String)(Directions.EAST, -1, 0)}
        }
    <Extension>
    Private Function GetMazeRooms(world As IWorld) As IEnumerable(Of IMap)
        Return world.GetYokage(Yokages.MAZE_ROOMS).Select(Function(x) world.GetMap(x))
    End Function
    <Extension>
    Friend Function GetMazeRoom(world As IWorld, mazeColumn As Integer, mazeRow As Integer) As IMap
        Return world.GetMazeRooms().SingleOrDefault(Function(x) x.GetMazeColumn() = mazeColumn AndAlso x.GetMazeRow() = mazeRow)
    End Function
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
        Dim mazeRooms = world.GetMazeRooms()
        For Each mazeRoom In mazeRooms
            Dim mazeColumn = mazeRoom.GetMazeColumn()
            Dim mazeRow = mazeRoom.GetMazeRow()
            Dim mazeCell = maze.GetCell(mazeColumn, mazeRow)
            mazeRoom.PopulateDoors(mazeCell)
        Next
        world.SetCounter(Counters.KEY_COUNT, mazeRooms.Count(Function(x) x.GetDoorCount() = 1))
        world.PopulateKeys(mazeRooms.Where(Function(x) x.GetDoorCount() > 1))
        Populate(mazeRooms)
        PopulateAvatar(mazeRooms)
    End Sub
#Region "Populate Keys"

    <Extension>
    Private Sub PopulateKeys(world As IWorld, mazeRooms As IEnumerable(Of IMap))
        Utility.Repeat(world.GetCounter(Counters.KEY_COUNT), PopulateKey(mazeRooms))
    End Sub

    Private Function PopulateKey(mazeRooms As IEnumerable(Of IMap)) As Action
        Return Sub()
                   Dim mazeRoom = RNG.FromEnumerable(mazeRooms)
                   Dim location = RNG.FromEnumerable(mazeRoom.Locations.Where(Function(x) x.EntitySubtype = LocationSubtypes.FLOOR AndAlso Not x.HasFeatures AndAlso Not x.HasCharacters))
                   location.CreateKey()
               End Sub
    End Function
#End Region

    Private Sub PopulateAvatar(mazeRooms As IEnumerable(Of IMap))
        Dim candidates = mazeRooms.Where(Function(x) x.GetDoorCount() = 4)
        If Not candidates.Any Then
            candidates = mazeRooms.Where(Function(x) x.GetDoorCount() = 3)
        End If
        If Not candidates.Any Then
            candidates = mazeRooms.Where(Function(x) x.GetDoorCount() = 2)
        End If
        Dim map = RNG.FromEnumerable(candidates)
        Dim location = RNG.FromEnumerable(map.Locations.Where(Function(x) x.EntitySubtype = LocationSubtypes.FLOOR AndAlso Not x.HasFeatures AndAlso Not x.HasCharacters))
        location.CreateCharacter(CharacterSubtypes.N00B, map.World.GetMetadata(Metadatas.CHOSEN_NAME), AddressOf CharacterInitializationExtensions.InitializeN00b)
    End Sub
#Region "Populate Items"

    Private Delegate Function Spawner(location As ILocation) As Boolean
    Private ReadOnly itemSpawnerDeets As New List(Of (Count As Integer, Spawner As Spawner)) From
        {
            (100, AddressOf SpawnFood),
            (25, AddressOf SpawnTaxForm),
            (5, AddressOf SpawnPen),
            (5, AddressOf SpawnInkWell)
        }

    Private Function SpawnInkWell(location As ILocation) As Boolean
        If location.EntitySubtype <> LocationSubtypes.FLOOR AndAlso Not location.HasFeatures AndAlso Not location.HasCharacters Then
            Return False
        End If
        location.CreateInkWell()
        Return True
    End Function

    Private Function SpawnPen(location As ILocation) As Boolean
        If location.EntitySubtype <> LocationSubtypes.FLOOR Then
            Return False
        End If
        location.Inventory.CreatePen()
        Return True
    End Function

    Private Function SpawnTaxForm(location As ILocation) As Boolean
        If location.EntitySubtype <> LocationSubtypes.FLOOR Then
            Return False
        End If
        location.CreateTaxForm()
        Return True
    End Function

    Private Function SpawnFood(location As ILocation) As Boolean
        If location.Map.GetDoorCount() < 2 OrElse
            location.EntitySubtype <> LocationSubtypes.FLOOR OrElse
            location.HasFeatures OrElse
            location.HasCharacters Then
            Return False
        End If
        location.Inventory.CreateItem(ItemSubtypes.FOOD, "food", AddressOf ItemInitializationExtensions.InitializeFood)
        Return True
    End Function

    Private Sub Populate(mazeRooms As IEnumerable(Of IMap))
        For Each itemSpawnerDeet In itemSpawnerDeets
            Utility.Repeat(itemSpawnerDeet.Count, PopulateItem(mazeRooms, itemSpawnerDeet.Spawner))
        Next
    End Sub

    Private Function PopulateItem(mazeRooms As IEnumerable(Of IMap), Spawner As Spawner) As Action
        Return Sub()
                   Dim location As ILocation
                   Do
                       location = RNG.FromEnumerable(RNG.FromEnumerable(mazeRooms).Locations)
                   Loop Until Spawner(location)
               End Sub
    End Function
#End Region

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
