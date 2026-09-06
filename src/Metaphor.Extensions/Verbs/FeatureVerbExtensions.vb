Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module FeatureVerbExtensions
    Private Delegate Function CanPerformHandler(verb As IVerb, feature As IFeature, actor As ICharacter) As Boolean
    Private Delegate Sub PerformHandler(verb As IVerb, feature As IFeature, actor As ICharacter)
#Region "Can Perform"
    Private ReadOnly canPerformTable As New Dictionary(Of String, CanPerformHandler) From
        {
            {VerbSubtypes.ENTER, AddressOf CanEnter},
            {VerbSubtypes.UNLOCK, AddressOf CanUnlock},
            {VerbSubtypes.FILL_OUT, AddressOf CanFillOut}
        }

    Private Function CanFillOut(verb As IVerb, feature As IFeature, actor As ICharacter) As Boolean
        Return Not feature.IsCounterMaximum(Counters.COMPLETENESS) AndAlso
            actor.Inventory.GetItemsOfSubtype(ItemSubtypes.PEN).Any(Function(x) Not x.IsCounterMinimum(Counters.INK))
    End Function

    Private Function CanUnlock(verb As IVerb, feature As IFeature, actor As ICharacter) As Boolean
        Return feature.HasTag(Tags.LOCKED) AndAlso actor.Inventory.HasItemOfSubtype(ItemSubtypes.KEY)
    End Function

    Private Function CanEnter(verb As IVerb, feature As IFeature, actor As ICharacter) As Boolean
        Return Not feature.HasTag(Tags.LOCKED)
    End Function

    <Extension>
    Public Function CanPerform(verb As IVerb, feature As IFeature, actor As ICharacter) As Boolean
        Dim handler As CanPerformHandler = Nothing
        If canPerformTable.TryGetValue(verb.EntitySubtype, handler) Then
            Return handler.Invoke(verb, feature, actor)
        End If
        Return True
    End Function
#End Region
#Region "Perform"
    Private ReadOnly performTable As New Dictionary(Of String, PerformHandler) From
        {
            {VerbSubtypes.ENTER, AddressOf HandleEnter},
            {VerbSubtypes.UNLOCK, AddressOf HandleUnlock},
            {VerbSubtypes.FILL_OUT, AddressOf HandleFillOut}
        }

    Private Sub HandleFillOut(verb As IVerb, feature As IFeature, actor As ICharacter)
        Dim pen = actor.Inventory.GetItemsOfSubtype(ItemSubtypes.PEN).First(Function(x) Not x.IsCounterMinimum(Counters.INK))
        pen.DoChangeCounter(Counters.INK, -1)
        feature.DoChangeCounter(Counters.COMPLETENESS, 1)
        actor.DoChangeCounter(Counters.SANITY, -1)
    End Sub

    Private Sub HandleUnlock(verb As IVerb, feature As IFeature, actor As ICharacter)
        actor.AddMessage($"{actor.Name} unlocks {feature.Name}.")
        feature.ClearTag(Tags.LOCKED)
        Dim key = actor.Inventory.GetItemsOfSubtype(ItemSubtypes.KEY).First
        key.Remove()
    End Sub

    Private Sub HandleEnter(verb As IVerb, feature As IFeature, actor As ICharacter)
        actor.AddMessage($"{actor.Name} enters {feature.Name}.")
        actor.Location = feature.GetDestination()
        actor.Look()
    End Sub

    <Extension>
    Sub Perform(verb As IVerb, feature As IFeature, actor As ICharacter)
        Dim handler As PerformHandler = Nothing
        If performTable.TryGetValue(verb.EntitySubtype, handler) Then
            handler.Invoke(verb, feature, actor)
            Return
        End If
    End Sub
#End Region
End Module
