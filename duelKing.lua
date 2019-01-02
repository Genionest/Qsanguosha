module("extensions.duelKing",package.seeall)

extension = sgs.Package("duelKing")
--暗降
-------------------------全局---------------------------------
Anjiang = sgs.General(extension,"anjiang","god",4,true,true,true)

--祭品效果，tp为祭品组数，一组祭品就是两张牌或一张装备牌，需要几组祭品就弃置几回
--(Room对象)room player:getRoom()的那个
--(ServerPlayer对象)player 就是平实的那个player
--(数字)tp 需要弃置的祭品组数
oblation = function(room,player,tp)
	local obL = 0
	if tp == 2 then
		obL = 4
	elseif tp == 3 then
		obL = 6
	elseif tp == 1 then
		obL = 2
	end
	local count =0
	while(count<obL and not player:isNude()) do
		local id = room:askForCardChosen(player,player,"he","oblation")
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("EquipCard") then
			count = count+2
		else
			count = count+1
		end
		room:throwCard(card,player)
	end
end

---------------------------------人物区--------------------------------

WangYang = sgs.General(extension,"WangYang$","shu",3)

lolShenChouCard = sgs.CreateSkillCard{
	name = "lolShenChouCard",
	target_fixed = true, 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
	
	end,
	on_use = function(self,room,source,targets)
		local choices = "basic+equip+trick"
		local chice = ""
		local choice = room:askForChoice(source,self:objectName(),choices)
		if choice == "basic" then
			chice = "BasicCard"
		elseif choice == "equip" then
			chice = "EquipCard"
		elseif choice == "trick" then
			chice = "TrickCard"
		end
		local ok = false
		while(not ok)
		do
			local ids = room:getNCards(1,true)
			local id = ids:first()
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf(chice) then
				room:obtainCard(source,c)
				break
			end
		end
		if source:getMark("drawGodlike")>0 then
			source:loseMark("drawGodlike")
		end
	end,

}

lolShenChou = sgs.CreateViewAsSkill{
	name = "lolShenChou",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolShenChouCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("drawGodlike")>0 or not player:hasUsed("#lolShenChouCard")
	end,		
}

lolFalao = sgs.CreateTriggerSkill{
	name = "lolFalao$",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		if player:getPhase() == sgs.Player_Start then
			if player:isLord() then
				local room = player:getRoom()
				local players = room:getAlivePlayers()
				local count = 0
				for _,p in sgs.qlist(players) do
					if p:getKingdom() == "shu" then
						count = count + 1
					end
				end
				room:setPlayerMark(player,"drawGodlike",count)
			end
		end
	end,
}

WangYang:addSkill(lolShenChou)
WangYang:addSkill(lolFalao)

---------------------------------装备区-----------------------------
local skill_list = sgs.SkillList()

BlueEyesDragon = sgs.CreateWeapon{
	name = "BlueEyesDragon",
	class_name = "BlueEyesDragon",
	suit = sgs.Card_Spade,
	number = 13,
	range = 3,
	on_install = function(self, player) --装备时获得技能,摸2张牌
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill("BlueEyesDragon")
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			elseif skill:inherits("TriggerSkill") then
				local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
				room:getThread():addTriggerSkill(triggerskill)
			end
		end
		oblation(room,player,1)
		if player:getMark("BlueEyesDragon")<3 then
			player:gainMark("BlueEyesDragon")
		end
	end,
	on_uninstall = function(self, player) --卸下时移除技能
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then
			room:detachSkillFromPlayer(player, self:objectName(), true)
		end
	end,
}
BlueEyesDragon:setParent(extension)

