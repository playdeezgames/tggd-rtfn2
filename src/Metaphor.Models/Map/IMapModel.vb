Public Interface IMapModel
    ReadOnly Property Columns As Integer
    ReadOnly Property Rows As Integer
    ReadOnly Property Locations As IEnumerable(Of ILocationModel)
End Interface
