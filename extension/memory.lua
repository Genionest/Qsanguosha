module("extensions.memory",package.seeall)

extension = sgs.Package("memory")

youwangyong = sgs.General(extension,"wangyong","wei",4)

siling = {}
siling["heart"] = "paoxiao"
siling["spade"] = "bazhen"
siling["diamond"] = "qianxun"
siling["club"] = "wushuang"


yousiling = sgs.CreateTriggerSkill{
	name = "yousiling",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart,sgs.FinishJudge},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhaseString() == "start" then
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.pattern = "."
				judge.reason = self:objectName()
				room:judge(judge)
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				for _,skill in ipairs({"wushuang","paoxiao","qianxun","bazhen"}) do
					room:detachSkillFromPlayer(player, skill)
				end
				local suit = judge.card:getSuitString()
				room:acquireSkill(player, siling[suit])
			end
		end
	end,	
}

youwangyong:addSkill(yousiling)

youbaisheng = sgs.General(extension, "baisheng", "wei", 3)

youbaiju = sgs.CreateTriggerSkill{
	name = "youbaiju",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "finish" then
			if player:getPile("Ju"):length() == 0 then
				if player:askForSkillInvoke(self:objectName(), data) then
					local cards = player:getHandcards()
					local count = 0
					for _,card in sgs.qlist(cards) do
						if card:isKindOf("Slash") then
							player:addToPile("Ju", card, true)
							count = count + 1
							if count >= 2 then
								break
							end
						end
					end
				end
			end
		end
	end,	
}

youbaiju2 = sgs.CreateDistanceSkill{
	name = "#youbaiju2",
	correct_func = function(self,from,to)
		if from:hasSkill( self:objectName() ) then
			return -from:getPile("Ju"):length()
		elseif to:hasSkill( self:objectName() ) then
			return to:getPile("Ju"):length()
		end
	end
}

youbaisheng:addSkill(youbaiju)
youbaisheng:addSkill(youbaiju2)

youzhangen = sgs.General(extension, "zhangen", "wei", 3)

youxiaoyoucard = sgs.CreateSkillCard{
	name = "youxiaoyoucard",	
	target_fixed = true,	 
	will_throw = true,
	on_use = function(self,room,source,targets)		
		local id = room:askForCardChosen(source, source, "h", self:objectName())
		room:showCard( source, id )
		local card = sgs.Sanguosha:getCard(id)
		if not card:isKindOf("EquipCard") then
			-- card:setTag("xiaoyou", sgs.QVariant( id ) )
			room:setCardFlag(card, "xiaoyou")
			-- source:setMark("xiaoyou", id)
			-- source:setFlags( card:objectName() )
			-- source:speak( tostring( card:getTag("xiaoyou"):toInt() ) )
			if card:isRed() then
				room:setPlayerFlag(source, "red")
				-- room:setPlayerMark(source, "color", 1)
			elseif card:isBlack() then
				room:setPlayerFlag(source, "black")
				-- room:setPlayerMark(source, "color", 2)
			end
		else
			return false
		end
	end,
}

youxiaoyou = sgs.CreateZeroCardViewAsSkill{
	name = "youxiaoyou",	
	view_as = function(self)
		return youxiaoyoucard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#youxiaoyoucard")
	end,
}

youshuangsheng = sgs.CreateViewAsSkill{
	name = "youshuangsheng",
	n = 1,
	view_filter = function(self,selected,to_select)
		if sgs.Self:hasFlag("red") then
		-- if sgs.Self:getMark("color") == 1 then
			return to_select:isRed()
		elseif sgs.Self:hasFlag("black") then
		-- elseif sgs.Self:getMark("color") == 2 then
			return to_select:isBlack()
		else
			return #selected == 0
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return false
		end
		local card = nil
		for _, handcard in sgs.qlist( sgs.Self:getHandcards() ) do
			if handcard:hasFlag('xiaoyou') then
				card = handcard
			end
		end
		if card == nil then return false end
		-- local str = sgs.Self:getFlags()
		local suit = cards[1]:getSuit()
		local number = cards[1]:getNumber()
		local vs_card = sgs.Sanguosha:cloneCard( card:objectName(), suit, number )
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName( self:objectName() )
		sgs.Self:setFlags("xiaoyou")
		return vs_card
	end,
	enabled_at_play = function(self,player)
		if not player:hasFlag("xiaoyou") then
			return player:hasFlag("red") or player:hasFlag("black")
		end
		-- return player:getMark("color") > 0
	end,
}

youshuangsheng2 = sgs.CreateTriggerSkill{
	name = "#youshuangsheng2",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "finish" then
			for _, card in sgs.qlist(player:getHandcards() ) do
				card:ClearFlags()
			end
		end
	end,
}

