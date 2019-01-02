module("extensions.fate",package.seeall)

extension = sgs.Package("fate")
--暗降
-------------------------全局---------------------------------
Anjiang = sgs.General(extension,"anjiang","god",4,true,true,true)

-- --祭品效果
-- oblation = function(room,player,tp)
-- 	local obL = 0
-- 	if tp == 2 then
-- 		obL = 4
-- 	elseif tp == 3 then
-- 		obL = 6
-- 	elseif tp == 1 then
-- 		obL = 2
-- 	end
-- 	local count =0
-- 	while(count<obL and not player:isNude()) do
-- 		local id = room:askForCardChosen(player,player,"he","oblation")
-- 		local card = sgs.Sanguosha:getCard(id)
-- 		if card:isKindOf("EquipCard") then
-- 			count = count+2
-- 		else
-- 			count = count+1
-- 		end
-- 		room:throwCard(card,player)
-- 	end
-- end

--请先看lol拓展包
Rset = function(Rname,Rmark)
	lolR = sgs.CreateTriggerSkill{
		name = "#"..Rname,	
		frequeny = sgs.Skill_Frequent, 
		events = {sgs.GameStart},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			room:setPlayerMark(player,Rmark,1)
		end,	
	}
	return lolR
end

--返回获取宝具的技能卡
--(字符串)baoju 这个字符串必须是BaoJu列表中的一个元素，它对应着那张牌的id
getBaojuCard = function(baoju)
	zaigetcard = sgs.CreateSkillCard{
		name = "zai"..baoju.."Card",	
		target_fixed = true,	 
		will_throw = false,
		on_use = function(self,room,source,targets)		
			local card = sgs.Sanguosha:getCard(BaoJu[baoju])
			source:obtainCard(card,false)
		end,	
	}
	return zaigetcard
end

--函数返回获取宝具的视为技，需要配合上面的返回获得宝具技能卡使用
--(字符串)baoju 和上述一样的一样，
--(技能卡对象)baojucard 这个技能卡就是要视为的技能卡
getBaoju = function(baoju,baojucard)
	zaiGet = sgs.CreateZeroCardViewAsSkill{
		name = "zai"..baoju,
		view_as = function(self)
			local vs_card = baojucard:clone()
			vs_card:setSkillName(self:objectName())
			return vs_card
		end,
		enabled_at_play = function(self,player)
			return not player:hasUsed("#zai"..baoju.."Card")
		end,
	}
	return zaiGet
end

-------------------------全局---------------------------------

--宝具列表的生成
BaoName = {"Excalibur","GaeBolg","Enuma","Enkidu","Durandal","Dainslef","Gram","Caladbolg","Vajra","Harpe"}
BaoJu = {}
bao_count = 278
for _,i in ipairs(BaoName) do
	BaoJu[i] = bao_count
	bao_count = bao_count+1
end

Saber = sgs.General(extension,"Saber","wei",4,false)

zaiExcaliburCard = getBaojuCard("Excalibur")

zaiExcalibur = getBaoju("Excalibur",zaiExcaliburCard)

zaiAvalon = sgs.CreateTriggerSkill{
	name = "#zaiAvalon",
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Discard and move.from:objectName() == player:objectName()
			 and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
			 then
				player:gainMark("excalibur",move.card_ids:length())
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			if player:getMark("excalibur") >= math.max(player:getHp(),2) then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player,recover)
			end
		elseif event == sgs.EventPhaseChanging then
			player:setMark("excalibur",0)
		end
	end,
}

Saber:addSkill(zaiExcalibur)
Saber:addSkill(zaiAvalon)

Emiya = sgs.General(extension,"Emiya","shu",3)

Kuqiulin = sgs.General(extension,"Kuqiulin","wei",4)

