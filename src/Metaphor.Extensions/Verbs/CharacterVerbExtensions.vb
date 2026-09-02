Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module CharacterVerbExtensions
    Private Delegate Function CanPerformHandler(verb As IVerb, character As ICharacter, actor As ICharacter) As Boolean
    Private Delegate Sub PerformHandler(verb As IVerb, character As ICharacter, actor As ICharacter)

    Private ReadOnly canPerformTable As New Dictionary(Of String, CanPerformHandler) From
        {
        }

    <Extension>
    Public Function CanPerform(verb As IVerb, character As ICharacter, actor As ICharacter) As Boolean
        Dim handler As CanPerformHandler = Nothing
        If canPerformTable.TryGetValue(verb.EntitySubtype, handler) Then
            Return handler.Invoke(verb, character, actor)
        End If
        Return True
    End Function

    Private ReadOnly performTable As New Dictionary(Of String, PerformHandler) From
        {
            {VerbSubtypes.MOVE, AddressOf HandleMove},
            {VerbSubtypes.LOOK, AddressOf HandleLook},
            {VerbSubtypes.STATUS, AddressOf HandleStatus}
        }

    Private Sub HandleStatus(verb As IVerb, character As ICharacter, actor As ICharacter)
        actor.ShowStatus()
    End Sub

    Private Sub HandleLook(verb As IVerb, character As ICharacter, actor As ICharacter)
        actor.Look()
    End Sub

    Private Sub HandleMove(verb As IVerb, character As ICharacter, actor As ICharacter)
        Dim deltaX = verb.GetCounter(Counters.DELTA_X)
        Dim deltaY = verb.GetCounter(Counters.DELTA_Y)
        Dim nextColumn = character.Location.Column + deltaX
        Dim nextRow = character.Location.Row + deltaY
        Dim nextLocation = character.Map.GetLocation(nextColumn, nextRow)
        Dim directionName = verb.GetMetadata(Metadatas.DIRECTION_NAME)
        If nextLocation Is Nothing OrElse nextLocation.HasTag(Tags.BLOCKED) Then
            actor.AddMessage($"{actor.Name} cannot move {directionName}.")
        Else
            actor.AddMessage($"{actor.Name} moves {directionName}.")
            actor.Location = nextLocation
            actor.Look()
        End If
    End Sub

    <Extension>
    Sub Perform(verb As IVerb, character As ICharacter, actor As ICharacter)
        Dim handler As PerformHandler = Nothing
        If performTable.TryGetValue(verb.EntitySubtype, handler) Then
            handler.Invoke(verb, character, actor)
            Return
        End If
    End Sub
End Module
