-- 众星之子
-- 救赎
local jiushu_skill = {
	name = "lolJiushu",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#lolJiushuCard") then
			return nil
		end
		return sgs.Card_Parse("#lolJiushuCard:.:")
	end,
}
table.insert(sgs.ai_skills, jiushu_skill)
sgs.ai_skill_use_func["#lolJiushuCard"] = function(card, use, self)
	local needHelp, doNotNeedHelp = self:getWoundedFriend(false, true)
	if #needHelp > 0 then
		use.card = card
		if use.to then
			if needHelp[1]:objectName() == self.player:objectName() then
				return
			else
				use.to:append(needHelp[1])
			end
		end
		return
	end
end

sgs.ai_use_value["lolJiushuCard"] = sgs.ai_use_value["QingnangCard"]
sgs.ai_use_priority["lolJiushuCard"] = 1
sgs.ai_card_intention["lolJiushuCard"] = sgs.ai_card_intention["QingnangCard"]
-- 沙漠死神
-- 死神
local sishen_skill = {
	name = "lolSishen",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@NasusR") > 0 then
			return sgs.Card_Parse("#lolSishenCard:.:")
		end
	end
}
table.insert(sgs.ai_skills, sishen_skill)
sgs.ai_skill_use_func["#lolSishenCard"] = function(card, use, self)
	local targets = self.room:getAlivePlayers()
	for _, target in sgs.qlist(targets) do
		if target:getHp() == 1 then
			use.card = card
		end
	end
end
sgs.ai_use_value["lolSishenCard"] = 100
sgs.ai_use_priority["lolSishenCard"] = 100
-- 齐天大圣
-- 千变
sgs.ai_skill_invoke["lolQianbian"] = function(self, data)
	return self.player:getHandcardNum() > 1
end

sgs.lolQianbian_keep_value = {
	heart = 5
}
-- 万化
sgs.ai_skill_invoke["lolWanhua"] = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.from) then
		return true
	end
end
-- 凛冬之怒
-- 寒狱
local hanyu_skill = {
	name = "lolHanyu",
	getTurnUseCard = function(self, inclusive)
		local targets = self.player:getAliveSiblings()
		local total_count = 0
		for _, target in sgs.qlist(targets) do
			total_count = total_count + target:getHandcardNum()
		end
		local limit_num = targets:length() * 3
		if limit_num < total_count then
			return sgs.Card_Parse("#lolHanyuCard:.:")
		end
	end
}
table.insert(sgs.ai_skills, hanyu_skill)
sgs.ai_skill_use_func["#lolHanyuCard"] = function(card, use, self)
	-- self:sort(self.enemies, "threat")
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isNude() and enemy:getMark("@coldPrison") < 2 then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			break
		end
	end
end

sgs.ai_use_value["lolHanyuCard"] = sgs.ai_use_value["Dismantlement"]
sgs.ai_use_priority["lolHanyuCard"] = sgs.ai_use_priority["Dismantlement"]
sgs.ai_choicemade_filter["cardChosen"].lolHanyu = sgs.ai_choicemade_filter["cardChosen"].dismantlement
sgs.ai_card_intention["lolHanyuCard"] = sgs.ai_card_intention["Dismantlement"]
-- 光辉女郎
-- 光缚
local guangfu_skill = {
	name = "lolGuangfu",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#lolGuangfuCard") then
			return nil
		end
		return sgs.Card_Parse("#lolGuangfuCard:.:")
	end,
}
table.insert(sgs.ai_skills, guangfu_skill)
sgs.ai_skill_use_func["#lolGuangfuCard"] = function(card, use, self)
	local slashs = {}
	local handcards = self.player:getHandcards()
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			table.insert(slashs, c)
		end
	end
	if #slashs == 0 then
		return 
	end
	local target = nil
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) then
			target = enemy
			break
		end
	end
	if target then
		self:sortByUseValue(slashs, true)
		local slash = slashs[1]
		local card_str = "#lolGuangfuCard:"..slash:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["lolGuangfuCard"] = sgs.ai_use_value["Indulgence"]
sgs.ai_use_priority["lolGuangfuCard"] = sgs.ai_use_priority["Indulgence"]
sgs.ai_card_intention["lolGuangfuCard"] = sgs.ai_card_intention["Indulgence"]
sgs.lolGuangfu_suit_value = {
	slash = 3,
}
sgs.ai_cardneed["lolGuangfu"] = function(target, card, self)
	return card:isKindOf("Slash")
end

