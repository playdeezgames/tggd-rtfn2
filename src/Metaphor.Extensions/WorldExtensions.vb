Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module WorldExtensions
#Region "Blue Room"
    <Extension>
    Private Function CreateBlueRoom(world As IWorld) As IMap
        Return world.CreateMap(
            MapSubtypes.BLUE_ROOM,
            "The Blue Room",
            (Grimoire.ROOM_COLUMNS, Grimoire.ROOM_ROWS),
            AddressOf MapInitializationExtensions.InitializeBlueRoom)
    End Function
#End Region
    <Extension>
    Public Sub Initialize(world As IWorld, chosenName As String)
        world.Clear()
        world.SetMetadata(Metadatas.CHOSEN_NAME, chosenName)
        world.CreateBlueRoom()
        world.AddMessage("Welcome to Beneath the Blue Room")
        world.Avatar.Look()
    End Sub
End Module
