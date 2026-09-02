Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module ItemExtensions
#Region "Describe"
    Private Delegate Sub ItemDescriber(item As IItem)
    ReadOnly describeTable As New Dictionary(Of String, ItemDescriber) From
        {
        }
    Private Sub DescribeItem(item As IItem)
        item.AddMessage($"It is a {item.Name}.")
        item.DescribeWeapon()
    End Sub
    <Extension>
    Private Sub DescribeWeapon(item As IItem)
        If Not item.HasTag(Tags.WEAPON) Then
            Return
        End If
        item.AddMessage($"Attack: {item.GetCounter(Counters.ATTACK)}(Cap {item.GetCounter(Counters.ATTACK_CAP)})")
    End Sub
    <Extension>
    Sub Describe(item As IItem)
        Dim describer As ItemDescriber = Nothing
        If describeTable.TryGetValue(item.EntitySubtype, describer) Then
            describer.Invoke(item)
        Else
            DescribeItem(item)
        End If
    End Sub
#End Region
End Module