zaiGaeBolgCard = sgs.CreateSkillCard{
	name = "zaiGaeBolgCard",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			if player:hasWeapon("GaeBolg") and player:getMark("KuqiulinR")>0 then
				return true
			elseif not player:hasWeapon("GaeBolg") or player:getMark("KuqiulinR")==0 then
				return to_select:objectName() == player:objectName()
			end
		end
	end,
	on_use = function(self,room,source,targets)	
		if targets[1]:objectName() == source:objectName() then	
			local card = sgs.Sanguosha:getCard(BaoJu["GaeBolg"])
			source:obtainCard(card,false)
		elseif targets[1]:objectName() ~= source:objectName() then
			if source:hasWeapon("GaeBolg") and source:getMark("KuqiulinR") > 0 then
				local card = source:getWeapon()
				room:throwCard(card,source)
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = targets[1]
				damage.damage = 1
				room:damage(damage)
				room:setPlayerMark(source,"KuqiulinR",0)
			end
		end
	end,
	on_effect = function(self,effect)
		
	end,	
}

zaiGaeBolg = sgs.CreateZeroCardViewAsSkill{
	name = "zaiGaeBolg",
	--relate_to_place = deputy,	
	--response_pattern = "",		
	view_as = function(self)
		local vs = zaiGaeBolgCard:clone() 
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zaiGaeBolgCard")
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}

zaiKuqiulinR = Rset("KuqiulinR","KuqiulinR")

Kuqiulin:addSkill(zaiGaeBolg)
Kuqiulin:addSkill(zaiKuqiulinR)

BoG = {"Enuma","Enkidu","Durandal","Dainslef","Gram","Caladbolg","Vajra","Harpe"}

Jier = sgs.General(extension,"Jier","god",3)

zaiBoGStart = sgs.CreateGameStartSkill{
	name = "#zaiBoGStart",
	frequeny = sgs.Skill_Compulsory,
	--view_as_skill = ,
	on_gamestart = function(self,player)
		local room = player:getRoom()
		for _,i in ipairs(BoG) do
			player:gainMark(i)
		end
	end,	
}

zaiBoGCard = sgs.CreateSkillCard{
	name = "zaiBoGCard",
	target_fixed = false,
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return to_select:objectName() ~= player:objectName()
		end
	end,
	on_use = function(self,room,source,targets)
		if self:getSubcards():isEmpty() then
			local card = nil
			while(true)
			do
				card = sgs.Sanguosha:getCard(BaoJu[BoG[math.random(1,8)]])
				if source:getMark(card:objectName()) > 0 then
					source:obtainCard(card,false)
					break
				end
			end
		elseif not self:getSubcards():isEmpty() then
			local id = self:getSubcards():first()
			local subcard = sgs.Sanguosha:getCard(id)
			local name = subcard:objectName()
			source:loseMark(name)
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = targets[1]
			damage.damage = 1
			room:damage(damage)
		end
	end,
	on_effect = function(self,effect)
		
	end,	
}

zaiBoG = sgs.CreateViewAsSkill{
	name = "zaiBoG",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 1,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return sgs.Self:getMark(to_select:objectName()) > 0 and to_select:objectName() ~= "Enuma"
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return zaiBoGCard:clone()
		elseif #cards == 1 then
			local card = zaiBoGCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zaiBoGCard")
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}

-- zaiBoG = sgs.CreateZeroCardViewAsSkill{
-- 	name = "zaiBoG",
-- 	--relate_to_place = deputy,	
-- 	--response_pattern = "",		
-- 	view_as = function(self)
-- 		return zaiBoGCard:clone()
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		return not player:hasUsed("#zaiBoGCard")
-- 	end,
-- 	enabled_at_response = function(self,player,pattern)
		
-- 	end,		
-- }

-- WangkuCard = function(baoju)
-- 	zaiWangkuCard = sgs.CreateSkillCard{
-- 		name = "zai"..baoju.."Card",
-- 		target_fixed = false,
-- 		will_throw = true,
-- 		filter = function(self,targets,to_select,player)
-- 			if #targets == 0 then
-- 				return to_select:objectName() ~= player:objectName()
-- 			end
-- 		end,
-- 		on_use = function(self,room,source,targets)		
-- 			local damage = sgs.DamageStruct()
-- 			damage.from = source
-- 			damage.to = targets[1]
-- 			damage.damage = 1
-- 			room:damage(damage)
-- 			source:loseMark(baoju)
-- 		end,
-- 	}
-- 	return zaiWangkuCard
-- end
-- --BoG = {"Enuma","Enkidu","Durandal","Dainslef","Gram","Caladbolg","Vajra","Harpe"}
-- zaiEnkiduCard = WangkuCard(BoG[2])
-- zaiDurandalCard = WangkuCard(BoG[3])
-- zaiDainslefCard = WangkuCard(BoG[4])
-- zaiGramCard = WangkuCard(BoG[5])
-- zaiCaladbolgCard = WangkuCard(BoG[6])
-- zaiVajraCard = WangkuCard(BoG[7])
-- zaiHarpeCard = WangkuCard(BoG[8])