-- 曲光
local quguang_skill = {
	name = "lolQuguang",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#lolQuguangCard") then
			return nil
		end
		return sgs.Card_Parse("#lolQuguangCard:.:")
	end,
}
table.insert(sgs.ai_skills, quguang_skill)
sgs.ai_skill_use_func["#lolQuguangCard"] = function(card, use, self)
	local equips = {}
	local cards = self.player:getCards("he")
	for _, card in sgs.qlist(cards) do
		if card:isKindOf("EquipCard") then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then
		return
	end
	local target = nil
	self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if ((friend:getHp() <= 1) or (friend:getLostHp() >= 2)) and friend:getMark("@Dun") == 0 then
			target = friend
			break
		end
	end
	if target then
		self:sortByUseValue(equips, true)
		local equip = equips[1]
		local card_str = "#lolQuguangCard:"..equip:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["lolQuguangCard"] = sgs.ai_use_value["QingnangCard"]
sgs.ai_use_priority["lolQuguangCard"] = 1

sgs.ai_cardneed["lolQuguang"] = function(target, card, self)
	return card:isKindOf("EquipCard")
end

-- 卡牌大师
-- 命运
local mingyun_skill = {
	name = "lolMingyun",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#lolMingyunCard") then
			return nil
		end
		return sgs.Card_Parse("#lolMingyunCard:.:")
	end,
}
table.insert(sgs.ai_skills, mingyun_skill)
sgs.ai_skill_use_func["#lolMingyunCard"] = function(card, use, self)
	local is_use = nil
	if self.player:getMark("@cardBlue") > 0 then
		is_use = math.random(0, 1)
	elseif self.player:getMark("@cardRed") > 0 then
		is_use = math.random(0, 3)
	elseif self.player:getMark("@cardYellow") > 0 then
		is_use = math.random(0, 6)
	end
	if self.player:hasFlag("Mingyun-ai") then
		is_use = 0
	end
	if is_use ~= 0 then
		use.card = card
	else
		self.room:setPlayerFlag(self.player, "Mingyun-ai")
	end
end

sgs.ai_use_value["lolMingyunCard"] = 5
sgs.ai_use_priority["lolMingyunCard"] = 10
-- 选牌
local xuanpai_skill = {
	name = "lolXuanpai",
	getTurnUseCard = function(self, inclusive)
		local cards = self.player:getCards("he")
		local can_use = {}
		for _, c in sgs.qlist(cards) do
			-- 
			if (c:getSuitString() == "heart" and self.player:hasFlag("lolMingyunYellow")) or 	
			(c:getSuitString() == "spade" and self.player:hasFlag("lolMingyunBlue")) or
			(c:getSuitString() == "diamond" and self.player:hasFlag("lolMingyunRed")) then
			--
				table.insert(can_use, c)
			end			
		end
		if #can_use == 0 then
			return nil
		end
		self:sortByKeepValue(can_use)
		local to_use = can_use[1]
		local id = to_use:getEffectiveId()
		local suit = to_use:getSuit()
		local point = to_use:getNumber()
		local card_str = nil
		-- 
		if self.player:hasFlag("lolMingyunYellow") then
			card_str = string.format("ex_nihilo:lolXuanpai[%s:%d]=%d", suit, point, id)
		elseif self.player:hasFlag("lolMingyunRed") then
			card_str = string.format("indulgence:lolXuanpai[%s:%d]=%d", suit, point, id)
		elseif self.player:hasFlag("lolMingyunBlue") then
			card_str = string.format("dismantlement:lolXuanpai[%s:%d]=%d", suit, point, id)
		end
		-- 
		return sgs.Card_Parse(card_str)
	end,
}
table.insert(sgs.ai_skills, xuanpai_skill)

sgs.ai_cardneed["lolXuanpai"] = function(target, card, self)
	if self.player:hasFlag("lolMingyunBlue") then
		return card:getSuitString() == "spade"
	elseif self.player:hasFlag("lolMingyunRed") then
		return card:getSuitString() == "diamond"
	elseif self.player:hasFlag("lolMingyunYellow") then
		return card:getSuitString() == "heart"
	end
end

-- 兽灵行者
-- 乌迪尔
sgs.ai_skill_invoke["lolSiling"] = function(self, data)
	return true
end

-- 虚空之女
-- 超载
sgs.ai_skill_invoke["lolChaozai"] = function(self, data)
	local player = self.player
	local cards = player:getCards("h")
	local red_count = 0
	for _, card in sgs.qlist(cards) do
		if card:isRed() then
			red_count = red_count + 1
		end
	end
	if player:getPile("HeavyRain"):length() == 0 then
		if red_count >= 2 then
			return true
		end
	end
	return nil
end

