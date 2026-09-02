Imports Metaphor.Processing
Imports TGGD.Presentation

Friend Class RunActivity
    Friend Shared Function Launch(
                                 context As IDisplayContext,
                                 model As IWorldModel,
                                 previous As DialogSource) As DialogSource
        Return Function()
                   model.Avatar.Combat.Run()
                   Return InPlay.Launch(context, model, previous).Invoke()
               End Function
    End Function
End Class