-- zaiWangku = sgs.CreateViewAsSkill{
-- 	name = "zaiWangku",
-- 	--relate_to_place = deputy,	
-- 	--response_pattern = "",
-- 	n = 1,
-- 	view_filter = function(self,selected,to_select)
-- 		if #selected == 0 then
-- 			return sgs.Self:getMark(to_select:objectName()) > 0 and to_select:objectName() ~= "Enuma"
-- 		end
-- 	end,
-- 	view_as = function(self,cards)
-- 		if #cards == 0 then
-- 			return nil
-- 		end
-- 		if #cards == 1 then
-- 			local card = cards[1]
-- 			local to_copy = nil
-- 			if card:objectName() == BoG[2] then
-- 				to_copy = zaiEnkiduCard:clone()
-- 			elseif card:objectName() == BoG[3] then
-- 				to_copy = zaiDurandalCard:clone()
-- 			elseif card:objectName() == BoG[4] then
-- 				to_copy = zaiDainslefCard:clone()
-- 			elseif card:objectName() == BoG[5] then
-- 				to_copy = zaiGramCard:clone()
-- 			elseif card:objectName() == BoG[6] then
-- 				to_copy = zaiCaladbolgCard:clone()
-- 			elseif card:objectName() == BoG[7] then
-- 				to_copy = zaiVajraCard:clone()
-- 			elseif card:objectName() == BoG[8] then
-- 				to_copy = zaiHarpeCard:clone()
-- 			end
-- 			to_copy:addSubcard(card)
-- 			to_copy:setSkillName(self:objectName())
-- 			return to_copy
-- 		end
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		return not player:hasUsed("#zaiWangkuCard")
-- 	end,
-- }

Jier:addSkill(zaiBoG)
Jier:addSkill(zaiBoGStart)

-------------------------装备区------------------------------

local skill_list = sgs.SkillList()

excalibur = sgs.CreateWeapon{
	name = "excalibur",
	class_name = "excalibur",
	suit = sgs.Card_Club,
	number = 2,
	range = 2,
}

excalibur:setParent(extension)

Excalibur = sgs.CreateTriggerSkill{
	name = "excalibur",	
	events = {sgs.Damage},
	--view_as_skill = ,
	can_trigger = function(self,player)
		return player and player:hasWeapon(self:objectName())
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:objectName() == player:objectName() then
			player:drawCards(1)
		end
	end
}

skill_list:append(Excalibur)

-- cangjingkong = sgs.Sanguosha:cloneCard("DefensiveHorse",sgs.Card_Heart,2)
-- cangjingkong:setObjectName("cangjingkong")
-- cangjingkong:setParent(extension)

GaeBolg = sgs.CreateWeapon{
	name = "GaeBolg",
	class_name = "GaeBolg",
	suit = sgs.Card_Club,
	number = 9,
	range = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("GaeBolg")
		if skill then
			if skill:inherits("ViewAsSkill") then
				room:attachSkillToPlayer(player, self:objectName())
			elseif skill:inherits("TriggerSkill") then
				local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
				room:getThread():addTriggerSkill(triggerskill)
			end
		end
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then
			room:detachSkillFromPlayer(player, self:objectName(), true)
		end
	end,
}
GaeBolg:setParent(extension)

GaeBolgSkill = sgs.CreateTriggerSkill{
	name = "GaeBolg",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.SlashProceed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		room:slashResult(effect,nil)
		return true
	end,
	can_trigger = function(self,target)
		return target and target:hasWeapon(self:objectName())
	end	
}
skill_list:append(GaeBolgSkill)

