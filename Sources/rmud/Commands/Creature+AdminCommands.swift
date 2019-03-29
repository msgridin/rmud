import Foundation

// MARK: - doGoto

extension Creature {
    func doGoto(context: CommandContext) {
        guard let location = findTargetRoom(argument: context.argument1) else {
            return
        }

        sendPoofOut()
        teleportTo(room: location)
        sendPoofIn()
        lookAtRoom(ignoreBrief: false)
    }
    
}

// MARK: - doReload

extension Creature {
    func doReload(context: CommandContext) {
        
    }
}

// MARK: - doLoad

extension Creature {
    func doLoad(context: CommandContext) {
        guard context.hasArguments else {
            send("создать <предмет|монстра> <номер>")
            return
        }
        if context.isSubCommand1(oneOf: ["предмет", "item"]) {
            guard !context.argument2.isEmpty else {
                send("Укажите номер предмета.")
                return
            }
            guard let vnum = Int(context.argument2) else {
                send("Некорректный номер предмета.")
                return
            }
            guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
                send("Предмета с таким номером не существует.")
                return
            }
            let item = Item(prototype: itemPrototype, uid: db.createUid() /*, in: nil*/)
            act("1*и сделал1(,а,о,и) волшебный жест, и появил@1(ся,ась,ось,ись) @1и!", .toRoom, .excludingCreature(self), .item(item))
            act("Вы создали @1в.", .toCreature(self), .item(item))
            
            var isOvermax = false
            let countInWorld = db.itemsCountByVnum[vnum] ?? 0
            if let loadMaximum = itemPrototype.maximumCountInWorld,
                    countInWorld >= loadMaximum {
                act("ВНИМАНИЕ! Превышен максимум экземпляров для @1р!", .toCreature(self), .item(item))
                isOvermax = true
            }
            if level < Level.implementor {
                logIntervention("\(nameNominative) создает\(isOvermax ? ", ПРЕВЫСИВ ПРЕДЕЛ,":"") \(item.nameAccusative) в комнате \"\(inRoom?.name ?? "без имени")\".")
            }
            if item.wearFlags.contains(.take) {
                item.give(to: self)
            } else {
                guard let room = inRoom else {
                    item.extract(mode: .purgeAllContents)
                    send(messages.noRoom)
                    return
                }
                item.put(in: room, activateDecayTimer: true)
                item.groundTimerTicsLeft = nil // disable ground timer
            }
        } else {
            send("Неизвестный тип объекта: \(context.argument1)")
        }
    }
}

// MARK: - doShow

extension Creature {
    private enum ShowMode {
        case areas
        case player
        case statistics
        case snoop
        case spells
        case overmax
        case linkdead
        case moons
        case multiplay
        case cases
        case room
        case mobile
        case item
    }
    
    private struct ShowSubcommand {
        let nameEnglish: String
        let nameNominative: String
        let nameAccusative: String
        let level: UInt8
        let mode: ShowMode
        
        init (_ nameEnglish: String, _ nameNominative: String, _ nameAccusative: String, _ level: UInt8, _ mode: ShowMode) {
            self.nameEnglish = nameEnglish
            self.nameNominative = nameNominative
            self.nameAccusative = nameAccusative
            self.level = level
            self.mode = mode
        }
    }
    
    private static var showSubcommands: [ShowSubcommand] = [
        // FIXME: сделать все в единственном числе? без аргумента показывать полный список
        ShowSubcommand("areas",     "области",    "области",    Level.lesserGod, .areas ),
        ShowSubcommand("player",    "персонаж",   "персонажа",  Level.lesserGod, .player ),
        ShowSubcommand("stats",     "статистика", "статистику", Level.lesserGod, .statistics ),
        ShowSubcommand("snooping",  "шпионаж",    "шпионаж",    Level.middleGod, .snoop ),
        ShowSubcommand("spells",    "заклинания", "заклинания", Level.lesserGod, .spells ),
        ShowSubcommand("overmax",   "превышение", "превышение", Level.greaterGod, .overmax ),
        ShowSubcommand("linkdead",  "связь",      "связь",      Level.lesserGod, .linkdead ),
        ShowSubcommand("moons",     "луны",       "луны",       Level.middleGod, .moons ),
        ShowSubcommand("multiplay", "мультиплей", "мультиплей", Level.lesserGod, .multiplay ),
        ShowSubcommand("cases",     "падежи",     "падежи",     Level.lesserGod, .cases),
        ShowSubcommand("room",      "комната",    "комнату",    Level.lesserGod, .room),
        ShowSubcommand("mobile",    "монстр",     "монстра",    Level.lesserGod, .mobile),
        ShowSubcommand("item",      "предмет",    "предмет",    Level.lesserGod, .item)
    ]
    
