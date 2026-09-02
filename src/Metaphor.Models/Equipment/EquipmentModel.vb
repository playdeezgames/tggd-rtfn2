Imports Metaphor.Extensions
Imports Metaphor.Persistence

Friend Class EquipmentModel
    Implements IEquipmentModel

    Private ReadOnly character As ICharacter

    Private Sub New(character As ICharacter)
        Me.character = character
    End Sub

    Public ReadOnly Property HasItems As Boolean Implements IEquipmentModel.HasItems
        Get
            Return character.HasEquipment()
        End Get
    End Property

    Public ReadOnly Property All As IEnumerable(Of IItemModel) Implements IEquipmentModel.All
        Get
            Return character.GetEquipment().Select(AddressOf ItemModel.Create)
        End Get
    End Property

    Friend Shared Function Create(character As ICharacter) As IEquipmentModel
        Return New EquipmentModel(character)
    End Function
End Class
