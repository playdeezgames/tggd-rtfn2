Imports System.Runtime.CompilerServices
Imports Metaphor.Persistence
Imports TGGD.Extensions

Public Module CharacterCombatExtensions
    <Extension>
    Public Sub Fight(character As ICharacter)
        character.AddMessage($"{character.Name} fights!")
        Dim enemy = character.Location.GetOtherCharacters(character).First(Function(x) x.HasTag(Tags.ENEMY))
        character.Attack(enemy)
        character.DoCounterAttacks()
    End Sub
    <Extension>
    Private Sub DoCounterAttacks(character As ICharacter)
        For Each enemy In character.Location.GetOtherCharacters(character).Where(Function(x) x.HasTag(Tags.ENEMY))
            enemy.Attack(character)
        Next
    End Sub
    <Extension>
    Private Sub Attack(attacker As ICharacter, defender As ICharacter)
        attacker.AddMessage($"{attacker.Name} attacks {defender.Name}.")
        Dim attackRoll = attacker.RollAttack()
        attacker.AddMessage($"{attacker.Name} rolls an attack of {attackRoll}.")
        Dim defendRoll = defender.RollDefend()
        attacker.AddMessage($"{defender.Name} rolls an attack of {defendRoll}.")
        Dim damage = Math.Max(0, attackRoll - defendRoll)
        attacker.AddMessage($"{defender.Name} takes {damage} damage.")
        If damage > 0 Then
            defender.ChangeCounter(Counters.HEALTH, -damage)
            If defender.IsDead() Then
                attacker.AddMessage($"{attacker.Name} kills {defender.Name}.")
                defender.Die()
            Else
                attacker.AddMessage($"{defender.Name} now has {defender.GetCounterStatistic(Counters.HEALTH)} health.")
            End If
        End If
    End Sub
    <Extension>
    Public Function IsDead(character As ICharacter) As Boolean
        Return character.IsCounterMinimum(Counters.HEALTH)
    End Function
    <Extension>
    Friend Sub Die(character As ICharacter)
        If Not character.IsAvatar Then
            character.Remove()
        End If
    End Sub
    <Extension>
    Private Function RollAttack(character As ICharacter) As Integer
        Return Math.Min(Enumerable.Range(0, character.GetAttack()).Select(Function(x) RNG.RollDice("1d6/6")).Sum(), character.GetAttackCap())
    End Function
    <Extension>
    Private Function RollDefend(character As ICharacter) As Integer
        Return Math.Min(Enumerable.Range(0, character.GetDefend()).Select(Function(x) RNG.RollDice("1d6/6")).Sum(), character.GetDefendCap())
    End Function
    <Extension>
    Public Sub Run(character As ICharacter)
        Dim verb = RNG.FromEnumerable(character.Verbs.Where(Function(x) x.EntitySubtype = VerbSubtypes.MOVE))
        If Not verb.CanPerform(character, character) Then
            character.AddMessage($"{character.Name} cannot run!")
        Else
            character.AddMessage($"{character.Name} runs!")
            'TODO: counter attacks of opportunity
            verb.Perform(character, character)
        End If
    End Sub
    <Extension>
    Public Function IsInCombat(character As ICharacter) As Boolean
        Return character.Location.GetOtherCharacters(character).Any(Function(x) x.HasTag(Tags.ENEMY))
    End Function
    <Extension>
    Friend Function GetAttack(character As ICharacter) As Integer
        Return character.GetCounter(Counters.ATTACK) + character.GetEquipment().Sum(Function(x) x.GetCounter(Counters.ATTACK))
    End Function
    <Extension>
    Friend Function GetAttackCap(character As ICharacter) As Integer
        Return character.GetCounter(Counters.ATTACK_CAP) + character.GetEquipment().Sum(Function(x) x.GetCounter(Counters.ATTACK_CAP))
    End Function
    <Extension>
    Friend Function GetDefend(character As ICharacter) As Integer
        Return character.GetCounter(Counters.DEFEND) + character.GetEquipment().Sum(Function(x) x.GetCounter(Counters.DEFEND))
    End Function
    <Extension>
    Friend Function GetDefendCap(character As ICharacter) As Integer
        Return character.GetCounter(Counters.DEFEND_CAP) + character.GetEquipment().Sum(Function(x) x.GetCounter(Counters.DEFEND_CAP))
    End Function
#Region "Equipment"
    <Extension>
    Public Function HasEquipment(character As ICharacter) As Boolean
        Return character.GetYokage(Yokages.EQUIPMENT).Any()
    End Function
    <Extension>
    Public Function GetEquipment(character As ICharacter) As IEnumerable(Of IItem)
        Return character.GetYokage(Yokages.EQUIPMENT).Select(Function(x) character.World.GetItem(x))
    End Function
    <Extension>
    Function CanEquip(character As ICharacter, item As IItem) As Boolean
        Return item.HasCounter(Counters.EQUIP_FLAGS) AndAlso
            ((item.GetCounter(Counters.EQUIP_FLAGS) And
                character.GetEquipment().Aggregate(
                    0,
                    Function(x, y) x Or y.GetCounter(Counters.EQUIP_FLAGS))) = 0)
    End Function
    <Extension>
    Function CanUnequip(character As ICharacter, item As IItem) As Boolean
        Return item.HasCounter(Counters.EQUIP_FLAGS) AndAlso character.GetYokage(Yokages.EQUIPMENT).Contains(item.EntityId)
    End Function
    <Extension>
    Sub Equip(character As ICharacter, item As IItem)
        item.Container = Nothing
        character.AddToYokage(Yokages.EQUIPMENT, item.EntityId)
    End Sub
    <Extension>
    Sub Unequip(character As ICharacter, item As IItem)
        character.RemoveFromYokage(Yokages.EQUIPMENT, item.EntityId)
        item.Container = character.Inventory
    End Sub
#End Region
End Module