--乖离剑 弃置一张牌，令其他角色流失1点体力
Enuma = sgs.CreateWeapon{
	name = "Enuma",
	class_name = "Enuma",
	suit = sgs.Card_Heart,
	number = 2,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,self:objectName())
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,self:objectName())--仅针对视为技
	end,
}
Enuma:setParent(extension)

EnumaSkillCard = sgs.CreateSkillCard{
	name = "EnumaSkillCard",	
	target_fixed = true,	 
	will_throw = true,
	on_use = function(self,room,source,targets)		
		local players = room:getOtherPlayers(source)
		for _,player in sgs.qlist(players) do
			room:loseHp(player)
		end
	end,	
}

EnumaSkill = sgs.CreateOneCardViewAsSkill{
	name = "Enuma",
	filter_pattern = "Slash|.",
	view_as = function(self,card)
		local to_copy = EnumaSkillCard:clone()
		to_copy:addSubcard(card)
		to_copy:setSkillName(self:objectName())
		return to_copy
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#EnumaSkillCard") and player:objectName() == Jier:objectName()
	end,		
}

skill_list:append(EnumaSkill)
--天之锁 指定一名角色，其被沉默并且下回合不得出杀
Enkidu = sgs.CreateWeapon{
	name = "Enkidu",
	class_name = "Enkidu",
	suit = sgs.Card_Heart,
	number = 12,
	range = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,"Enkidu")
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"Enkidu")--仅针对视为技
	end,
}
Enkidu:setParent(extension)

EnkiduSkillCard = sgs.CreateSkillCard{
	name = "EnkiduSkillCard",	
	target_fixed = false,	 
	will_throw = false,
	filter = function(self,targets,to_select,player)
		if #targets==0 then
			return to_select:getHp()>player:getHp()
		end
	end,
	on_use = function(self,room,source,targets)		
		room:setPlayerCardLimitation(targets[1],"use,response","Slash|.|.|.",true)
	end,
}

EnkiduSkill = sgs.CreateZeroCardViewAsSkill{
	name = "Enkidu",		
	view_as = function(self)
		return EnkiduSkillCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#EnkiduSkillCard")
	end,	
}

skill_list:append(EnkiduSkill)
--维摩那 座驾
-- Vimana = sgs.CreateTreasure{
-- 	name = "Vimana",
-- 	class_name = "Vimana",
-- 	suit = sgs.Card_Club,
-- 	number = 8,
-- 	on_install = function(self,player)
-- 		local room = player:getRoom()
-- 		local triggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
-- 		room:getThread():addTriggerSkill(triggerskill)
-- 	end,
-- }

-- VimanaSkill = sgs.CreateTriggerSkill{
-- 	name = "Vimana",	
-- 	frequeny = sgs.Skill_Compulsory, 
-- 	events = {sgs.EventPhaseEnd},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		if player:getPhase() == sgs.Player_Finish then
-- 			local hand = player:getHandcardNum()
-- 			if hand<4 then
-- 				if player:askForSkillInvoke(self:objectName(),data) then
-- 					player:drawCards(4-hand)
-- 				end
-- 			end
-- 		end
-- 	end,	
-- 	can_trigger = function(self,target)
-- 		return target and target:hasWeapon(self:objectName())
-- 	end
-- }

-- skill_list:append(VimanaSkill)
--迪朗达尔 辉煌如石中剑 跟excalibur类似
Durandal = sgs.CreateWeapon{
	name = "Durandal",
	class_name = "Durandal",
	suit = sgs.Card_Spade,
	number = 1,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Durandal")
		room:getThread():addTriggerSkill(skill)
	end,
}
Durandal:setParent(extension)

DurandalSkill = sgs.CreateTriggerSkill{
	name = "Durandal",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.Damage},
	can_trigger = function(self,player)
		return player and player:hasWeapon(self:objectName())
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:objectName() == player:objectName() then
			player:drawCards(1)
		end
	end
}

