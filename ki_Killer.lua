-- 定义扩展包
local extension = Package("ki_Killer")
extension.extensionName = "sakisakura"

-- 定义武将夜神月
local ki_killer = General(extension, "ki_killer", "qun", 4)

-- 定义夜神月的一技能
local ki_killer_skill1 = fk.CreateTriggerSkill {
  name = "ki_killer_skill1",
  anim_type = "control",
  frequency = Skill.Frequent,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:getMark("@ki_killer_target") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local alive_players = room:getAlivePlayers()
    local choices = table.map(alive_players, function(p) return p.id end)
    local choice = room:askForChoosePlayers(player, choices, 1, 1, "#ki_killer_skill1-choose", self.name, true)
    if #choice > 0 then
      self.cost_data = choice[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target_id = self.cost_data
    local target_player = room:getPlayerById(target_id)
    if target_player then
      room:setPlayerMark(player, "@ki_killer_target", target_id)
      player:chat(string.format("我记住了玩家 %s", target_player.name))
      room:sendLog{ type = "$SkillInvoke", from = player.id, skill = self.name, args = { "记住了 " .. target_player.name } }
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:getMark("@ki_killer_target") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local target_id = player:getMark("@ki_killer_target")
    local target_player = room:getPlayerById(target_id)
    if target_player and not target_player.dead then
      local choices = {"kill", "remove"}
      local choice = room:askForChoice(player, choices, self.name, "#ki_killer_skill1-refresh", true)
      if choice == "kill" then
        room:killPlayer({ who = target_id, from = player.id, skillName = self.name })
        player:chat(string.format("我让玩家 %s 死亡了", target_player.name))
        room:sendLog{ type = "$SkillInvoke", from = player.id, skill = self.name, args = { "让 " .. target_player.name .. " 死亡" } }
      elseif choice == "remove" then
        player.room:removePlayer(target_id, true)
        player:chat(string.format("我让玩家 %s 移出了游戏", target_player.name))
        room:sendLog{ type = "$SkillInvoke", from = player.id, skill = self.name, args = { "让 " .. target_player.name .. " 移出游戏" } }
      end
    else
      player:chat("记录的目标玩家已经死亡或移出游戏")
      room:sendLog{ type = "$SkillInvoke", from = player.id, skill = self.name, args = { "记录的目标玩家已经死亡或移出游戏" } }
    end
    room:setPlayerMark(player, "@ki_killer_target", 0)
  end,
}

-- 将技能添加到武将
ki_killer:addSkill(ki_killer_skill1)

-- 翻译表
Fk:loadTranslationTable {
  ["ki_killer"] = "夜神月",
  ["#ki_killer"] = "记得夜神月的小秘密",

  ["ki_killer_skill1"] = "记忆",
  [":ki_killer_skill1"] = "在回合开始时，你可以记住一名玩家；在第二轮回合结束时，你可以选择让该玩家死亡或移出游戏。",
  ["#ki_killer_skill1-choose"] = "记忆：请选择你想要记住的玩家",
  ["#ki_killer_skill1-refresh"] = "记忆：请选择你想对 %dest 执行的操作",
  ["$ki_killer_skill1-used"] = "夜神月记住了玩家 %dest",
  ["$ki_killer_skill1-killed"] = "夜神月让玩家 %dest 死亡了",
  ["$ki_killer_skill1-removed"] = "夜神月让玩家 %dest 移出了游戏",
  ["$ki_killer_skill1-target-gone"] = "记录的目标玩家已经死亡或移出游戏",
  ["~ki_killer"] = "记忆夜神月，你的目的已经达成。",
}

-- 返回扩展包
return extension