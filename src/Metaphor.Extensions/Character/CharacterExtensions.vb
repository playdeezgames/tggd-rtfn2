Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module CharacterExtensions
#Region "Show Status"
    <Extension>
    Public Sub ShowStatus(character As ICharacter)
        character.AddMessage($"Status:")
        character.AddMessage($"Stomach: {character.GetCounterStatistic(Counters.STOMACH)}")
        character.AddMessage($"Bowel: {character.GetCounterStatistic(Counters.BOWEL)}")
        character.AddMessage($"Satiety: {character.GetCounterStatistic(Counters.SATIETY)}")
        character.AddMessage($"Health: {character.GetCounterStatistic(Counters.HEALTH)}")
    End Sub
#End Region
#Region "Look"
    <Extension>
    Public Sub Look(character As ICharacter)
        If character.IsDead Then
            character.AddMessage($"{character.Name} is dead.")
            Return
        End If
        Dim location = character.Location
        character.AddMessage($"{character.Name} is on {location.Name}.")
        location.Describe()
        DescribeFeatures(location)
    End Sub

    Private Sub DescribeFeatures(location As ILocation)
        If location.HasFeatures Then
            location.AddMessage($"Features:")
            For Each feature In location.Features
                location.AddMessage($"- {feature.Name}")
            Next
        End If
    End Sub
#End Region
#Region "Verbs"
    <Extension>
    Friend Sub CreateMoveVerb(character As ICharacter, name As String, directionName As String, deltaX As Integer, deltaY As Integer)
        character.CreateVerb(
            VerbSubtypes.MOVE,
            name,
            Sub(verb)
                verb.SetCounter(Counters.DELTA_X, deltaX)
                verb.SetCounter(Counters.DELTA_Y, deltaY)
                verb.SetMetadata(Metadatas.DIRECTION_NAME, directionName)
            End Sub)
    End Sub
    <Extension>
    Friend Sub CreateStatusVerb(character As ICharacter)
        character.CreateVerb(VerbSubtypes.STATUS, "Status")
    End Sub
    <Extension>
    Friend Sub CreateLookVerb(character As ICharacter)
        character.CreateVerb(VerbSubtypes.LOOK, "Look")
    End Sub
    <Extension>
    Friend Sub CreatePoopVerb(character As ICharacter)
        character.CreateVerb(VerbSubtypes.POOP, "Poop!")
    End Sub
#End Region
End Module
