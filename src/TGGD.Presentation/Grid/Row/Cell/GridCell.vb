Friend Class GridCell
    Implements IGridCell

    Private Sub New()
        Character = 64
        Attribute = 15
    End Sub

    Public Property Character As Byte Implements IGridCell.Character

    Public Property Attribute As Byte Implements IGridCell.Attribute

    Public Property ToolTip As String Implements IGridCell.ToolTip

    Friend Shared Function Create() As IGridCell
        Return New GridCell
    End Function
End Class
