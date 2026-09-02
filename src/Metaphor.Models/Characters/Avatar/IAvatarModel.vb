Public Interface IAvatarModel
    ReadOnly Property Inventory As IInventoryModel
    ReadOnly Property AvailableVerbs As IEnumerable(Of IVerbModel)
    ReadOnly Property DialogMode As String
    ReadOnly Property Map As IMapModel
    ReadOnly Property Equipment As IEquipmentModel
    ReadOnly Property Combat As IAvatarCombatModel
End Interface
