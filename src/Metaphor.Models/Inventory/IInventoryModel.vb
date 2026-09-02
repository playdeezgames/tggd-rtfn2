Public Interface IInventoryModel
    ReadOnly Property HasItems As Boolean
    ReadOnly Property ItemStacks As IEnumerable(Of IItemStackModel)
End Interface
