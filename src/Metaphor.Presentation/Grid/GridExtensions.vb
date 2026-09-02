Imports System.Runtime.CompilerServices
Imports Metaphor.Extensions
Imports Metaphor.Processing
Imports TGGD.Presentation

Friend Module GridExtensions
    Private ReadOnly featureTypeDeets As New Dictionary(Of String, (Text As Byte, [Class] As Byte)) From
        {
            {FeatureSubtypes.CHEST, (127, &H6)}
        }
    Private ReadOnly itemTypeDeets As New Dictionary(Of String, (Text As Byte, [Class] As Byte)) From
        {
            {ItemSubtypes.DAGGER, (CByte(Asc("-")), &H8)}
        }
    Private ReadOnly characterTypeDeets As New Dictionary(Of String, (Text As Byte, [Class] As Byte)) From
        {
            {CharacterSubtypes.N00B, (2, &HF)},
            {CharacterSubtypes.RAT, (CByte(Asc("r")), &H8)}
        }
    Private ReadOnly locationTypeDeets As New Dictionary(Of String, (Text As Byte, [Class] As Byte)) From
        {
            {LocationSubtypes.WALL, (CByte(Asc("#")), &H91)},
            {LocationSubtypes.FLOOR, (CByte(Asc(".")), &H7)}
        }
    <Extension>
    Friend Sub Refresh(grid As IGrid, model As IWorldModel)
        Dim mapModel = model.Avatar.Map
        grid.Size = (mapModel.Columns, mapModel.Rows)
        For Each location In mapModel.Locations
            Dim character = location.Characters.All.FirstOrDefault()
            Dim feature = location.Features.AllVisible.FirstOrDefault()
            Dim item = location.Ground.Items.FirstOrDefault
            Dim deets = If(
                character Is Nothing,
                If(
                    feature Is Nothing,
                    If(
                        item Is Nothing,
                        locationTypeDeets(location.LocationType),
                        itemTypeDeets(item.ItemType)),
                    featureTypeDeets(feature.FeatureType)),
                characterTypeDeets(character.CharacterType))
            Dim cell = grid.Rows(location.Row).Cells(location.Column)
            cell.Character = deets.Text
            cell.Attribute = deets.Class
            cell.ToolTip = If(character?.Name, If(feature?.Name, location.Name))
        Next
    End Sub
End Module
