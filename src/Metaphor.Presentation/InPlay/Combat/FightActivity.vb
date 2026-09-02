Imports Metaphor.Processing
Imports TGGD.Presentation

Friend Class FightActivity
    Friend Shared Function Launch(context As IDisplayContext, model As IWorldModel, previous As DialogSource) As DialogSource
        Return Function()
                   model.Avatar.Combat.Fight()
                   Return InPlay.Launch(context, model, previous).Invoke()
               End Function
    End Function
End Class