skill_list:append(DurandalSkill)
--达瑟汀 招致破灭的强力诅咒
Dainslef = sgs.CreateWeapon{
	name = "Dainslef",
	class_name = "Dainslef",
	suit = sgs.Card_Diamond,
	number = 5,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,self:objectName())
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"Dainslef")--仅针对视为技
	end,
}
Dainslef:setParent(extension)

DainslefSkillCard = sgs.CreateSkillCard{
	name = "DainslefSkillCard",	
	target_fixed = true,	 
	will_throw = false,
	on_use = function(self,room,source,targets)		
		room:loseHp(source)
		source:drawCards(2)
	end,
}	

DainslefSkill = sgs.CreateZeroCardViewAsSkill{
	name = "Dainslef",			
	view_as = function(self)
		return DainslefSkillCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#DainslefSkillCard")
	end,	
}
skill_list:append(DainslefSkill)
--破灭的黎明 屠龙剑
Gram = sgs.CreateWeapon{
	name = "Gram",
	class_name = "Gram",
	suit = sgs.Card_Diamond,
	number = 7,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Gram")
		room:getThread():addTriggerSkill(skill)
	end,
}
Gram:setParent(extension)

GramSkill = sgs.CreateTriggerSkill{
	name = "Gram",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from 
			 and use.from:objectName() == player:objectName() then
			 	for _,target in sgs.qlist(use.to) do
			 		if not target:isKongcheng() then
			 			if player:askForSkillInvoke(self:objectName(),data) then
							room:askForDiscard(target,self:objectName(),1,1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:getHp() == 1 then
					local recover = sgs.RecoverStruct()
					recover.who = player
					room:recover(player,recover)
					local card = player:getWeapon()
					room:throwCard(card,player)
				end
			end
		end					
	end,	
	can_trigger = function(self,target)
		return target and target:hasWeapon(self:objectName())
	end
}

skill_list:append(GramSkill)
--螺旋剑
Caladbolg = sgs.CreateWeapon{
	name = "Caladbolg",
	class_name = "Caladbolg",
	suit = sgs.Card_Club,
	number = 9,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Caladbolg")
		room:getThread():addTriggerSkill(skill)
	end,
}
Caladbolg:setParent(extension)	

CaladbolgSkill = sgs.CreateTriggerSkill{
	name = "Caladbolg",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.by_user and 
		 not damage.chain and not damage.transfer then
		 	if damage.to:getAttackRange() >= 3 then
		 		damage.damage = damage.damage + 1
		 		data:setValue(damage)
		 	end
		end
	end,	
	can_trigger = function(self,target)
		return target and target:hasWeapon(self:objectName())
	end
}

skill_list:append(CaladbolgSkill)
--因陀罗之雷
Vajra = sgs.CreateWeapon{
	name = "Vajra",
	class_name = "Vajra",
	suit = sgs.Card_Club,
	number = 11,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,self:objectName())
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"Vajra")--仅针对视为技
	end,
}
Vajra:setParent(extension)

VajraSkill = sgs.CreateOneCardViewAsSkill{
	name = "Vajra",
	filter_pattern = "Slash|.",
	view_as = function(self,card)
		local suit = card:getSuit()
		local num = card:getNumber()
		local to_copy = sgs.Sanguosha:cloneCard("ThunderSlash",suit,num)
		to_copy:addSubcard(card)
		to_copy:setSkillName(self:objectName())
		return to_copy
	end,
	enabled_at_play = function(self,player)
		return true
	end,		
}

skill_list:append(VajraSkill)
--屠戮不死之刃 此剑所伤，不可复原
Harpe = sgs.CreateWeapon{
	name = "Harpe",
	class_name = "Harpe",
	suit = sgs.Card_Heart,
	number = 4,
	range = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("Harpe")
		room:getThread():addTriggerSkill(skill)
	end,
}
Harpe:setParent(extension)