    func doShow(context: CommandContext) {
        let modeString = context.argument1
        
        guard !modeString.isEmpty else {
            send("Режимы:")
            showModesHelp()
            return
        }
        
        guard let showMode = getShowMode(modeString) else {
            send("Неверный режим. Доступные режимы:")
            showModesHelp()
            return
        }
        
        let value = context.argument2
        
        switch showMode {
        case .areas:
            if value.isEmpty {
                let areas = areaManager.areasByStartingVnum.sorted { $0.key < $1.key }
                for (_, area) in areas {
                    let fromRoom = String(area.vnumRange.lowerBound).leftExpandingTo(minimumLength: 5)
                    let toRoom = String(area.vnumRange.upperBound).rightExpandingTo(minimumLength: 5)
                    let roomCount = String(area.rooms.count).rightExpandingTo(minimumLength: 4)
                    let areaName = area.lowercasedName.rightExpandingTo(minimumLength: 30)
                    let age = String(area.age).leftExpandingTo(minimumLength: 2)
                    let resetInterval = String(area.resetInterval).rightExpandingTo(minimumLength: 2)
                    let resetCondition = area.resetCondition.nominative
                    send("\(fromRoom)-\(toRoom) (:\(roomCount)) \(areaName) Возраст: \(age)/\(resetInterval)   Сброс: \(resetCondition)")
                }
            } else {
                // FIXME
            }
        case .player:
            break
        case .statistics:
            break
        case .snoop:
            break
        case .spells:
            break
        case .overmax:
            break
        case .linkdead:
            break
        case .moons:
            break
        case .multiplay:
            break
        case .cases:
            showCases()
        case .room:
            guard !value.isEmpty else {
                listRooms()
                return
            }
            guard let vnum = Int(value) else {
                send("Некорректный номер комнаты.")
                return
            }
            showRoom(vnum: vnum)
        case .mobile:
            guard !value.isEmpty else {
                listMobiles()
                return
            }
            guard let vnum = Int(value) else {
                send("Некорректный номер существа.")
                return
            }
            showMobile(vnum: vnum)
        case .item:
            guard !value.isEmpty else {
                listItems()
                return
            }
            guard let vnum = Int(value) else {
                send("Некорректный номер предмета.")
                return
            }
            showItem(vnum: vnum)
        }
    }

    private func showModesHelp() {
        var output = ""
        var modes: [String] = []
        for subcommand in Creature.showSubcommands {
            guard subcommand.level <= level else { continue }
            modes.append(subcommand.nameAccusative)
        }
        if !modes.isEmpty {
            for (index, mode) in modes.enumerated() {
                if index > 0 && index % 5 == 0 {
                    output += "\n"
                }
                output += mode.rightExpandingTo(minimumLength: 16)
            }
        } else {
            output += "Недоступно ни одного режима показа."
        }
        send(output)
    }
    
    private func getShowMode(_ modeString: String) -> ShowMode? {
        for subcommand in Creature.showSubcommands {
            guard subcommand.level <= level else { continue }
            guard modeString.isAbbreviation(ofOneOf: [subcommand.nameEnglish, subcommand.nameNominative, subcommand.nameAccusative], caseInsensitive: true) else { continue }
            return subcommand.mode
        }
        return nil
    }
    
    private func showCases() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        let table = StringTable()
        for (vnum, mobilePrototype) in area.prototype.mobilePrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            let mp = mobilePrototype
            let isAnimate = !mp.flags.contains(.inanimate)
            let compressed = endings.compress(
                names: [mp.nameNominative, mp.nameGenitive, mp.nameDative, mp.nameAccusative, mp.nameInstrumental, mp.namePrepositional],
                isAnimate: isAnimate)

