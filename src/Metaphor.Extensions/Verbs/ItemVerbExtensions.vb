Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module ItemVerbExtensions
    Private Delegate Function CanPerformHandler(verb As IVerb, item As IItem, actor As ICharacter) As Boolean
    Private Delegate Sub PerformHandler(verb As IVerb, item As IItem, actor As ICharacter)
#Region "Can Perform"
    Private ReadOnly canPerformTable As New Dictionary(Of String, CanPerformHandler) From
        {
            {VerbSubtypes.EQUIP, AddressOf CanEquip},
            {VerbSubtypes.UNEQUIP, AddressOf CanUnequip}
        }

    Private Function CanUnequip(verb As IVerb, item As IItem, actor As ICharacter) As Boolean
        Return actor.CanUnequip(item)
    End Function

    Private Function CanEquip(verb As IVerb, item As IItem, actor As ICharacter) As Boolean
        Return actor.CanEquip(item)
    End Function

    <Extension>
    Public Function CanPerform(verb As IVerb, item As IItem, actor As ICharacter) As Boolean
        Dim handler As CanPerformHandler = Nothing
        If canPerformTable.TryGetValue(verb.EntitySubtype, handler) Then
            Return handler.Invoke(verb, item, actor)
        End If
        Return True
    End Function
#End Region
#Region "Perform"
    Private ReadOnly performTable As New Dictionary(Of String, PerformHandler) From
        {
            {VerbSubtypes.EQUIP, AddressOf HandleEquip},
            {VerbSubtypes.UNEQUIP, AddressOf HandleUnequip}
        }

    Private Sub HandleUnequip(verb As IVerb, item As IItem, actor As ICharacter)
        actor.AddMessage($"{actor.Name} equips {item.Name}.")
        actor.Unequip(item)
    End Sub

    Private Sub HandleEquip(verb As IVerb, item As IItem, actor As ICharacter)
        actor.AddMessage($"{actor.Name} unequips {item.Name}.")
        actor.Equip(item)
    End Sub

    <Extension>
    Sub Perform(verb As IVerb, item As IItem, actor As ICharacter)
        Dim handler As PerformHandler = Nothing
        If performTable.TryGetValue(verb.EntitySubtype, handler) Then
            handler.Invoke(verb, item, actor)
            Return
        End If
    End Sub
#End Region
End Module