sgs.ai_lolChaozai_suit_value = {
	diamond = 3.9,
	heart = 3.9,
}
-- 暴雨(
local baoyu_skill = {
	name = "lolBaoyu",
	getTurnUseCard = function(self, inclusive)
		local card_ids = self.player:getPile("HeavyRain")
		if card_ids:length() > 0 then
			local card = sgs.Sanguosha:getCard(card_ids:first())
			local suit = card:getSuit()
			local id = card:getEffectiveId()
			local number = card:getNumber()
			local str = string.format("slash:lolBaoyu[%s:%d]=%d", suit, number, id)
			return sgs.Card_Parse(str)
		end
	end,
}
table.insert(sgs.ai_skills, baoyu_skill)

sgs.ai_cardneed["lolBaoyu"] = function(target, card, self)
	return self.player:getPileName(card:getId()) == "HeavyRain"
end

-- 山隐之焰
-- 众生
sgs.ai_skill_invoke["lolZhongsheng"] = function(self, data)
	return true
end

-- 平等
local pingdeng_skill = {}
pingdeng_skill.name = "lolPingdeng"
table.insert(sgs.ai_skills, pingdeng_skill)
pingdeng_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:hasUsed("#lolPingdengCard") then
		return nil
	end
	return sgs.Card_Parse("#lolPingdengCard:.:")
end
sgs.ai_skill_use_func["#lolPingdengCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local cards = {}
	if handcards:length() > 0 then
		for _, c in sgs.qlist(handcards) do
			table.insert(cards, c)
		end
	end
	self:sortByUseValue(cards, true)
	local target = nil
	self:sort(self.friends, "defense")
	for _,friend in ipairs(self.friends) do
		if not friend:faceUp() then
			target = friend
			break
		end
	end
	if not target then
		if #self.enemies > 0 then
			self:sort(self.enemies, "threat")
			for _,enemy in ipairs(self.enemies) do
				if enemy:faceUp() then
					target = enemy
					break
				end
			end
		end
	end
	if target then
		local card_str = "#lolPingdengCard:"..cards[1]:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["lolPingdengCard"] = 3
sgs.ai_use_priority["lolPingdengCard"] = 2
sgs.ai_card_intention["lolPingdengCard"] = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if self:toTurnOver(to, 0, "lolPingdeng") then
			sgs.updateIntention(from, to, 80)
		else
			sgs.updateIntention(from, to, -80)
		end
	end
end

-- 德玛西亚之力
-- 正义
local nzhengyi_skill = {}
nzhengyi_skill.name = "lolNZhengyi"
table.insert(sgs.ai_skills, nzhengyi_skill)
nzhengyi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@Garen_R") > 0 then
		return sgs.Card_Parse("#lolNZhengyiCard:.:")
	end
end
sgs.ai_skill_use_func["#lolNZhengyiCard"] = function(card, use, self)
	self:sort(self.enemies)
	local target = nil
	for _, enemy in ipairs(self.enemies) do
		if enemy:getLostHp() >= 3 or enemy:getHp() <= 1 or self.player:getHp() <= 1 then
			target = enemy
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

-- 虚空先知
-- 冥府
local mingfu_skill = {}
mingfu_skill.name = "lolMingfu"
table.insert(sgs.ai_skills, mingfu_skill)
mingfu_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:getMark("@Sheol") > 0 then
		return sgs.Card_Parse("#lolMingfuCard:.:")
	end
end
sgs.ai_skill_use_func["#lolMingfuCard"] = function(card, use, self)
	self:sort(self.enemies)
	target = nil
	local count = 0
	local players = self.room:getAlivePlayers()
	self.player:speak("1")
	for _, player in sgs.qlist(players) do
		if player:hasSkill("lolMingfu") then
			count = count + 1
		end
	end
	self.player:speak("2")
	for _, enemy in ipairs(self.enemies) do
		if count < 2 and not enemy:hasSkill("lolMingfu") then
			self.player:speak("3")
			target = enemy
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end	
end

-- 荣誉行刑官
-- 飞斧
sgs.ai_skill_invoke["lolLianmeng"] = function(self, data)
	return true
end

-- 疾风剑豪
-- 浪客

sgs.ai_skill_playerchosen["lolLangke"] = function(self, targets)	
	return self:findPlayerToDiscard("h", true, true)
end

-- 亡灵战神
-- 融魂
local ronghun_skill = {}
ronghun_skill.name = "lolRonghun"
table.insert(sgs.ai_skills, ronghun_skill)
ronghun_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:getMark("@Dun") == 0 and not self.player:hasUsed("#lolRonghunCard") then
		return sgs.Card_Parse("#lolRonghunCard:.:")
	end
end
sgs.ai_skill_use_func["#lolRonghunCard"] = function(card, use, self)
	if self.player:getHp() > 2 then
		use.card = card
	end
end

sgs.ai_use_priority["lolRonghunCard"] = 3

-- 铸魂
local zhuhun_skill = {}
zhuhun_skill.name = "lolZhuhun"
table.insert(sgs.ai_skills, zhuhun_skill)
zhuhun_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then
		return sgs.Card_Parse("#lolZhuhunCard:.:")
	end
end
sgs.ai_skill_use_func["#lolZhuhunCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local peaches = {}
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Peach") then
			table.insert(peaches, c)
		end
	end
	local peach = nil
	if #peaches > 0 then
		peach = peaches[1]
		local card_str = "#lolZhuhunCard:"..peach:getEffectiveId()..":->"..self.player:objectName()
		acard = sgs.Card_Parse(card_str)
		use.card = acard
	end
end

sgs.ai_use_priority["lolZhuhunCard"] = 4

-- 虚空行者
-- 虚无
local xuwu_skill = {}
xuwu_skill.name = "lolXuwu"
table.insert(sgs.ai_skills, xuwu_skill)
xuwu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#lolXuwuCard") then	
		return sgs.Card_Parse("#lolXuwuCard:.:")
	end
end
sgs.ai_skill_use_func["#lolXuwuCard"] = function(card, use, self)
	local target = nil
	self:sort(self.enemies, "defense")
	if #self.enemies > 0 then
		target = self.enemies[1]
	end
	if not target then
		local targets = self.room:getAlivePlayers()
		target = targets:first()
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end	
end

sgs.ai_use_priority["lolXuwuCard"] = 10

-- 虚刃
sgs.ai_skill_invoke["lolXuren"] = function(self, data)
	local use = data:toCardUse()
	local to = use.to:first()
	if self:isEnemy(to) then
		return true
	end
end

-- 无极剑圣
-- 冥想
local nmingxiang_skill = {}
nmingxiang_skill.name = "lolNMingxiang"
table.insert(sgs.ai_skills, nmingxiang_skill)
nmingxiang_skill.getTurnUseCard = function(self, inclusive)	
	if not self.player:hasUsed("#lolNMingxiangCard") then
		return sgs.Card_Parse("#lolNMingxiangCard:.:")
	end
end
sgs.ai_skill_use_func["#lolNMingxiangCard"] = function(card, use, self)
	if self.player:getHp() <= 1 then
		use.card = card
	end	
end

-- 无极
local nwuji_skill = {}
nwuji_skill.name = "lolNWuji"
table.insert(sgs.ai_skills, nwuji_skill)
nwuji_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:getMark("@YiR") > 0 then
		return sgs.Card_Parse("#lolNWujiCard:.:")
	end
end
sgs.ai_skill_use_func["#lolNWujiCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local count = 0
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			count = count + 1
		end
	end
	if #self.enemies == 0 then
		count = 0
	end
	if count >= 3 then
		use.card = card
	end
end

sgs.ai_use_value["lolNWujiCard"] = 10
sgs.ai_use_priority["lolNWujiCard"] = 10

-- 蛮族之王
-- 不灭
sgs.ai_skill_invoke["lolBumie"] = function(self, data)
	return true
end

-- 荒漠屠夫
-- 暴君
sgs.ai_skill_invoke["lolBaoJun"] = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		if damage.to:faceUp() then
			return true
		end
	end
end

-- 统治
local tongzhi_skill = {}
tongzhi_skill.name = "lolTongzhi"
table.insert(sgs.ai_skills, tongzhi_skill)
tongzhi_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:getMark("@RenektonR") > 0 then
		return sgs.Card_Parse("#lolTongzhiCard:.:")
	end
end
sgs.ai_skill_use_func["#lolTongzhiCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["lolTongzhiCard"] = 5

-- 卡尔萨斯
-- 镇魂
sgs.ai_skill_invoke["lolZhenhun"] = function(self, data)
	local targets = self.room:getAlivePlayers()
	for _, target in sgs.qlist(targets) do
		if target:getPhaseString() == "start" then
			if self:isEnemy(target) then
				return true
			end
		end
	end
end

-- 德玛西亚皇子
-- 地裂
local ndilie_skill = {}
ndilie_skill.name = "lolNDilie"
table.insert(sgs.ai_skills, ndilie_skill)
ndilie_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#lolNDilieCard") then	
		return sgs.Card_Parse("#lolNDilieCard:.:")
	end
end
sgs.ai_skill_use_func["#lolNDilieCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local has_slash = false
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			has_slash = true
			break
		end
	end
	local dilies = {}
	for _, c in sgs.qlist(handcards) do
		if c:isRed() or c:isKindOf("EquipCard") then
			table.insert(dilies, c)
		end
	end
	self:sortByUseValue(dilies, true)
	local dilie = nil
	dilie = dilies[1]
	self:sort(self.friends)
	if #self.friends > 0 and has_slash and dilie then
		local card_str = "#lolNDilieCard:"..dilie:getEffectiveId()..":->"..self.player:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			if self.player:isLord() then
				for _, friend in ipairs(self.friends) do
					use.to:append(friend)
				end
			else
				use.to:append(self.player)
			end
		end
	end
end

sgs.ai_use_priority["lolNDilieCard"] = 3
