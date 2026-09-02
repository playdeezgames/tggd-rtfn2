Friend NotInheritable Class EquipFlags
    Private Sub New() : End Sub
    Friend Const MAIN_HAND = 1
    Friend Const OFF_HAND = 2
    Friend Const BOTH_HANDS = MAIN_HAND Or OFF_HAND
End Class
