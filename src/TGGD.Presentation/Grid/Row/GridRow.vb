Friend Class GridRow
    Implements IGridRow

    Private _cells As List(Of IGridCell)

    Private Sub New(cells As Integer)
        _cells = Enumerable.Range(0, cells).Select(Function(x) GridCell.Create()).ToList()
    End Sub

    Public ReadOnly Property Cells As IList(Of IGridCell) Implements IGridRow.Cells
        Get
            Return _cells
        End Get
    End Property

    Friend Shared Function Create(cells As Integer) As IGridRow
        Return New GridRow(cells)
    End Function
End Class
