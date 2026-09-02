Public Interface ILocationModel
    ReadOnly Property AvailableVerbs As IEnumerable(Of IVerbModel)
    ReadOnly Property Features As IFeaturesModel
    ReadOnly Property Characters As ICharactersModel
    ReadOnly Property Ground As IGroundModel
    ReadOnly Property LocationType As String
    ReadOnly Property Name As String
    ReadOnly Property Column As Integer
    ReadOnly Property Row As Integer
End Interface