HarpeSkill = sgs.CreateTriggerSkill{
	name = "Harpe",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.by_user 
		 and (not damage.chain) and (not damage.transfer) then
			if player:askForSkillInvoke(self:objectName(), data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:loseMaxHp(damage.to)
					return true
				end
			end
		end
	end,	
	can_trigger = function(self,target)
		return target and target:hasWeapon(self:objectName())
	end
}

skill_list:append(HarpeSkill)

-------------------------技能添加区-------------------------------------
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
	["fate"] = "Fate包",

	["excalibur"] = "胜利与誓约之剑",
	[":excalibur"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你造成伤害时，摸一张牌。",

	["Saber"] = "阿尔托莉雅",
	["&Saber"] = "阿尔托莉雅",
	["#Saber"] = "亚瑟王",
	["designer:Saber"] = "Wargon",
	["cv:Saber"] = "Miss Baidu",
	["illustrator:Saber"] = "Riot",
	["zaiExcalibur"] = "王者之剑",
	[":zaiExcalibur"] = "出牌阶段，你可以将【Excalibur】获得至手中，每回合限一次。弃牌阶段，若你弃置了等同于体力值数的手牌（至少两张），你回复一点体力",
	
	["GaeBolg"] = "贯穿死棘之枪",
	[":GaeBolg"] = "装备牌·武器<br />攻击范围：3<br />武器特效：你的【杀】不可闪避",

	["Kuqiulin"] = "库丘林",
	["&Kuqiulin"] = "库丘林",
	["#Kuqiulin"] = "光之子",
	["designer:Kuqiulin"] = "Wargon",
	["cv:Kuqiulin"] = "Miss Baidu",
	["illustrator:Kuqiulin"] = "Riot",
	["zaiGaeBolg"] = "伽耶伯格",
	[":zaiGaeBolg"] = "出牌阶段，你可以将【Excalibur】获得至手中，每回合限一次。限定技，出牌阶段，若你装备了【GaeBolg】，你可以弃掉【GaeBolg】，对一名其他角色造成1点伤害",

	["Enuma"] = "乖离剑",
	[":Enuma"] = "装备牌·武器<br />攻击范围：2<br />武器特效：出牌阶段，你可弃置一张【杀】，令所有其他角色失去1点体力，每回合限一次(这把剑只有英雄王才能驾驭)",

	["Enkidu"] = "天之锁",
	[":Enkidu"] = "装备牌·武器<br />攻击范围：5<br />武器特效：出牌阶段，你可指定一名体力值大于你的角色，令其下回合不得使用【杀】，每回合限一次",

	["Vimana"] = "维摩那",
	[":Vimana"] = "",

	["Durandal"] = "迪朗达尔",
	[":Durandal"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你造成伤害时，摸一张牌。",

	["Dainslef"] = "达瑟汀",
	[":Dainslef"] = "装备牌·武器<br />攻击范围：2<br />武器特效：出牌阶段，你可自减1点体力，然后摸两张牌,每回合限一次",

	["Gram"] = "破灭的黎明",
	[":Gram"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你使用【杀】指定一名角色时，可令其弃置一张手牌；回合开始时，若你的体力值为1，你弃置这张牌，然后回复1点体力",

	["Caladbolg"] = "螺旋剑",
	[":Caladbolg"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你的【杀】对攻击距离不小于3的角色造成的伤害+1",

	["Vajra"] = "因陀罗之雷",
	[":Vajra"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你可将一张【杀】当【雷杀】使用",
	
	["Harpe"] = "屠戮不死之刃",
	[":Harpe"] = "装备牌·武器<br />攻击范围：2<br />武器特效：你的【杀】对一名角色造成伤害时，你可进行1次判定，若为黑色，你防止此伤害，令其失去1点体力上限",

	["Jier"] = "吉尔伽美什",
	["&Jier"] = "吉尔伽美什",
	["#Jier"] = "英雄王",
	["designer:Jier"] = "Wargon",
	["cv:Jier"] = "Miss Baidu",
	["illustrator:Jier"] = "Riot",
	["zaiBoG"] = "王之宝库",
	[":zaiBoG"] = "出牌阶段，你可随机将一张属于王之宝库的牌获得至手牌中。你可弃置一张属于王之宝库的牌（乖离剑除外），对一名角色造成一点伤害，此牌以后不再属于王之宝库。每回合限一次",
}
