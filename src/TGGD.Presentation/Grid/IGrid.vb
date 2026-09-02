Public Interface IGrid
    ReadOnly Property Rows As IList(Of IGridRow)
    Property Size As (Columns As Integer, Rows As Integer)
    Sub Fill(position As (Column As Integer, Row As Integer), size As (Columns As Integer, Rows As Integer), text As Byte, [class] As Byte)
End Interface
