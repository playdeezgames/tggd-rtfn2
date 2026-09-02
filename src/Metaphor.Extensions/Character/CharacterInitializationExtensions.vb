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
        character.InitializeCounter(Counters.HEALTH, 3, 0, 3)
        character.SetCounter(Counters.ATTACK, 3)
        character.SetCounter(Counters.ATTACK_CAP, 1)
        character.SetCounter(Counters.DEFEND, 4)
        character.SetCounter(Counters.DEFEND_CAP, 2)
    End Sub

    Friend Sub InitializeRat(character As ICharacter)
        character.SetTag(Tags.ENEMY)
        character.InitializeCounter(Counters.HEALTH, 1, 0, 1)
        character.SetCounter(Counters.ATTACK, 2)
        character.SetCounter(Counters.ATTACK_CAP, 1)
        character.SetCounter(Counters.DEFEND, 1)
        character.SetCounter(Counters.DEFEND_CAP, 1)
    End Sub
#End Region
End Module
