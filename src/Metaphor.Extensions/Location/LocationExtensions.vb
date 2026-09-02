Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence

Public Module LocationExtensions
#Region "Description"
    Private Delegate Sub LocationDescriber(location As ILocation)
    Private ReadOnly describers As New Dictionary(Of String, LocationDescriber) From
        {
        }
    <Extension>
    Friend Sub Describe(location As ILocation)
        Dim describer As LocationDescriber = Nothing
        If describers.TryGetValue(location.EntitySubtype, describer) Then
            describer(location)
        End If
    End Sub
#End Region
#Region "N00b"
    <Extension>
    Friend Function CreateN00b(location As ILocation, name As String) As ICharacter
        Return location.CreateCharacter(CharacterSubtypes.N00B, name, AddressOf CharacterInitializationExtensions.InitializeN00b)
    End Function
#End Region
End Module