youzhangen:addSkill(youxiaoyou)
youzhangen:addSkill(youshuangsheng)
youzhangen:addSkill(youshuangsheng2)

youmuyong = sgs.General(extension, "muyong", "wei", 4)
--当你受到伤害时，你可以选择一项：你的跳过下个弃牌阶段；伤害来源跳过下个摸牌阶段
youwufeng = sgs.CreateMasochismSkill{
	name = "youwufeng",	
	frequeny = sgs.Skill_Frequent,	
	-- view_as_skill = ,
	on_damaged = function(self,player,damage)
		local room = player:getRoom()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			local data = sgs.QVariant()
			data:setValue(damage)
			if player:askForSkillInvoke(self:objectName(), data ) then
				--清楚其他角色的武风标记
				for _, target in sgs.qlist(room:getAlivePlayers() ) do
					target:setMark("wufeng", 0)
				end
				local choice = room:askForChoice(player, self:objectName(), "draw+discard", data)
				if choice == "draw" then
					damage.from:addMark("wufeng_draw")
				elseif choice == "discard" then
					player:addMark("wufeng_discard")
				end
				damage.from:addMark("wufeng")
			end
		end
	end,	
}

youwufeng2 = sgs.CreateTriggerSkill{
	name = "#youwufeng2",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseChanging},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName() )
		local dest = nil
		for _, target in sgs.qlist( room:getAlivePlayers() ) do
			if target:getMark("wufeng") > 0 then
				dest = target
				break
			end
		end
		if dest == nil then return false end
		local change = data:toPhaseChange()
		if player:getMark("wufeng_draw") > 0 then
			if change.to == sgs.Player_Draw then
				player:skip(sgs.Player_Draw)
				player:setMarks("wufeng_draw", 0)
			end
		end
		if player:getMark("@Tree") > 0 then
			if change.to == sgs.Player_Discard then
				player:skip(sgs.Player_Discard)
				player:setMarks("wufeng_discard", 0)
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

youmuyong:addSkill(youwufeng)
youmuyong:addSkill(youwufeng2)

youxiaoshun = sgs.General(extension, "xiaoshun", "wei", 4)

youyingxiang = sgs.CreateTriggerSkill{
	name = "youyingxiang",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.Damaged, sgs.HpRecover},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged and player:askForSkillInvoke(self:objectName(), data) then
			local damage = sgs.DamageStruct()
			damage.from = player
			damage.damage = 1
			for _, target in sgs.qlist(room:getOtherPlayers(player) ) do
				if player:isAdjacentTo(target) then
					damage.to = target
					room:damage(damage)
				end
			end
		elseif event == sgs.HpRecover and player:askForSkillInvoke(self:objectName(), data) then
			local recover = sgs.RecoverStruct()
			recover.who = player
			for _, target in sgs.qlist(room:getOtherPlayers(player) ) do
				if player:isAdjacentTo(target) then
					room:recover(target, recover)
				end
			end
		end
	end,	
}

youxiaoshun:addSkill(youyingxiang)

