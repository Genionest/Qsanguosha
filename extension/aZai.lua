module("extensions.aZai",package.seeall)

extension = sgs.Package("aZai")
--暗降
-------------------------全局---------------------------------
Anjiang = sgs.General(extension,"anjiang","god",4,true,true,true)

-------------------------全局---------------------------------

Shiren = sgs.General(extension,"Shiren","qun",3)

lolYinyouCard = sgs.CreateSkillCard{
	name = "lolYinyouCard",
	target_fixed = true,
	will_throw = true,
	filter = function(self,targets,to_select)
		return true
	end,
	on_use = function(self,room,source,targets)
		local suit = room:askForSuit(source,self:objectName())
		local suit_str = sgs.Card_Suit2String(suit)
		local judge = sgs.JudgeStruct() --创建判定结构体实例
		judge.who = source --设置属性
		judge.pattern = ".|"..suit_str --.表示没限制；后面条件没有可省略）
		judge.good = true --符合判定条件是否有利
		judge.reason = self:objectName()
		room:judge(judge)
		if judge:isGood() then --如果判定结果有利
			source:drawCards(1)
		elseif judge:isBad() then
		end
		room:setPlayerFlag(source,"lolYinyou")
	end,
}

lolYinyou = sgs.CreateViewAsSkill{
	name = "lolYinyou", --必须
	n = 0, --必须
	view_as = function(self, cards) --必须
		local vs_card = lolYinyouCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasFlag("lolYinyou")
	end, 
}

lolYinyou1 = sgs.CreateTriggerSkill{
	name = "#lolYinyou1",	
	frequeny = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local judge = data:toJudge()
		if judge.reason ~= "lolYinyouCard" then
			return false
		end
		if judge.who ~= player then
			return false
		end
		local card = judge.card
		if card:isRed() then
			player:drawCards(1)
		end
	end,	
}

lolPiaoboCard = sgs.CreateSkillCard{
	name = "lolPiaoboCard",	
	target_fixed = false,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return not to_select:hasFlag(self:objectName()) and to_select:objectName() ~= player:objectName()
		end
	end,
	on_use = function(self,room,source,targets)		
		local target = targets[1]
		room:setPlayerFlag(target,self:objectName())
		local choices = "accept+refuse"
		local choice = room:askForChoice(target,self:objectName(),choices)
		if choice == "refuse" then
			return false
		end
		if choice == "accept" then
			local id = room:askForCardChosen(target,target,"h",self:objectName())
			room:obtainCard(source,id)
			if source:hasFlag("lolYinyou") then
				room:setPlayerFlag(source,"-lolYinyou")
			end
			room:setPlayerFlag(source,self:objectName())
		end
	end,
}

lolPiaobo = sgs.CreateViewAsSkill{
	name = "lolPiaobo",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolPiaoboCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasFlag("lolPiaoboCard")
	end,		
}

Shiren:addSkill(lolYinyou)
Shiren:addSkill(lolYinyou1)
Shiren:addSkill(lolPiaobo)

ChengShuling = sgs.General(extension,"ChengShuling","qun",3)



lolTianlai = sgs.CreateTriggerSkill{
	name = "lolTianlai",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:isSkipped(sgs.Player_Play) then
			return false
		end
		if player:getPhase() == sgs.Player_Draw then
			if player:askForSkillInvoke(self:objectName(),data) then
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if player:inMyAttackRange(p) then
						if p:isAlive() then
							room:loseHp(p,1)
						end
					end
				end
				player:skip(sgs.Player_Play)
			end
		end
		
	end,
}

lolMianJingCard = sgs.CreateSkillCard{
	name = "lolMianJingCard",	
	target_fixed = false,	 
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return to_select:isWounded()
		end
	end,
	on_use = function(self,room,source,targets)		
		local target = targets[1]
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(target,recover,true)
	end,	
}	

lolMianJing = sgs.CreateOneCardViewAsSkill{
	name = "lolMianJing",
	--relate_to_place = deputy,	
	--response_pattern = "",	
	filter_pattern = "EquipCard",
	view_as = function(self,card)
		local to_copy = lolMianJingCard:clone()
		to_copy:addSubcard(card)
		to_copy:setSkillName(self:objectName())
		return to_copy
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolMianJingCard")
	end,		
}

ChengShuling:addSkill(lolTianlai)
ChengShuling:addSkill(lolMianJing)



-------------------------全局---------------------------------

cangjingkong = sgs.Sanguosha:cloneCard("DefensiveHorse",sgs.Card_Heart,2)
cangjingkong:setObjectName("cangjingkong")
cangjingkong:setParent(extension)

boduoye = sgs.Sanguosha:cloneCard("OffensiveHorse",sgs.Card_Heart,2)
boduoye:setObjectName("boduoye")
boduoye:setParent(extension)

maliya = sgs.Sanguosha:cloneCard("DefensiveHorse",sgs.Card_Spade,13)
maliya:setObjectName("maliya")
maliya:setParent(extension)

taogu = sgs.Sanguosha:cloneCard("OffensiveHorse",sgs.Card_Diamond,13)
taogu:setObjectName("taogu")
taogu:setParent(extension)



sgs.LoadTranslationTable{
	["aZai"] = "阿宅包",

	["Shiren"] = "简拉基茨德",
	["&Shiren"] = "简拉基茨德",
	["#Shiren"] = "吟游诗人",
	["designer:Shiren"] = "Wargon",
	["cv:Shiren"] = "Miss Baidu",
	["illustrator:Shiren"] = "Riot",
	["lolYinyou"] = "吟游",
	[":lolYinyou"] = "出牌阶段，你可选择一种花色，然后进行一次判定，若花色相同，你获得摸一张牌；如果判定结果为红色，你可摸一张牌。每回合限一次。",
	["lolPiaobo"] = "漂泊",
	[":lolPiaobo"] = "出牌阶段，你可指定一名角色，令其选择是否交给你一张手牌，若如此做，你可发动一次”吟游“。每回合限生效一次，每回合每名角色限一次。",

	["ChengShuling"] = "程书林",
	["&ChengShuling"] = "程书林",
	["#ChengShuling"] = "面筋哥",
	["designer:ChengShuling"] = "Wargon",
	["cv:ChengShuling"] = "Miss Baidu",
	["illustrator:ChengShuling"] = "Riot",
	["lolTianlai"] = "天籁",
	[":lolTianlai"] = "出牌阶段开始时，你可跳过本回合，令其他在你攻击范围内的角色失去1点体力",
	["lolMianJing"] = "面筋",
	[":lolMianJing"] = "出牌阶段，你可弃置一张装备牌，令一名角色回复一点体力，每回合限一次",

	["cangjingkong"] = "苍井空",
	[":cangjingkong"] = "装备：马<br>骑乘效果：其他角色与你计算距离时，始终+1。",

	["boduoye"] = "波多野结衣",
	[":boduoye"] = "装备：马<br>骑乘效果：你与其他角色计算距离时，始终-1。",

	["maliya"] = "小泽玛丽亚",
	[":maliya"] = "装备：马<br>骑乘效果：你与其他角色计算距离时，始终+1。",

	["taogu"] = "桃谷绘里香",
	[":taogu"] = "装备：马<br>骑乘效果：你与其他角色计算距离时，始终-1。",
}
