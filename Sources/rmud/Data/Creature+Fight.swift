import Foundation

extension Creature {
    func primaryWeapon() -> Item? {
        for position in EquipmentPosition.primaryWeapon {
            if let item = equipment[position], item.hasType(.weapon) {
                return item
            }
        }
        return nil
    }
    
    // Два свободных монстра всегда за одно, если только
    //они не дерутся друг с другом.
    //FIXME arilou: к сожалению, из-за этого монстры-агрессоры будут считать своими
    // монстров-защитников, которые дерутся на стороне игроков :(
    func isMobsFriendship(with victim: Creature) -> Bool {
        return isMobile && victim.isMobile &&
            fighting != victim && victim.fighting != self && // случай fighting == NULL учтён автоматически :)
            !hasPlayerMaster() && !victim.hasPlayerMaster()
    }
    
    // Общий враг - тоже объединяющий фактор
    func isSameEnemy(with victim: Creature) -> Bool {
        // бьёт того же, кого и ch или ch бьёт того, кто бьёт vict
        return (isFighting &&
                (fighting == victim.fighting || fighting!.fighting == victim)) ||
               (victim.isFighting && victim.fighting!.fighting == self) // бьёт того, кто бьёт self
    }
    
    func damagePositionBonus(damage: Int) -> Int {
        if !position.isAwake { return damage }
        else if position == .resting { return damage / 2 }
        else if position == .sitting { return damage / 4 }
        return 0
    }
}