youlongyihong = sgs.General(extension, "longyihong", "wei", 3)
--方块：杀，闪；黑桃：过河拆桥，无懈可击
youtianjian = sgs.CreateViewAsSkill{
	name = "youtianjian",
	-- relate_to_place = deputy,	
	n = 1,
	view_filter = function(self,selected,to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if sgs.Slash_IsAvailable(sgs.Self) and (to_select:getSuit() == sgs.Card_Diamond) then
				if sgs.Self:getWeapon() and (to_select:getEffectiveId() == sgs.Self:getWeapon():getId())
						and to_select:isKindOf("Crossbow") then
					return sgs.Self:canSlashWithoutCrossbow()
				else
					return true
				end
			elseif to_select:getSuitString() == "spade" then
				return true
			end
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		 or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		 	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		 	if pattern == "jink" then
		 		return to_select:getSuitString() == "diamond"
		 	elseif pattern == "nullification" then
		 		return to_select:getSuitString() == "spade"
		 	end
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then return nil end
		local card = cards[1]
		local vs_card = nil
		-- if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		if sgs.Self:getPhaseString() == "play" then
			if card:getSuitString() == "diamond" then
				vs_card = sgs.Sanguosha:cloneCard( "slash", card:getSuit(), card:getNumber() )
			elseif card:getSuitString() == "spade" then
				vs_card = sgs.Sanguosha:cloneCard( "dismantlement", card:getSuit(), card:getNumber() )
			end
		-- elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		--  or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		elseif sgs.Self:getPhaseString() == "not_active" then
			if card:getSuitString() == "diamond" then
				vs_card = sgs.Sanguosha:cloneCard( "jink", card:getSuit(), card:getNumber() )
			elseif card:getSuitString() == "spade" then
				vs_card = sgs.Sanguosha:cloneCard( "nullification", card:getSuit(), card:getNumber() )
			end
		end
		vs_card:addSubcard(card)
		vs_card:setSkillName( self:objectName() )
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return true
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getPhaseString() == "not_active" then
			return pattern == "jink" or pattern == "nullification"
		end
		return false
	end,		
	enabled_at_nullification = function(self,player)
		if player:getPhaseString() ~= "not_active" then
			return false
		end
		local count = 0
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
		for _, card in sgs.qlist(player:getEquips()) do
			if card:getSuit() == sgs.Card_Spade then count = count + 1 end
			if count >= 1 then return true end
		end
	end
}

youlongming = sgs.CreateTriggerSkill{
	name = "youlongming",	
	frequeny = sgs.Skill_Frequent,	 
	events = {sgs.Damage},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal then
			if damage.from and damage.from:objectName() ~= damage.to:objectName() then
				if player:askForSkillInvoke(self:objectName(), data) then
					local mhp = sgs.QVariant()
					local count = damage.to:getMaxHp()
					mhp:setValue(count-1)
					room:setPlayerProperty(damage.to, "maxhp", mhp)
				end
			end
		end
	end,	
}

youlongyihong:addSkill(youtianjian)
youlongyihong:addSkill(youlongming)

maomao = sgs.General(extension, "maomao", "qun", 4)

yousutong = sgs.CreateTriggerSkill{
	name = "yousutong",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		local damage = data:toDamage()
		if damage.from and (damage.from:objectName() == me:objectName() or
		 damage.to:objectName() == me:objectName() ) then
			local hp = damage.to:getHp()
			local new_damage = hp
			damage.damage = hp
			data:setValue(damage)
		end
	end,
	can_trigger = function(self,target)
			return target
	end	
}

maomao:addSkill(yousutong)

kkv = sgs.General(extension, "kkv", "qun", 6)

youfanche = sgs.CreateTriggerSkill{
	name = "youfanche",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:objectName() == player:objectName() then
			if damage.to:getHp() <= damage.damage then
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.pattern = ".|red"
				judge.reason = self:objectName()
				judge.good = true
				room:judge(judge)
				if judge:isBad() then
					return true
				end
			end
		end
	end,	
}

kkv:addSkill(youfanche)

aochangzhang = sgs.General(extension, "aochangzhang", "god", 4)

yougemen = sgs.CreateTriggerSkill{
	name = "yougemen",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DrawNCards},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local count = 0
		for _, target in sgs.qlist(room:getAlivePlayers()) do
			if target:getKingdom() == player:getKingdom() then
				count = count + 1
			end
		end
		count = count + data:toInt()
		data:setValue(count)
	end,	
}

yougemen2 = sgs.CreateMaxCardsSkill{
	name = "#yougemen2",
	extra_func = function(self,player)
		if player:hasSkill(self:objectName()) then
			local targets = player:getAliveSiblings()
			local count = 1
			for _, target in sgs.qlist(targets) do
				if target:getKingdom() == player:getKingdom() then
					count = count + 1
				end
			end
			return count
		end
	end
}

aochangzhang:addSkill(yougemen)
aochangzhang:addSkill(yougemen2)

yangweitao = sgs.General(extension, "yangweitao", "shu", 3)

youcusi = sgs.CreateTriggerSkill{
	name = "youcusi",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd, sgs.HpChanged},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhaseString() == "start" then
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.pattern = ".|spade|2,3,4,5,6,7|."
				judge.reason = self:objectName()
				judge.good = false
				room:judge(judge)
				player:speak("1")
				if judge:isBad() then
					player:speak("2")
					room:killPlayer(player)
				end
			end
		elseif event == sgs.HpChanged then
			if player:getHp() <= 0 then
				local hp = sgs.QVariant(1)
				room:setPlayerProperty(player, "hp", hp)
			end
		end
	end,
}

yangweitao:addSkill(youcusi)

zhognyong = sgs.General(extension, "zhongyong", "wei", 4)

shandongcard = sgs.CreateSkillCard{
	name = "shangdongcard",	
	target_fixed = true,	 
	will_throw = false,
	-- handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		if targets[1]:canSlash(targets[2]) then
		end
	end,
	on_effect = function(self,effect)
		
	end,	
}





















