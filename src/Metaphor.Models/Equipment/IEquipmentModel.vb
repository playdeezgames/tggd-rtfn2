Public Interface IEquipmentModel
    ReadOnly Property HasItems As Boolean
    ReadOnly Property All As IEnumerable(Of IItemModel)
End Interface
