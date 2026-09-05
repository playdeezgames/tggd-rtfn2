Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Friend Module CharacterBiologyExtensions
    <Extension>
    Friend Sub DoBiology(character As ICharacter, amount As Integer)
        If Not character.IsAvatar OrElse character.IsDead() OrElse amount <= 0 Then
            Return
        End If
        Dim stomach = Math.Min(amount, character.GetStomach())
        Dim damage = 0
        If stomach > 0 Then
            amount -= stomach
            character.DoChangeCounter(Counters.STOMACH, -stomach)
            Dim bowel = Math.Min(stomach, character.GetCounterCapacity(Counters.BOWEL))
            damage += (stomach - bowel)
            If damage > 0 Then
                character.AddMessage($"{character.Name} takes damage from having a full bowel!")
            End If
            character.DoChangeCounter(Counters.BOWEL, bowel)
        End If
        Dim satiety = Math.Min(amount, character.GetSatiety())
        If satiety > 0 Then
            amount -= satiety
            character.DoChangeCounter(Counters.SATIETY, -satiety)
        Else
            If character.IsCounterMaximum(Counters.SATIETY) Then
                If Not character.IsCounterMaximum(Counters.HEALTH) AndAlso damage <= 0 Then
                    character.DoChangeCounter(Counters.HEALTH, 1)
                End If
            Else
                character.DoChangeCounter(Counters.SATIETY, 1)
            End If
        End If
        damage += amount
        If damage > 0 Then
            character.DoChangeCounter(Counters.HEALTH, -damage)
        End If
    End Sub
End Module
