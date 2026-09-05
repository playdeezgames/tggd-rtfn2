Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Friend Module CharacterInitializationExtensions
#Region "N00b"
    <Extension>
    Friend Sub InitializeN00b(character As ICharacter)
        character.World.Avatar = character
        character.CreateMoveVerb("N", "north", 0, -1)
        character.CreateMoveVerb("E", "east", 1, 0)
        character.CreateMoveVerb("S", "south", 0, 1)
        character.CreateMoveVerb("W", "west", -1, 0)
        character.CreateLookVerb()
        character.CreateStatusVerb()
        character.InitializeCounter(Counters.SATIETY, 100, 0, 100)
        character.InitializeCounter(Counters.HEALTH, 100, 0, 100)
        character.InitializeCounter(Counters.STOMACH, 0, 0, 50)
    End Sub
#End Region
End Module
