Fk:loadTranslationTable {
  ["ki_god_Shiki"] = "神山識",
  ["ki_bat"] = "御结",
  ["ki_omusubi"] = "饭团",
}
local extension = Package:new("Shiki")
extension.extensionName = "sakisakura"
-- 定义武将的名称，势力，血量，性别
local Kamiyama_Shiki = General(extension, "ki_god_Shiki", "god", 3, 5, General.Female)

-- 定义技能
local ki_bat = fk.CreateActiveSkill {
    name = "ki_bat",
    anim_type = "support",
    card_num = 0,
    target_num = 1,
    prompt = "#ki_bat",
    can_use = function(self, player)
        -- 修改为允许使用两次
        return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
    end,
    card_filter = function(self, to_select, selected)
        return false
    end,
    target_filter = function(self, to_select, selected)
        local target = Fk:currentRoom():getPlayerById(to_select)
        return #selected == 0 and target ~= Self
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        local skills = {}
        for _, s in ipairs(target.player_skills) do
            if not (s:isEquipmentSkill(target) or s.name[#s.name] == "&" or player:hasSkill(s.name, true) or s.name:startsWith("#")) then
                table.insertIfNeed(skills, s.name)
            end
        end
        if #skills == 0 then return end
        local to_delete = room:askForChoices(player, skills, 1, 1, self.name)
        if #to_delete > 0 then
            room:handleAddLoseSkills(player, to_delete)
            -- 发动御结后失去一点体力
            room:loseHp(player, 1)
        end
    end,
}

-- 定义防御技
local ki_omusubi = fk.CreateTriggerSkill {
    name = "ki_omusubi",
    anim_type = "defensive",
    events = { fk.DamageInflicted }, -- 触发时机：受到伤害时
    can_trigger = function(self, event, target, player, data)
        -- 只有当玩家是目标时才能触发
        return target == player and player:hasSkill(self.name)
    end,
    on_cost = function(self, event, target, player, data)
        -- 询问玩家是否使用该技能
        local room = player.room
        local prompt = "#ki_omusubi-ask"
        return room:askForSkillInvoke(player, self.name, data, prompt)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        -- 防止本次伤害
        data.damage = 0
        -- 发动护盾后失去一点体力上限
        room:changeMaxHp(player, -1)
    end,
}

-- 将技能添加到神山识
Kamiyama_Shiki:addSkill(ki_bat)
Kamiyama_Shiki:addSkill(ki_omusubi)

-- 加载翻译表
Fk:loadTranslationTable {
    ["ki_bat"] = "御结",
    ["#ki_bat"] = "御结：你可以跑到海边偷鱼",
    [":ki_bat"] = "休闲时间限两次，到海边偷点鱼吧。",
    ["ki_omusubi"] = "饭团",
    ["#ki_omusubi-ask"] = "饭团：你可以交出饭团",
    [":ki_omusubi"] = "当你失去活力时，你可以防止之。吃掉饭团后失去一点体力上限。",
}
--本代码在雀魂包基础上学习(抄写)的
return extension