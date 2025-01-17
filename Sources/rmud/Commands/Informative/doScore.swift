extension Creature {
    func doScore(context: CommandContext) {
        let raceName = race.info.namesByGender[gender] ?? "(раса неизвестна)"
        
        let className = classId.info.namesByGender[gender] ?? "(профессия неизвестна)"

        if let player = player {
            do {
                let affectedAgeComponents = GameTimeComponents(gameSeconds: player.affectedAgeSeconds())
                act("Вы &1 1и, &2 #1 уровня. Вам #2 #2(год,года,лет).", .toSleeping,
                    .to(self), .text(raceName), .text(className), .number(Int(level)), .number(affectedAgeComponents.years))
            }
            
            do {
                let realAgeComponents = GameTimeComponents(gameSeconds: player.realAgeSeconds)
                if realAgeComponents.months == 0 && realAgeComponents.days == 0 {
                    send("У Вас сегодня день рождения.")
                }
            }
        } else {
            act("Вы &1 1и, &2 #1 уровня.", .toSleeping,
                .to(self), .text(raceName), .text(className), .number(Int(level)))
        }
        
        if context.argument1.isAbbrevCI(ofAny: ["склонение", "declension"]) {
            act("Склонение Вашего имени: 1и/1р/1д/1в/1т/1п.", .toSleeping, .to(self))
        }
        
        if let player = player {
            if !player.customTitle.isEmpty {
                send("Вы носите титул \"\(player.customTitle)\".")
            }
            if !player.titleRequest.isEmpty {
                send("Вы запросили титул \"\(player.titleRequest)\".")
            }
        }
        
        act("У Вас сейчас #1 из #2 очк#1(о,а,ов) жизни и #3 из #4 очк#3(о,а,ов) бодрости.",
            .toSleeping, .to(self), .number(hitPoints), .number(affectedMaximumHitPoints()), .number(movement), .number(affectedMaximumMovement()))
        
        let alignment = affectedAlignment()
        let alignmentCategory = alignment.category
        send(alignment.category.description)
        
        if classId.info.classGroup == .wizard  {
            switch alignmentCategory {
            case .veryGood, .moderatelyGood, .slightlyGood:
                send("Вам покровительствует белая луна, Солинари.")
            case .barelyGood:
                send("Вам пока еще покровительствует белая луна, Солинари.")
            case .neutralBorderingGood, .neutralBorderingEvil:
                send("Вам пока еще покровительствует красная луна, Лунитари.")
            case .neutral:
                send("Вам покровительствует красная луна, Лунитари.")
            case .barelyEvil:
                send("Вам пока еще покровительствует черная луна, Нуитари.")
            case .slightlyEvil, .moderatelyEvil, .veryEvil:
                send("Вам покровительствует черная луна, Нуитари.")
            }
        }

        if isPlayer && level <= maximumMortalLevel {
            var format = "Вы набрали #1 очк#1(о,а,ов) опыта."
            let experienceNeeded = classId.info.experience(forLevel: level + 1) - experience
            if experienceNeeded > 0 {
                format += " До следующего уровня осталось #2."
            }
            act(format, .toSleeping, .to(self), .number(experience), .number(experienceNeeded))
        }
        
        act("У Вас есть # стальн#(ая,ые,ых) монет#(а,ы,).", .toSleeping, .to(self), .number(gold))

        if let player = player {
            let seconds = player.playedSecondsSaved + player.playedSecondsUnsaved
            let hours = (seconds / secondsPerRealHour) % 24 // 0..23 hours
            let days = (seconds / secondsPerRealDay) // 0..34 days
            //seconds -= (secondsPerRealDay * days)
            
            act("Вы играете #1 д#1(ень,ня,ней) и #2 час#2(,а,ов).", .toSleeping,
                .to(self), .number(Int(days)), .number(Int(hours)))
        }
    }
}
