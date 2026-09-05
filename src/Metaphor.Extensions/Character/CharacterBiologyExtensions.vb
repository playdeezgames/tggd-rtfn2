Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Friend Module CharacterBiologyExtensions
    <Extension>
    Friend Sub DoBiology(character As ICharacter, amount As Integer)
        If Not character.IsAvatar OrElse character.IsDead() OrElse amount <= 0 Then
            Return
        End If
        Dim stomach = Math.Min(amount, character.GetStomach())
        If stomach > 0 Then
            amount -= stomach
            character.DoChangeCounter(Counters.STOMACH, -stomach)
        End If
        Dim satiety = Math.Min(amount, character.GetSatiety())
        If satiety > 0 Then
            amount -= satiety
            character.DoChangeCounter(Counters.SATIETY, -satiety)
        End If
        If amount > 0 Then
            character.DoChangeCounter(Counters.HEALTH, -amount)
        End If
    End Sub
End Module