BlueEyesDragonSkill = sgs.CreateTriggerSkill{
	name = "BlueEyesDragon",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed,sgs.DamageCaused,sgs.DrawNCards},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed and player:getMark("BlueEyesDragon")>0 then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() then
				if use.card and use.card:isKindOf("Slash") then
					player:drawCards(1)
				end
			end
		elseif event == sgs.DamageCaused and player:getMark("BlueEyesDragon")>1 then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not
			 damage.chain and not damage.transfer then
				damage.from:drawCards(1)
			end
		elseif event == sgs.DrawNCards and player:getMark("BlueEyesDragon")>2 then
			local count = data:toInt()+2
			data:setValue(count)
		end
	end,	
	can_trigger = function(self,target)
		return target and target:hasWeapon("BlueEyesDragon")
	end
}	

skill_list:append(BlueEyesDragonSkill)

skyDragon = sgs.CreateWeapon{
	name = "skyDragon",
	class_name = "skyDragon",
	suit = sgs.Card_Heart,
	number = 5,
	range = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			elseif skill:inherits("TriggerSkill") then
				local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
				room:getThread():addTriggerSkill(triggerskill)
			end
		end
		oblation(room,player,3)
		player:drawCards(3)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then
			room:detachSkillFromPlayer(player, self:objectName(), true)
		end
	end,
}
skyDragon:setParent(extension)

goodtrick = {"ExNihilo","GodSalvation","AmazingGrace"}

