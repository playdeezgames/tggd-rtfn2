Public Interface IItemModel
    ReadOnly Property Name As String
    Sub Take()
    Sub Drop()
    Sub Describe()
    ReadOnly Property Verbs As IEnumerable(Of IVerbModel)
    ReadOnly Property ItemType As String
End Interface