            //send("\(nBlu())\(vnum)\(nNrm()) \(isAnimate ? nGrn() : nYel())\(compressed)\(nNrm()) | \(mp.nameNominative) | \(mp.nameGenitive) | \(mp.nameDative) | \(mp.nameAccusative) | \(mp.nameInstrumental) | \(mp.namePrepositional)")
            table.add(row: [String(vnum), compressed, mp.nameGenitive, mp.nameDative, mp.nameAccusative, mp.nameInstrumental, mp.namePrepositional], colors: [nBlu(), isAnimate ? nGrn() : nYel()])
        }
        send(table.description)
    }
    
    private func listRooms() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for room in area.rooms.sorted(by: { $0.vnum < $1.vnum }) {
            send("\(nBlu())\(room.vnum)\(nNrm()) \(room.prototype.name)")
        }
    }
    
    private func showRoom(vnum: Int) {
        guard let room = db.roomsByVnum[vnum] else {
            send("Комнаты с виртуальным номером \(vnum) не существует.")
            return
        }
        let roomString = room.prototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(roomString.trimmingCharacters(in: .newlines))
    }

    private func listMobiles() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for (vnum, mobilePrototype) in area.prototype.mobilePrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            send("\(nBlu())\(vnum)\(nNrm()) \(mobilePrototype.nameNominative)")
        }
    }

    private func showMobile(vnum: Int) {
        guard let mobilePrototype = db.mobilePrototypesByVnum[vnum] else {
            send("Монстра с виртуальным номером \(vnum) не существует.")
            return
        }
        let mobileString = mobilePrototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(mobileString.trimmingCharacters(in: .newlines))
    }
    
    private func listItems() {
        guard let area = inRoom?.area else {
            send("Комната, в которой Вы находитесь, не принадлежит ни одной области.")
            return
        }
        for (vnum, itemPrototype) in area.prototype.itemPrototypesByVnum.sorted(by: { $0.key < $1.key }) {
            send("\(nBlu())\(vnum)\(nNrm()) \(itemPrototype.nameNominative)")
        }
    }

    private func showItem(vnum: Int) {
        guard let itemPrototype = db.itemPrototypesByVnum[vnum] else {
            send("Предмета с виртуальным номером \(vnum) не существует.")
            return
        }
        let itemString = itemPrototype.save(for: .ansiOutput(creature: self), with: db.definitions)
        send(itemString.trimmingCharacters(in: .newlines))
    }
}

// MARK: - doSet

extension Creature {
    func doSet(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            send("установить <комнате|монстру|предмету> <номер> [поле значение]")
            return
        }
        if context.isSubCommand1(oneOf: ["комнате", "комната", "room"]) {
            guard let vnum = Int(context.argument2) else {
                send("Некорректный номер комнаты.")
                return
            }
            guard let field = context.scanWord() else {
                send("Вы можете установить следующие поля комнаты:")
                showRoomFields()
                return
            }
            let value = context.restOfString()
            guard !value.isEmpty else {
                send("Укажите значение.")
                return
            }
            setRoomPrototypeField(vnum: vnum, fieldName: field, value: value)
        }
    }
    
    private func showRoomFields() {
        let text = format(fieldDefinitions: db.definitions.roomFields)
        send(text)
    }
    
    private func setRoomPrototypeField(vnum: Int, fieldName: String, value: String) {
        guard let room = db.roomsByVnum[vnum] else {
            send("Комнаты с виртуальным номером \(vnum) не существует.")
            return
        }
        let lowercasedFieldName = fieldName.lowercased()
        guard let field = db.definitions.roomFields.fieldsByLowercasedName[lowercasedFieldName] else {
            send("Поля комнаты с таким названием не существует.")
            return
        }
        let roomString = room.prototype.save(for: .areaFile, with: db.definitions)
        let parser = AreaFormatParser(db: db, definitions: db.definitions)
        do {
            try parser.parse(data: [UInt8](roomString.data(using: .utf8) ?? Data()))
        } catch {
            send("Ошибка парсера: \(error)")
            return
        }
        guard let area = room.area,
                let entity = db.areaEntitiesByLowercasedName[area.lowercasedName]?.roomEntitiesByVnum[vnum] else {
            send("Ошибка при поиске прототипа.")
            return
        }
        
        let fieldNameWithIndex: String
        if let name = structureName(fromFieldName: lowercasedFieldName),
                let index = entity.lastStructureIndex[name] {
            fieldNameWithIndex = appendIndex(toName: lowercasedFieldName, index: index)
        } else {
            fieldNameWithIndex = lowercasedFieldName
        }
        send("Не реализовано.")
//        roomEntity[fieldNameWithIndex]
//        print("\(roomEntity)")
    }

    private func format(fieldDefinitions: FieldDefinitions) -> String {
        var result = ""
        
        for (index, fieldName) in fieldDefinitions.fieldsByLowercasedName.keys.sorted().enumerated() {
            if index != 0 {
                result += "\n"
            }
            result += fieldName.uppercased() //.rightExpandingTo(minimumLength: 20)
        }
        return result
    }
}