skyDragonSkill = sgs.CreateTriggerSkill{
	name = "skyDragon",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused,sgs.TargetConfirmed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not
			 damage.chain and not damage.transfer and damage.from:hasWeapon(self:objectName()) then
			 	if not damage.to:hasWeapon("Tormentor") and not damage.to:hasWeapon("RaWinged") then
					local count = damage.from:getCards("h"):length()
					damage.damage = count
					data:setValue(damage)
				end
			end
			if damage.card and damage.card:isKindOf("TrickCard") 
			 and damage.to:hasWeapon(self:objectName()) then
			 	return true
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isBlack() and card:isKindOf("TrickCard") then
				for _,target in sgs.qlist(use.to) do
					if target:hasWeapon(self:objectName()) then
						local nullified = use.nullified_list
						table.insert(nullified,target:objectName())
						use.nullified_list = nullified
						data:setValue(use)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

skill_list:append(skyDragonSkill)

Tormentor = sgs.CreateWeapon{
	name = "Tormentor",
	class_name = "Tormentor",
	suit = sgs.Card_Club,
	number = 9,
	range = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Tormentor")
		room:getThread():addTriggerSkill(skill)
		oblation(room,player,3)
		player:drawCards(2)
	end,
}
Tormentor:setParent(extension)

TormentorSkill = sgs.CreateTriggerSkill{
	name = "Tormentor",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart,sgs.TargetConfirmed,sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:hasWeapon(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(),data) then
					if not player:isSkipped(sgs.Player_Judge) then
						player:skip(sgs.Player_Judge)
					end
					if not player:isSkipped(sgs.Player_Draw) then
						player:skip(sgs.Player_Draw)
					end
					if not player:isSkipped(sgs.Player_Play) then
						player:skip(sgs.Player_Play)
					end
					local players = room:getOtherPlayers(player)
					for _,p in sgs.qlist(players) do
						if not p:hasWeapon("skyDragon") and not p:hasWeapon("RaWinged") then
							room:loseHp(p)
							p:throwAllEquips()
						end
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isBlack() and card:isKindOf("TrickCard") then
				for _,target in sgs.qlist(use.to) do
					if target:hasWeapon(self:objectName()) then
						local nullified = use.nullified_list
						table.insert(nullified,target:objectName())
						use.nullified_list = nullified
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			if damage.card and damage.card:isKindOf("TrickCard") 
			 and damage.to:hasWeapon(self:objectName()) then
			 	return true
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

skill_list:append(TormentorSkill)

RaWinged = sgs.CreateWeapon{
	name = "RaWinged",
	class_name = "RaWinged",
	suit = sgs.Card_Diamond,
	number = 1,
	range = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("RaWinged")
		room:getThread():addTriggerSkill(skill)
		oblation(room,player,3)
	end,
}
RaWinged:setParent(extension)

RaWingedSkill = sgs.CreateTriggerSkill{
	name = "RaWinged",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart,sgs.TargetConfirmed,sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasWeapon(self:objectName()) then
				if player:askForSkillInvoke(self:objectName(),data) then
					local hp = player:getHp()
					room:loseHp(player,hp-1)
					if hp-1 >= 1 then
						local players = room:getOtherPlayers(player)
						local target = room:askForPlayerChosen(player,players,self:objectName())
						room:loseHp(target,target:getHp()-1)
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = target
						damage.damage = 1
						damage.nature =  sgs.DamageStruct_Fire
						room:damage(damage)
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			if card:isBlack() and card:isKindOf("TrickCard") then
				for _,target in sgs.qlist(use.to) do
					if target:hasWeapon(self:objectName()) then
						local nullified = use.nullified_list
						table.insert(nullified,target:objectName())
						use.nullified_list = nullified
						data:setValue(use)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			if damage.card and damage.card:isKindOf("TrickCard") 
			 and damage.to:hasWeapon(self:objectName()) then
			 	return true
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

skill_list:append(RaWingedSkill)

---------------------------添加技能-----------------------------
local add = false

if sgs.Sanguosha then -- 装备那里要能够添加技能，就必须现在引擎把技能加上
	for _,skill in sgs.qlist(skill_list) do
		if not sgs.Sanguosha:getSkill(skill:objectName()) then
			add = true
			break
		end
	end
	if add then
		sgs.Sanguosha:addSkills(skill_list)
	end
end

sgs.LoadTranslationTable{
	["duelKing"] = "游戏王包",

	["BlueEyesDragon"] = "青眼的白龙",
	[":BlueEyesDragon"] = "装备牌·武器<br />攻击范围：3<br />祭品：弃置1张装备牌或两张手牌。<br />武器特效：若你至少装备过1次此牌，你使用【杀】时摸1张牌；若你至少装备过2次此牌，你的【杀】造成伤害时摸1张牌；若你至少装备过3次此牌，摸牌阶段你多摸2张牌。",

	["skyDragon"] = "欧西里斯的天空龙",
	[":skyDragon"] = "装备牌·武器<br />攻击范围：5<br />祭品：弃置1张装备牌或两张手牌，弃置3组；祭献完成后，立即摸3张牌。<br />武器特效：你的【杀】对于没有神之卡的角色造成的伤害等于你当前的手牌数。<br>神之躯：黑色锦囊对你无效且你免疫锦囊伤害。",

	["Tormentor"] = "欧贝里斯克的巨神兵",
	[":Tormentor"] = "装备牌·武器<br />攻击范围：5<br />祭品：弃置1张装备牌或两张手牌，弃置3组；祭献完成后，立即摸2张牌。<br />武器特效：回合开始时，你可直跳过判定，摸牌，出牌阶段，令其他没有神之卡的角色失去1点体力并弃置所有装备区的牌。<br>神之躯：黑色锦囊对你无效且你免疫锦囊伤害。",

	["RaWinged"] = "太阳神的翼神龙",
	[":RaWinged"] = "装备牌·武器<br />攻击范围：5<br />祭品：弃置1张装备牌或两张手牌，弃置3组。<br />武器特效：出牌阶段开始时，你可失去体力至1点，若你至少失去了1点体力，你可令一名角色失去体力至1点，然后受到1点火焰伤害。<br>神之躯：黑色锦囊对你无效且你免疫锦囊伤害。",

	["WangYang"] = "王样",
	["&WangYang"] = "王样",
	["#WangYang"] = "无名的法老王",
	["designer:WangYang"] = "Wargon",
	["cv:WangYang"] = "Miss Baidu",
	["illustrator:WangYang"] = "Riot",
	["lolShenChou"] = "神抽",
	[":lolShenChou"] = "出牌阶段，你可选择一种类别的牌，然后从牌堆中获得一张此类别的牌，每回合限一次",
	["lolFalao"] = "法老",
	[":lolFalao"] = "主公技，场上每存在一名其他的蜀势力角色，你于回合内发动“神抽”的上限便+1",
}
