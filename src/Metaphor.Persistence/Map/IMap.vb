Public Delegate Sub MapInitializer(map As IMap)
Public Interface IMap
    Inherits IMetaphorEntity
    Function CreateLocation(locationType As String, name As String, position As (Column As Integer, Row As Integer), Optional initializer As LocationInitializer = Nothing) As ILocation
    ReadOnly Property Size As (Columns As Integer, Rows As Integer)
    ReadOnly Property Locations As IEnumerable(Of ILocation)
    Function GetLocation(column As Integer, row As Integer) As ILocation
End Interface