// MARK: - doArea

extension Creature {
    func doArea(context: CommandContext) {
        guard !context.argument1.isEmpty else {
            send("""
                 Поддерживаемые команды:
                 область список
                 область создать <название> [стартовый внум] [последний внум]
                 область сохранить [название | все]
                 область идти [название]
                 """)
            return
        }

        if context.isSubCommand1(oneOf: ["список", "list"]) {
        } else if context.isSubCommand1(oneOf: ["создать", "create"]) {
        } else if context.isSubCommand1(oneOf: ["сохранить", "save"]) {
            saveArea(name: context.argument2)
        } else if context.isSubCommand1(oneOf: ["идти", "goto"]) {
            gotoArea(name: context.argument2)
        }
    }
    
    private func saveArea(name: String) {
        var areasToSave: [Area] = []
        if name.isEmpty {
            guard let area = inRoom?.area else {
                send("Комната, в который Вы находитесь, не принадлежит ни к одной из областей.")
                return
            }
            areasToSave = [area]
        } else {
            if let area = areaManager.areasByLowercasedName[name.lowercased()] {
                areasToSave = [area]
            } else if name.isEqual(toOneOf: ["все", "all"], caseInsensitive: false) {
                guard !areaManager.areasByLowercasedName.isEmpty else {
                    send("Не найдено ни одной области.")
                    return
                }
                areasToSave = areaManager.areasByLowercasedName.sorted { pair1, pair2 in
                    pair1.key < pair2.key
                }.map{ $1 }
            } else {
                send("Области с таким названием не существует.")
                return
            }
        }
        
        for area in areasToSave {
            areaManager.save(area: area)
            send("Область сохранена: \(area.lowercasedName)")
        }
    }
    
    private func gotoArea(name: String) {
        if let area = areaManager.findArea(byAbbreviatedName: name) {
            let targetRoom: Room
            if let originVnum = area.originVnum,
                    let room = db.roomsByVnum[originVnum] {
                targetRoom = room
            } else if let room = area.rooms.first {
                send("У области отсутствует основная комната, переход в первую комнату области.")
                targetRoom = room
            } else {
                send("Область пуста.")
                return
            }
            
            sendPoofOut()
            teleportTo(room: targetRoom)
            sendPoofIn()
            lookAtRoom(ignoreBrief: false)
        } else {
            send("Области с таким названием не существует.")
            return
        }
    }
}

// MARK: - Utility methods

extension Creature {
    func sendPoofOut() {
        if let player = player,
                !player.poofout.isEmpty,
                let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofout)
            }
        } else {
            act("1*и исчез1(,ла,ло,ли) в клубах дыма.", .toRoom, .excludingCreature(self))
        }
    }
    
    func sendPoofIn() {
        if let player = player,
            !player.poofin.isEmpty,
            let room = inRoom {
            for to in room.creatures {
                guard to != self && to.canSee(self) else { continue }
                to.send(player.poofin)
            }
        } else {
            act("1*и появил1(ся,ась,ось,ись) в клубах дыма.", .toRoom, .excludingCreature(self))
        }
    }
}