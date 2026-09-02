Imports Metaphor.Persistence

Friend Class GroundModel
    Implements IGroundModel

    Private ReadOnly location As ILocation

    Private Sub New(location As ILocation)
        Me.location = location
    End Sub

    Public ReadOnly Property HasItems As Boolean Implements IGroundModel.HasItems
        Get
            Return location.Inventory.HasItems
        End Get
    End Property

    Public ReadOnly Property Items As IEnumerable(Of IItemModel) Implements IGroundModel.Items
        Get
            Return location.Inventory.Items.Select(AddressOf ItemModel.Create)
        End Get
    End Property

    Public ReadOnly Property Inventory As IInventoryModel Implements IGroundModel.Inventory
        Get
            Return InventoryModel.Create(location.Inventory)
        End Get
    End Property

    Friend Shared Function Create(entity As ILocation) As IGroundModel
        Return New GroundModel(entity)
    End Function
End Class