sgs.LoadTranslationTable{
	["memory"] = "回忆包",

	["wangyong"] = "王勇",
	["&wangyong"] = "王勇",
	["#wangyong"] = "灵魂护卫",
	["designer:wangyong"] = "Wargon",
	["cv:wangyong"] = "Miss Baidu",
	["illustrator:wangyong"] = "",
	["yousiling"] = "四灵",
	[":yousiling"] = "回合开始时，你进行一次判定，并根据判定结果获得以下一项技能，你最多同时拥有其中一项。红桃：咆哮，黑桃：八阵，方块：谦逊，梅花：无双",

	["Ju"] = "驹",
	["baisheng"] = "柏国胜",
	["&baisheng"] = "柏国胜",
	["#baisheng"] = "白驹先锋",
	["designer:baisheng"] = "Wargon",
	["cv:baisheng"] = "Miss Baidu",
	["illustrator:baisheng"] = "",
	["youbaiju"] = "白驹",
	[":youbaiju"] = "回合结束阶段，若你武将牌上没有“驹”，你可将手牌中所有的【杀】置于武将牌上称为“驹”(最多两张)，你每拥有一张“驹”，你与其他角色计算距离时便-1，其他角色与你计算距离时便+1。",

	["zhangen"] = "张显恩",
	["&zhangen"] = "张显恩",
	["#zhangen"] = "阴阳之子",
	["designer:zhangen"] = "Wargon",
	["cv:zhangen"] = "Miss Baidu",
	["illustrator:zhangen"] = "",
	["youxiaoyou"] = "效尤",
	[":youxiaoyou"] = "出牌阶段，你可展示自己的一张手牌。每回合限一次。",
	["youshuangsheng"] = "双生",
	[":youshuangsheng"] = "若你于回合内发动过“效尤”，且展示的牌不为装备牌并仍在你手上，则你本回合可以将一张与展示牌相同颜色的牌当其使用。每回合限一次。",

	["muyong"] = "穆先旭",
	["&muyong"] = "穆先旭",
	["#muyong"] = "星之血缘",
	["designer:muyong"] = "Wargon",
	["cv:muyong"] = "Miss Baidu",
	["illustrator:muyong"] = "",
	["youwufeng"] = "武风",
	[":youwufeng"] = "当你受到伤害时，你可以选择一项：你跳过下个弃牌阶段；伤害来源跳过下个出牌阶段。",

	["xiaoshun"] = "穆小顺",
	["&xiaoshun"] = "穆小顺",
	["#xiaoshun"] = "星辰之末",
	["designer:xiaoshun"] = "Wargon",
	["cv:xiaoshun"] = "Miss Baidu",
	["illustrator:xiaoshun"] = "",
	["youyingxiang"] = "影响",
	[":youyingxiang"] = "当你受到伤害时，你可令你旁边的角色受到1点伤害；当你回复一点体力时，你可令你旁边的角色回复一点体力",

	["longyihong"] = "龙义鸿",
	["&longyihong"] = "龙义鸿",
	["#longyihong"] = "苍之龙裔",
	["designer:longyihong"] = "Wargon",
	["cv:longyihong"] = "Miss Baidu",
	["illustrator:longyihong"] = "",
	["youtianjian"] = "天剑",
	[":youtianjian"] = "出牌阶段，你可将方块牌当【杀】使用，黑桃牌当【过河拆桥】使用；回合外，你可将方块牌当【闪】使用，黑桃牌当【无懈可击】使用。",
	["youlongming"] = "龙鸣",
	[":youlongming"] = "当你造成属性伤害时，你可令受伤角色损失一点体力上限。",

	["maomao"] = "毛毛",
	["&maomao"] = "毛毛",
	["#maomao"] = "速通之王",
	["designer:maomao"] = "Wargon",
	["cv:maomao"] = "Miss Baidu",
	["illustrator:maomao"] = "",
	["yousutong"] = "速通",
	[":yousutong"] = "你造成或受到伤害时，伤害值等于受伤角色的体力值。",

	["kkv"] = "KKV",
	["&kkv"] = "KKV",
	["#kkv"] = "翻车王",
	["designer:kkv"] = "Wargon",
	["cv:kkv"] = "Miss Baidu",
	["illustrator:kkv"] = "",
	["youfanche"] = "翻车",
	[":youfanche"] = "你对一名角色造成致命伤害时，你进行一次判定，若结果为黑色，你将不造成此伤害。",

	["aochangzhang"] = "敖缘凤",
	["&aochangzhang"] = "敖缘凤",
	["#aochangzhang"] = "敖厂长",
	["designer:aochangzhang"] = "Wargon",
	["cv:aochangzhang"] = "Miss Baidu",
	["illustrator:aochangzhang"] = "",
	["yougemen"] = "哥们",
	[":yougemen"] = "摸牌阶段，场上每存活一名与你相同势力的角色，你便多摸一张牌，你的手牌上限便+1。",

	["yangweitao"] = "杨伟涛",
	["&yangweitao"] = "杨伟涛",
	["#yangweitao"] = "死肥宅",
	["designer:yangweitao"] = "Wargon",
	["cv:yangweitao"] = "Miss Baidu",
	["illustrator:yangweitao"] = "",
	["youcusi"] = "猝死",
	[":youcusi"] = "回合开始时，你进行一次判定，若结果为黑桃2-7，你直接死亡；当你的体力值减少到0或更低时，你的体力值变为1。",
}