Public Delegate Sub CharacterInitializer(character As ICharacter)
Public Interface ICharacter
    Inherits IMetaphorEntity
    Property Location As ILocation
    ReadOnly Property Map As IMap
    Property DialogMode As String
End Interface
