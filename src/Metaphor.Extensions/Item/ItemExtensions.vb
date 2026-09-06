Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module ItemExtensions
#Region "Describe"
    Private Delegate Sub ItemDescriber(item As IItem)
    ReadOnly describeTable As New Dictionary(Of String, ItemDescriber) From
        {
            {ItemSubtypes.PEN, AddressOf DescribePen}
        }

    Private Sub DescribePen(item As IItem)
        DescribeItem(item)
        item.AddMessage($"Ink: {item.GetCounterStatistic(Counters.INK)}")
    End Sub

    Private Sub DescribeItem(item As IItem)
        item.AddMessage($"It is a {item.Name}.")
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
