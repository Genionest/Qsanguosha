module("extensions.lolEquip",package.seeall)

extension = sgs.Package("lolEquip")

local skill_list = sgs.SkillList()

Landun = sgs.CreateArmor{
	name = "Landun",
	class_name = "Landun",
	suit = sgs.Card_Club,
	number = 7,	
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Landun")
		room:getThread():addTriggerSkill(skill)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player,recover)
	end,
}
Landun:setParent(extension)

landun = sgs.CreateTriggerSkill{
	name = "Landun",
	frequeny = sgs.skill_Frequent,
	events = {sgs.DamageCaused},
	-- view_as_skill = 
	on_trigger = function(self,event,player,data)
		local damage = data:toDamage()
		if damage.to and damage.to:hasArmorEffect("Landun") and damage.damage > 1 then
			return true
		end
	end,
	can_trigger = function(self,target)
		return true
	end
}

skill_list:append(landun)

Kuangtu = sgs.CreateArmor{
	name = "Kuangtu",
	class_name = "Kuangtu",
	suit = sgs.Card_Heart,
	number = 13,	
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Kuangtu")
		room:getThread():addTriggerSkill(skill)
	end,
}
Kuangtu:setParent(extension)

kuangtu = sgs.CreateTriggerSkill{
	name = "Kuangtu",	
	frequeny = sgs.skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.Damage, sgs.Damaged},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhaseString() == "start" then
				player:gainMark("kuangtu")
				if player:getMark("kuangtu") >= 2 then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player,recover)
					player:loseAllMark("kuangtu")
				end
			end
		elseif event == sgs.Damage or event == sgs.Damaged then
			player:loseAllMarks("kuangtu")
		end
	end,	
	can_trigger = function(self,target)
		return target and target:hasArmorEffect("Kuangtu")
	end
}

skill_list:append(kuangtu)

---------------------------------------------------------

if sgs.Sanguosha then -- 装备那里要能够添加技能，就必须现在引擎把技能加上
	for _,skill in sgs.qlist(skill_list) do
		if not sgs.Sanguosha:getSkill(skill:objectName()) then
			sgs.Sanguosha:addSkills(skill_list)		
			break
		end
	end
end

sgs.LoadTranslationTable{
	["lolEquip"] = "英雄联盟装备包",

	["Landun"] = "兰顿之兆",
	[":Landun"] = "装备牌·防具<br />其他角色无法对你造成大于1点的伤害;你失去此装备时，回复1点体力",

	["Kuangtu"] = "狂徒铠甲",
	[":Kuangtu"] = "装备牌·防具<br />每过两个回合，你回复一点体力。你造成或受到伤害都会重新计算回合数",
}