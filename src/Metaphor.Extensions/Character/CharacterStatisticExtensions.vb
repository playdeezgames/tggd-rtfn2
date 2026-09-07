Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module CharacterStatisticExtensions
    <Extension>
    Public Function IsAvatar(character As ICharacter) As Boolean
        Return character.EntityId = character.World.Avatar.EntityId
    End Function
    <Extension>
    Public Function IsDead(character As ICharacter) As Boolean
        Return character.IsCounterMinimum(Counters.HEALTH)
    End Function
    <Extension>
    Public Function CanAct(character As ICharacter) As Boolean
        Return Not character.IsDead AndAlso Not character.IsInsane
    End Function
    <Extension>
    Public Function IsInsane(character As ICharacter) As Boolean
        Return character.IsCounterMinimum(Counters.SANITY)
    End Function
    <Extension>
    Friend Function GetStomach(character As ICharacter) As Integer
        Return character.GetCounter(Counters.STOMACH)
    End Function
    <Extension>
    Friend Function GetBowel(character As ICharacter) As Integer
        Return character.GetCounter(Counters.BOWEL)
    End Function
    <Extension>
    Friend Function GetSatiety(character As ICharacter) As Integer
        Return character.GetCounter(Counters.SATIETY)
    End Function
    <Extension>
    Friend Function GetHealth(character As ICharacter) As Integer
        Return character.GetCounter(Counters.HEALTH)
    End Function

#Region "Utility"
    Private ReadOnly counterNames As New Dictionary(Of String, String) From
        {
            {Counters.STOMACH, "stomach"},
            {Counters.HEALTH, "health"},
            {Counters.SATIETY, "satiety"},
            {Counters.BOWEL, "bowel"},
            {Counters.INK, "ink"},
            {Counters.SANITY, "sanity"},
            {Counters.COMPLETENESS, "completeness"}
        }
    <Extension>
    Friend Function DoChangeCounter(entity As IMetaphorEntity, counterId As String, delta As Integer, Optional silent As Boolean = False) As Integer
        If delta <> 0 Then
            Dim counterName = counterNames(counterId)
            entity.AddMessage($"{entity.Name} {If(delta > 0, "gains", "loses")} {Math.Abs(delta)} {counterName}.", silent:=silent)
            entity.ChangeCounter(counterId, delta)
            If entity.GetCounterMaximum(counterId) = Integer.MaxValue Then
                entity.AddMessage($"{entity.Name} now has {entity.GetCounter(counterId)} {counterName}.", silent:=silent)
            Else
                entity.AddMessage($"{entity.Name} now has {entity.GetCounterStatistic(counterId)} {counterName}.", silent:=silent)
            End If
        End If
        Return entity.GetCounter(counterId)
    End Function
#End Region
End Module
