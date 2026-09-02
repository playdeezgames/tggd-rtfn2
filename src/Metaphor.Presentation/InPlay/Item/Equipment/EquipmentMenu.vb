
Imports Metaphor.Processing
Imports TGGD.Presentation

Friend Class EquipmentMenu
    Inherits MetaphorPickerMenu

    Private Sub New(context As IDisplayContext, model As IWorldModel, previous As DialogSource)
        MyBase.New(context, model, previous)
    End Sub

    Public Overrides ReadOnly Property PromptText As String
        Get
            Return "Equipment:"
        End Get
    End Property

    Protected Overrides ReadOnly Property Launchers As IEnumerable(Of LaunchDelegate)
        Get
            Return Enumerable.Empty(Of LaunchDelegate).
                Append(AddressOf ChooseNeverMind).
                Concat(Model.Avatar.Equipment.All.Select(AddressOf ChooseEquippedItem))
        End Get
    End Property

    Private Function ChooseEquippedItem(itemModel As IItemModel) As LaunchDelegate
        Return Function(c, m, p) DialogChoice.CreateEnabled(itemModel.Name, EquippedItemMenu.Launch(c, m, p, itemModel))
    End Function

    Friend Shared Function Launch(context As IDisplayContext, model As IWorldModel, previous As DialogSource) As DialogSource
        Return Function() New EquipmentMenu(context, model, previous)
    End Function

    Private Function ChooseNeverMind(context As IDisplayContext, model As IWorldModel, previous As DialogSource) As IDialogChoice
        Return DialogChoice.CreateEnabled("Never Mind", InPlay.Launch(context, model, previous))
    End Function
End Class
