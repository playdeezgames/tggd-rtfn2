Public Class Grid
    Implements IGrid

    Private _rows As New List(Of IGridRow)

    Public ReadOnly Property Rows As IList(Of IGridRow) Implements IGrid.Rows
        Get
            Return _rows
        End Get
    End Property

    Public Property Size As (Columns As Integer, Rows As Integer) Implements IGrid.Size
        Get
            Dim rows = _rows.Count
            If rows > 0 Then
                Return (_rows(0).Cells.Count, rows)
            Else
                Return (0, rows)
            End If
        End Get
        Set(value As (Columns As Integer, Rows As Integer))
            _rows = Enumerable.Range(0, value.Rows).Select(Function(x) GridRow.Create(value.Columns)).ToList()
        End Set
    End Property

    Public Sub Fill(position As (Column As Integer, Row As Integer), size As (Columns As Integer, Rows As Integer), text As Byte, [class] As Byte) Implements IGrid.Fill
        For Each x In Enumerable.Range(position.Column, size.Columns)
            For Each y In Enumerable.Range(position.Row, size.Rows)
                Rows(y).Cells(x).Character = text
                Rows(y).Cells(x).Attribute = [class]
            Next
        Next
    End Sub
End Class
