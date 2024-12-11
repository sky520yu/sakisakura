Fk:loadTranslationTable {
  ["ki_rox"] = "京",
  ["ki_robot"] = "人机",
  ["ki_red"] = "红温",
}

local extension = Package:new("Leeee")
extension.extensionName = "sasisakura"

-- 定义武将的名称，势力，血量，性别
local ki_rox = General(extension, "ki_rox", "qun", 3, 3, General.Male)

-- 定义技能
local ki_robot = fk.CreateActiveSkill {
    name = "ki_robot",
    anim_type = "control",
    card_num = 1,
    target_num = 1,
    prompt = "#ki_robot",
    can_use = function(self, player)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end,
    card_filter = function(self, to_select, selected)
        return #selected == 0 and Fk:currentRoom():getCardById(to_select).type == Card.TypeBasic
    end,
    target_filter = function(self, to_select, selected)
        local target = Fk:currentRoom():getPlayerById(to_select)
        return #selected == 0 and target ~= Self
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        local choices = { "discard_two", "take_damage" }
        local choice = room:askForChoice(target, choices, self.name)
        if choice == "discard_two" then
            room:askForDiscard(target, 2, 2, true, self.name, false)
        elseif choice == "take_damage" then
            room:damage({
                from = player,
                to = target,
                damage = 1,
                skillName = self.name,
            })
        end
    end,
}

local ki_red = fk.CreateTriggerSkill {
    name = "ki_red",
    anim_type = "defensive",
    events = { fk.Damaged },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self.name) and player:getHandcardNum() > 0
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local prompt = "#ki_red-ask"
        return room:askForSkillInvoke(player, self.name, data, prompt)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:throwCard(room:askForDiscard(player, 1, 1, false, self.name, true), self.name, player)
        local targets = room:getOtherPlayers(player):filter(function(p) return p:isAlive() and not p:isDying() end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#ki_red-choose", self.name)
        if #to > 0 then
            room:transferDamage(player, room:getPlayerById(to[1]), data.damage, self.name)
        end
    end,
}

-- 将技能添加到武将
ki_rox:addSkill(ki_robot)
ki_rox:addSkill(ki_red)

-- 加载翻译表
Fk:loadTranslationTable {
    ["ki_robot"] = "人机",
    ["#ki_robot"] = "人机：出牌阶段，你可以弃置一张手牌，然后选择一名其他角色。该角色需选择一项：1. 弃置两张手牌；2. 受到你造成的一点伤害。",
    [":ki_robot"] = "出牌阶段，你可以弃置一张手牌，然后选择一名其他角色。该角色需选择一项：1. 弃置两张手牌；2. 受到你造成的一点伤害。",
    ["ki_red"] = "红温",
    ["#ki_red-ask"] = "红温：你可以弃置一张手牌，然后将伤害转移给一名其他角色。",
    [":ki_red"] = "当你受到伤害时，你可以弃置一张手牌，然后将伤害转移给一名其他角色（该角色需在场且未处于濒死状态）。",
}

return extension