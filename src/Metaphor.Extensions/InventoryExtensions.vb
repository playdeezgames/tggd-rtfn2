Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module InventoryExtensions
#Region "Pen"
    <Extension>
    Friend Function CreatePen(inventory As IInventory) As IItem
        Return inventory.CreateItem(ItemSubtypes.PEN, "Pen #15", AddressOf ItemInitializationExtensions.InitializePen)
    End Function
#End Region
End Module
