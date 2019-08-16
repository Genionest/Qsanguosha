module("extensions.lol",package.seeall)

extension = sgs.Package("lol")
--------------------------------------------------------------------------------
--移出字符串首位的@
--	(string)name, 需要进行修改的字符串
removeAt = function(name)
	if name:find("@") then
		name = string.sub(name,2,-1)
	else
		name = name
	end
	return name
end

removeCardStr = function(card)
	local name = card:objectName()
	if name:find("Card") then
		name = string.sub(name,1,-5)
	end
	return name
end

--你只需为武将添加这个函数返回的技能，游戏开始时他就会为你的武将返回一个Rmark所代表的标记
--ex：lolWujinagR = getRMark("@WujiangR")
--    Wujiang:addSkill(lolWujiangR)
-- 游戏开始时，Wujiang这个武将就会获得一枚"@WujiangR"标记，以下的其他函数同理

--	(string)Rmark 游戏开始时要添加的mark
getRMark = function(Rmark)
	local Rname = removeAt(Rmark)
	local lolR = sgs.CreateTriggerSkill{
		name = "#"..Rname,	
		frequeny = sgs.Skill_Frequent, 
		events = {sgs.GameStart},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			player:gainMark(Rmark)	
		end,	
	}
	return lolR
end

--返回两个技能，
--技能1：使用【杀】，获得mark标记，并且将markClear标记设置为0，并添加mark(无@) flag
--技能2：回合内你没有使用【杀】，你获得一枚markClear标记，如果markClear标记大于round
--		 失去一枚mark标记，并将markClear标记设为round-1，如果你有mark(无@) flag，你不会
--		 获得markClear标记
--	(string)mark, 使用【杀】获得的标记
--	(int)round, 连续不适用【杀】多少回合后，会失去标记
--	(int)max, 标记数量的上限
SlashedMarkPassive = function(mark,round,max)
	--清除mark的@
	local Name = removeAt(mark)
	--创建用杀得标记技能
	local useSlashGetMark =  sgs.CreateTriggerSkill{
		name = "#loluseSlashGet"..Name,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.CardUsed},
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			local use = data:toCardUse()
			--你使用了【杀】获得标记，设已用【杀】flag，且清楚标记为0
			if use.from:objectName() == player:objectName() then
				if use.card:isKindOf("Slash") then 
					room:setPlayerMark(player,Name.."Clear",0)
					room:setPlayerFlag(player,Name)
					if player:getMark(mark) < max then
						player:gainMark(mark)
					end
				end
			end	
		end,	
	}
	--创建连续不用杀失去标记技能
	local noUseSlashLostMark = sgs.CreateTriggerSkill{
		name = "#noUseSlashLost"..Name,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.EventPhaseEnd},
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				if player:hasFlag(Name) then --已经用了【杀】就不能继续
					return false
				end
				room:addPlayerMark(player,Name.."Clear")
				if player:getMark(Name.."Clear") >= round then --没有使用杀的连续回合超过限制
					if player:getMark(mark) > 0 then
						player:loseMark(mark)
					end
					room:setPlayerMark(player,Name.."Clear",round-1) --标记数变为界限-1
				end
			end
		end,	
	}
	--返回
	return useSlashGetMark,noUseSlashLostMark
end

--自动清除标记，你只需要给武将添加一个这个函数返回的技能，然后武将每个回合结束就会自动清除time所代表的标记
--	(string）mark 标记的名字，比如“@mark”，“flag”等等
endRemoveMark = function(mark)
	local Name = removeAt(mark)
	local lolMark = sgs.CreateTriggerSkill{
		name = "#"..Name,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.EventPhaseEnd},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark(mark)>0 then
					player:loseMark(mark)
				end
			end
		end,	
	}
	return lolMark
end

--自动清除标记，你只需要给武将添加一个这个函数返回的技能，然后武将每个回合开始就会自动清除time所代表的标记
--	(string）mark 标记的名字，比如“@mark”，“flag”等等
startRemoveMark = function(mark)
	local Name = removeAt(mark)
	local lolMark = sgs.CreateTriggerSkill{
		name = "#"..Name,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.EventPhaseStart},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Start then
				if player:getMark(mark)>0 then
					player:loseMark(mark)
				end
			end
		end,	
	}
	return lolMark
end

--返回零牌无限制视为技能
--	(技能卡对象)skillcard, 视为的技能卡
ZeroVS = function(skillcard)
	local vsSkill = sgs.CreateZeroCardViewAsSkill{
		name = skillcard:objectName(),	
		view_as = function(self)
			local vs = skillcard:clone()
			vs:setSkillName(self:objectName())
			return vs
		end,	
	}
	return vsSkill
end

--返回每回合限制一次的零牌视为技
--	(技能卡对象)skillcard, 视为的技能卡
ZeroOnceTimeVS = function(skillcard)
	local Name = removeCardStr(skillcard)
	local VSskill = sgs.CreateZeroCardViewAsSkill{
		name = Name,
		view_as = function(self)
			local vs = skillcard:clone()
			vs:setSkillName(self:objectName())
			return vs
		end,
		enabled_at_play = function(self,player)
			return not player:hasUsed("#"..skillcard:objectName())
		end,	
	}
	return VSskill
end

--返回大招视为技能
--	(技能卡对象)skillcard, 视为的技能卡
--	(string)Rmark, 大招所需的标记
ZeroRVS = function(skillcard, Rmark)
	local Name = removeCardStr(skillcard)
	local VSskill = sgs.CreateZeroCardViewAsSkill{
		name = Name,
		view_as = function(self)
			local vs = skillcard:clone()
			vs:setSkillName(self:objectName())
			return vs
		end,
		enabled_at_play = function(self,player)
			return player:getMark(Rmark) > 0
		end,	
	}
	return VSskill
end

--返回单牌一次性视为技
--	(技能卡对象)skillcard, 视为的技能卡
-- 	(string)pattern_str, 卡牌要求
OneOnceTimeVS = function(skillcard, pattern_str)
	local Name = removeCardStr(skillcard)
	local VSskill = sgs.CreateOneCardViewAsSkill{
		name = Name,	
		filter_pattern = pattern_str,
		view_as = function(self,card)
			local to_copy = skillcard:clone()
			to_copy:addSubcard(card)
			to_copy:setSkillName(self:objectName())
			return to_copy
		end,
		enabled_at_play = function(self,player)
			return not player:hasUsed("#"..skillcard:objectName())
		end,
	}
	return VSskill
end

--以下技能有些是为了方便测试而添加的，有些武将的技能触发条件有些苛刻，用这些技能可以方便达成条件，
GMlist = {"lolGiveArmor","lolThrow","lolDraw","lolRecover","lolDamage","lolChange"}

--GM，让你的武将拥有GM之力
lolGM = sgs.CreateGameStartSkill{
	name = "#lolGM",
	frequeny = sgs.Skill_Compulsory,
	on_gamestart = function(self,player)
		local room = player:getRoom()
		for _,skill in ipairs(GMlist) do
			room:acquireSkill(player,skill)
		end
	end,
}

--给装备，类似二张直谏，不过不摸牌
lolGiveArmorCard = sgs.CreateSkillCard{
	name = "lolGiveArmor",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets ~= 0 or to_select:objectName() == player:objectName() then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	on_effect = function(self, effect)
		local player = effect.from
		player:getRoom():moveCardTo(self, player, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "lolGiveArmor", ""))
	end
}

lolGiveArmor = sgs.CreateOneCardViewAsSkill{
	name = "lolGiveArmor",	
	filter_pattern = "EquipCard|.|.|.",
	view_as = function(self, card)
		local vs_card = lolGiveArmorCard:clone()
		vs_card:addSubcard(card)
		vs_card:setSkillName(self:objectName())
		return vs_card
	end
}

--
lolRecoverCard = sgs.CreateSkillCard{
	name = "lolRecover",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return to_select:isWounded()
		end
	end,
	on_use = function(self,room,source,targets)		
		local recover = sgs.RecoverStruct()
		local target = targets[1]
		recover.who = source
		recover.recover = 1
		room:recover(target,recover)
	end,
}

--恢复，指定一名角色，令其回复1点体力
lolRecover = ZeroVS(lolRecoverCard)

--
lolDamageCard = sgs.CreateSkillCard{
	name = "lolDamage",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		return #targets == 0
	end,
	on_use = function(self,room,source,targets)		
		local target = targets[1]
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.damage = 1
		room:damage(damage)
	end,
}

--伤害，对一名角色造成1点伤害
lolDamage = ZeroVS(lolDamageCard)

--摸牌，指定一名角色，让他摸一张牌
lolDrawCard = sgs.CreateSkillCard{
	name = "lolDraw",	
	target_fixed = false,	 
	will_throw = false,filter = function(self,targets,to_select,player)
		return #targets == 0
	end,
	on_use = function(self,room,source,targets)		
		targets[1]:drawCards(1)
	end,
}

lolDraw = ZeroVS(lolDrawCard)

--
lolThrowCard = sgs.CreateSkillCard{
	name = "lolThrow",	
	target_fixed = false,	 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return not to_select:isKongcheng()
		end
	end,
	on_use = function(self,room,source,targets)		
		local target = targets[1]
		-- local card = room:askForCardChosen(source,target,"he",self:objectName())
		room:askForDiscard(target,self:objectName(),1,1)
	end,
}

--弃牌，你可弃置一名角色一张牌
lolThrow =	ZeroVS(lolThrowCard)

lolChangeCard = sgs.CreateSkillCard{
	name = "lolChangeCard",		
	target_fixed = false,	 
	will_throw = false,
	-- handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return to_select:objectName() ~= player:objectName()
		end
	end,
	on_use = function(self,room,source,targets)
		room:changeHero(targets[1], "Azir", true)
	end,
}	

lolChange = sgs.CreateZeroCardViewAsSkill{
	name = "lolChange",
	-- relate_to_place = deputy,	
	-- response_pattern = "",		
	view_as = function(self)
		return lolChangeCard:clone()
	end,
	enabled_at_play = function(self,player)
		return true
	end,
}

--
-- lolCardUseReason = sgs.CreateTriggerSkill{
-- 	name = "lolHah",	
-- 	frequeny = sgs.Skill_Frequent, 
-- 	events = {sgs.CardUsed,sgs.CardResponded},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		if event == sgs.CardResponded then
-- 			local response = data:toCardResponse()
-- 			if response.m_who then
-- 				response.m_who:gainMark("@card1")
-- 			end
-- 			if response.m_isUse then
-- 				player:gainMark("@card2")
-- 			end
-- 			if response.m_isRetrial then
-- 				player:gainMark("@card3")
-- 			end
-- 			if response.m_isHandcard then
-- 				player:gainMark("@card4")
-- 			end
-- 		end
-- 	end,
-- 	can_trigger = function(self,target)
-- 			return target
-- 		end	
-- }

---------------------------------------------------------------------------------------
--特殊效果技能，需要这些效果的武将直接添加，免得再写

--能添加护盾的武将需要添加这个隐藏技能，
--这个技能会为有"@Dun"标记的武将抵消伤害，是作用于所有角色的，也就是说你可以给其他武将添加"@Dun"标记
lolHuDun = sgs.CreateTriggerSkill{
	name = "#lolHuDun",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:getMark("@Dun")>0 then
			local count = damage.to:getMark("@Dun")
			if damage.damage <= count then
				damage.to:loseMark("@Dun",damage.damage)
				damage.damage = 0
			elseif damage.damage > count then
				damage.damage = damage.damage - count
				damage.to:loseAllMarks("@Dun")
			end
			data:setValue(damage)
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

--能添加魔法护盾的武将需要添加这个隐藏技能
--这个技能会为有"@Dun"标记的武将抵消【杀】以外的伤害，是作用于所有角色的，也就是说你可以给其他武将添加"@MoDun"标记
lolMoDun = sgs.CreateTriggerSkill{
	name = "#lolMoDun",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			return false
		end
		if damage.to and damage.to:getMark("@MoDun")>0 then
			local count = damage.to:getMark("@MoDun")
			if damage.damage <= count then
				damage.to:loseMark("@MoDun",damage.damage)
				damage.damage = 0
			elseif damage.damage > count then
				damage.damage = damage.damage - count
				damage.to:loseAllMarks("@MoDun")
			end
			data:setValue(damage)
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}


--穿甲，拥有这个技能，你的【杀】会无视防具
lolChuanJia = sgs.CreateTriggerSkill{
	name = "lolChuanJia",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.TargetConfirmed,sgs.CardFinished},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				if use.from:hasSkill(self:objectName()) then
					local targets = use.to
					for _,t in sgs.qlist(targets) do
						room:setPlayerMark(t,"Armor_Nullified",1)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local players = room:getAlivePlayers()
			for _,p in sgs.qlist(players) do
				if p:getMark("Armor_Nullified")>0 then
					room:setPlayerMark(p,"Armor_Nullified",0)
				end
			end
		end
	end,	
}

--暴击，如果你的武将有这个技能，那么他的【杀】，如果有"Baoji"这个flag，那么这张【杀】造车的伤害将+1
lolBaoJi = sgs.CreateTriggerSkill{
	name = "#lolBaoJi",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card then
			local card = damage.card
			if card:isKindOf("Slash") and card:hasFlag("BaoJi") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,	
}

--
lolDizzy = sgs.CreateTriggerSkill{
	name = "#lolDizzy",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		--有眩晕标记
		if player:getMark("@XuanYun") == 0 then
			return false
		end
		if player:getPhase() == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Play) then
				player:skip(sgs.Player_Play)
			end
			room:setPlayerMark(player,"@XuanYun",0)
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

lolImprison = sgs.CreateTriggerSkill{
	name = "#lolImprison",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		--有禁锢标记
		if player:getMark("@JinGu") == 0 then
			return false
		end
		if player:getPhase() == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Draw) then
				player:skip(sgs.Player_Draw)
			end
			room:setPlayerMark(player,"@JinGu",0)
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

--致盲，可以致盲别人的武将需要添加这个技能，你只需要给其他角色添加一个"blind"标记，他下个回合就无法出杀
lolBlind = sgs.CreateTriggerSkill{
	name = "lolBlind",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark("blind")>0 then
			room:setPlayerMark(player,"blind",0)
			room:setPlayerCardLimitation(player,"use","slash|.|.|.",true)
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

--------------------通用技能栏-------------------------

--暗降
Anjiang = sgs.General(extension,"anjiang","god",4,true,true,true)

--------------------通用技添加区-----------------------

Anjiang:addSkill(lolChuanJia)
Anjiang:addSkill(lolGiveArmor)
Anjiang:addSkill(lolDraw)
Anjiang:addSkill(lolThrow)
Anjiang:addSkill(lolDamage)
Anjiang:addSkill(lolRecover)
Anjiang:addSkill(lolChange)

--------------------通用技添加区-----------------------

--狗头
Nasus = sgs.General(extension,"Nasus","shu",4)

lolJihun = sgs.CreateTriggerSkill{
	name = "lolJihun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeachesDone,sgs.DamageCaused}, --求桃时
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		if event == sgs.AskForPeachesDone then -- 如果是求桃时
			local mode = room:getMode()
			if string.sub(mode, -1) == "p" or string.sub(mode, -2) == "pd" or string.sub(mode, -2) == "pz" then
				local dying = data:toDying() --濒死结构体
				if dying.damage then --如果存在伤害来源
					local killer = dying.damage.from -- 获取杀人者
					if not player:isLord() and player:getHp() <= 0 then -- 如果死的不死主公
						if killer:hasSkill(self:objectName()) or me:getMark("SishenTime")>0 then -- 如果凶手拥有这技能
							room:broadcastSkillInvoke(self:objectName())
							me:gainMark("@getSoul",1) -- 获得一枚汲魂标记
							room:notifySkillInvoke(player,self:objectName()) -- 看不懂		
						end
						return false
					end
				end
			end
		elseif event == sgs.DamageCaused then -- 如果是造成伤害时
			local room = player:getRoom()
			local damage = data:toDamage()
			if not damage.by_user then return false end -- 如果没有伤害来源，那就算了吧
			if damage.from and damage.card and damage.card:isKindOf("Slash") and damage.from:hasSkill(self:objectName()) then -- 若果是杀造成的伤害
				local count = damage.from:getMark("@getSoul") -- 获取标记数量
				if count>0 then
					room:notifySkillInvoked(damage.from,self:objectName())
				end
				damage.damage = damage.damage + count -- 增加伤害
				data:setValue(damage)
				room:broadcastSkillInvoke(self:objectName())
			end
			return false
		end
	end,
	can_trigger = function(self, target) 
		return target -- 其他角色回合也可发动
	end
}

lolSishenCard = sgs.CreateSkillCard{
	name = "lolSishenCard",	
	target_fixed = true,	 
	will_throw = false,
	on_use = function(self,room,source,targets)		
		room:setPlayerMark(source,"SishenTime",2)
		room:broadcastSkillInvoke("lolJihun")
		local mhp = sgs.QVariant()
		local count =source:getMaxHp()
		mhp:setValue(count+1)
		room:setPlayerProperty(source,"maxhp",mhp)
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(source,recover)
		source:drawCards(1)
		room:setPlayerMark(source,"@NasusR",0)
	end,
} 

lolSishen = ZeroRVS(lolSishenCard,"@NasusR")

lolSishenTime = startRemoveMark("SishenTime")

lolNasusR = getRMark("@NasusR")

Nasus:addSkill(lolJihun)
Nasus:addSkill(lolSishen)
Nasus:addSkill(lolSishenTime)
Nasus:addSkill(lolNasusR)

--索拉卡
Soroka = sgs.General(extension,"Soroka","wu",3,false)

lolJiushuCard = sgs.CreateSkillCard{
	name = "lolJiushuCard",
	filter = function(self,targets,to_select)
		-- 如果还没有选择角色，不能选择自己
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() then return false end
		return to_select:isWounded() -- 只能选择受伤角色
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		room:loseHp(effect.from) -- 发动者失去一点体力
		if effect.to:getLostHp() == 1 then -- 如果只伤了1血
			room:broadcastSkillInvoke("lolJiushu")
			local recover = sgs.RecoverStruct()
			recover.who = effect.from
			room:recover(effect.to,recover) -- 只回一血
		end
		if effect.to:getLostHp() >= 2 then -- 如果至少上了2血
			room:broadcastSkillInvoke("lolJiushu")
			local recover = sgs.RecoverStruct()
			recover.recover = 2
			recover.who = effect.from
			room:recover(effect.to,recover) -- 回两血
			room:broadcastSkillInvoke("lolJiushuCard")
		end
	end
}

lolJiushu = ZeroOnceTimeVS(lolJiushuCard)

lolQidao = sgs.CreateTriggerSkill{
	name = "lolQidao",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DamageCaused},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.card and damage.card:isNDTrick() then
			if not player:hasFlag(self:objectName()) then	
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player,recover)
				room:setPlayerFlag(self:objectName())
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,	
}

Soroka:addSkill(lolJiushu)
Soroka:addSkill(lolQidao)

--武器
Jax = sgs.General(extension,"Jax","qun",4)

lolZongshi = sgs.CreateTriggerSkill{
	name = "lolZongshi",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not
			 damage.chain and not damage.transfer and damage.from:hasSkill(self:objectName()) then
			 	room:broadcastSkillInvoke(self:objectName())
				player:gainMark("zongshi")
				player:drawCards(1)
			end
		end
	end,	
}

lolZongshiPlus = sgs.CreateTargetModSkill{
	name = "#lolZongshiPlus",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",	
	residue_func = function(self,player)
		return player:getMark("zongshi")
	end,
}

lolZongshiClear = sgs.CreateTriggerSkill{
	name = "#lolZongshiClear",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		room:setPlayerMark(player, "zongshi", 0)
	end,	
}

Jax:addSkill(lolZongshi)
Jax:addSkill(lolZongshiPlus)
Jax:addSkill(lolZongshiClear)

--猴子
Wukong = sgs.General(extension,"Wukong","qun",4)

lolQianbian = sgs.CreateTriggerSkill{
	name = "lolQianbian",
	events = {sgs.EventPhaseStart}, -- 阶段开始
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then -- 如果是结束阶段
			if player:isKongcheng() then return false end -- 要是没手牌就算了
			local hou = player:getPile("hou") -- 获取私有牌堆
			if hou:length() == 0 then -- 如果牌堆没牌
				-- 询问一张手牌
				if player:askForSkillInvoke(self:objectName(), data) then
					local card = room:askForCard(player,".|.|.|hand","@lolQianbian",sgs.QVariant(),sgs.Card_MethodNone)
					if card then 
						player:addToPile("hou",card,false) -- 加到牌堆里
						room:broadcastSkillInvoke(self:objectName())
					end
				end
			end
		end
	end,
}

lolWanhua = sgs.CreateTriggerSkill{
	name = "lolWanhua",
	events = {sgs.DamageCaused}, -- 什么鬼
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local me = room:findPlayerBySkillName(self:objectName())
		if damage.to:objectName() == me:objectName() then
			if damage.from and damage.from:objectName() ~= me:objectName() then
				local hou = me:getPile("hou")
				if hou:length() > 0 then
					if me:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local id = hou:first()
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuitString()
						room:throwCard(card, nil, nil)
						if suit == "heart" then
							room:loseHp(damage.from)
							return true
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

lolQitian = sgs.CreateTargetModSkill{
	name = "lolQitian",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self,player)
		if player:hasSkill(self:objectName()) then
			local x = player:getAttackRange(true) -- 获取攻击距离
			return x-1 -- 返回攻击距离-1
		else
			return 0
		end
	end
}

Wukong:addSkill(lolQianbian)
Wukong:addSkill(lolWanhua)
Wukong:addSkill(lolQitian)
--猪妹
Sejuani = sgs.General(extension,"Sejuani","qun",4,false)

lolHanyuCard = sgs.CreateSkillCard{
	name = "lolHanyuCard",
	target_fixed = false,
	will_throw = false,
	skill_name = "lolHanyu",
	filter = function(self,targets,to_select,player)
		if #targets == 0 and to_select:objectName() ~= player:objectName() then
			return to_select:getMark("@coldPrison") < 2
		end
	end,
	on_use = function(self,room,source,targets)	
		room:broadcastSkillInvoke("lolHanyu")
		local target = targets[1]
		local id = room:askForCardChosen(source,target,"he","lolHanyu")
		room:throwCard(id,target,source)
		target:gainMark("@coldPrison")
	end,
}

lolHanyu = sgs.CreateZeroCardViewAsSkill{
	name = "lolHanyu",
	view_as = function(self)
		local vs_card = lolHanyuCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		local total_count = 0
		local targets = player:getAliveSiblings()
		for _,target in sgs.qlist(targets) do
			total_count = total_count + target:getHandcardNum()
		end
		local limit_num = targets:length()*3
		return total_count > limit_num
	end,
}

lolHanyuPlus = sgs.CreateTriggerSkill{
	name = "#lolHanyuPlus",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local targets = room:getOtherPlayers(player)
			for _,target in sgs.qlist(targets) do
				if target:getMark("@coldPrison") > 0 then
					room:setPlayerMark(target,"@coldPrison",0)
				end
			end
		end
	end,	
}

Sejuani:addSkill(lolHanyu)
Sejuani:addSkill(lolHanyuPlus)

--吸血鬼
Vladimir = sgs.General(extension,"Vladimir","qun",4)

lolXueqi = sgs.CreateTriggerSkill{
	name = "lolXueqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.HpRecover}, -- 受伤时
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		if event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from:objectName() == me:objectName() or
			 damage.to:objectName() == me:objectName() then
				me:drawCards(damage.damage)
			end
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			if recover.who:objectName() == me:objectName() then
				player:drawCards(recover.recover)
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

Vladimir:addSkill(lolXueqi)

Lux = sgs.General(extension,"Lux","qun",3,false)

lolGuangfuCard = sgs.CreateSkillCard{
	name = "lolGuangfuCard",	
	target_fixed = false,	 
	will_throw = true,
	skill_name = "lolGuangfu",
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return not player:inMyAttackRange(to_select)
		end
	end,
	on_use = function(self,room,source,targets)		
		targets[1]:gainMark("@XuanYun")
		room:broadcastSkillInvoke("lolGuangfu")
	end,
	on_effect = function(self,effect)
		
	end,	
}

lolGuangfu = OneOnceTimeVS(lolGuangfuCard, "Slash|.")

lolQuguangCard = sgs.CreateSkillCard{
	name = "lolQuguangCard",	
	target_fixed = false,	 
	will_throw = true,
	skill_name = "lolQuguang",
	filter = function(self,targets,to_select,player)
		return #targets == 0 and to_select:getMark("@Dun") == 0
	end,
	on_use = function(self,room,source,targets)		
		targets[1]:gainMark("@Dun")
		room:broadcastSkillInvoke("lolQuguang")
	end,
}

lolQuguang = OneOnceTimeVS(lolQuguangCard, "EquipCard|.")

Lux:addSkill(lolGuangfu)
Lux:addSkill(lolQuguang)
Lux:addSkill(lolHuDun)
Lux:addSkill(lolDizzy)

Olaf = sgs.General(extension,"Olaf","shu",4)

lolZhushen = sgs.CreateTriggerSkill{
	name = "lolZhushen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:isWounded() then -- 如果我受伤了
			if player:askForSkillInvoke(self:objectName()) then
				local lose = player:getLostHp() -- 获取损失体力值
				local count = data:toInt() + lose - 1 -- 多摸损失体力值张牌-1
				data:setValue(count)
				room:broadcastSkillInvoke(self:objectName())
			end
		end
	end,
}

lolZhushenPlus = sgs.CreateTargetModSkill{
	name = "#lolZhushenPlus",
	frequency = sgs.Skill_NotFrequent,
	residue_func = function(self,player)
		if player:hasSkill(self:objectName()) then
			local lose = player:getLostHp() -- 获取损失体力值
			return lose - 1  -- 返回损失体力值-1
		else
			return 0
		end
	end
}

Olaf:addSkill(lolZhushen)
Olaf:addSkill(lolZhushenPlus)

Twisted = sgs.General(extension,"Twisted","wei",3)

lolMingyunPlus = sgs.CreateTriggerSkill{
	name = "#lolMingyunPlus",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "start" then
			if player:getMark("@cardBlue") > 0 then
				player:loseMark("@cardBlue")
				player:gainMark("@cardRed")
				player:loseMark("@cardYellow")
			elseif player:getMark("@cardRed") > 0 then
				player:loseMark("@cardBlue")
				player:loseMark("@cardRed")
				player:gainMark("@cardYellow")
			else
				player:gainMark("@cardBlue")
				player:loseMark("@cardRed")
				player:loseMark("@cardYellow")
			end
		end
	end,	
}

lolXuanpai = sgs.CreateOneCardViewAsSkill{
	name = "lolXuanpai",
	view_filter = function(self,card)
		local suit = nil
		if sgs.Self:hasFlag("lolMingyunBlue") then
			suit = "spade"
		elseif sgs.Self:hasFlag("lolMingyunRed") then
			suit = "diamond"
		elseif sgs.Self:hasFlag("lolMingyunYellow") then
			suit = "heart"
		end
		return card:getSuitString() == suit
	end,
	view_as = function(self,card)
		local suit_str = card:getSuitString()
		local suit = card:getSuit()
		local number = card:getNumber()
		local to_copy = nil
		if suit_str == "heart" then
			to_copy = sgs.Sanguosha:cloneCard("ex_nihilo", suit, number)
		elseif suit_str == "spade" then
			to_copy = sgs.Sanguosha:cloneCard("dismantlement", suit, number)
		elseif suit_str == "diamond" then
			to_copy = sgs.Sanguosha:cloneCard("indulgence", suit, number)
		end
		if to_copy then
			to_copy:addSubcard(card)
			to_copy:setSkillName(self:objectName())
		end
		return to_copy
	end,
}

lolMingyunCard = sgs.CreateSkillCard{
	name = "lolMingyunCard",	
	target_fixed = true,	 
	will_throw = false,
	filter = function(self,targets,to_select,player)
		return true
	end,
	on_use = function(self,room,source,targets)		
		if source:getMark("@cardBlue") > 0 then
			source:loseMark("@cardBlue")
			room:setPlayerFlag(source, "lolMingyunBlue")
		elseif source:getMark("@cardRed") > 0 then
			source:loseMark("@cardRed")
			room:setPlayerFlag(source, "lolMingyunRed")
		elseif source:getMark("@cardYellow") > 0 then
			source:loseMark("@cardYellow")
			room:setPlayerFlag(source, "lolMingyunYellow")
		end
		room:broadcastSkillInvoke("lolMingyun")
	end,
}

lolMingyun = sgs.CreateZeroCardViewAsSkill{
	name = "lolMingyun",
	view_as = function(self)
		local vs_card = lolMingyunCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolMingyunCard")
	end,
}

Twisted:addSkill(lolMingyun)
Twisted:addSkill(lolMingyunPlus)
Twisted:addSkill(lolXuanpai)

Udyr = sgs.General(extension,"Udyr","wei",4)
Udyr_tiger = sgs.General(extension,"Udyr_tiger","qun",4,true,true,true)
Udyr_turtle = sgs.General(extension,"Udyr_turtle","wu",4,true,true,true)
Udyr_bear = sgs.General(extension,"Udyr_bear","wei",4,true,true,true)
Udyr_Phoenix = sgs.General(extension,"Udyr_Phoenix","shu",4,true,true,true)

Udyr_tiger:addSkill("nostieji")
Udyr_turtle:addSkill("bazhen")
Udyr_bear:addSkill("nosguose")
Udyr_Phoenix:addSkill("huoji")

lolSiling = sgs.CreateTriggerSkill{
	name = "lolSiling",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.FinishJudge},	
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		-- 开始阶段开始时
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				-- 询问触发技能
				if player:askForSkillInvoke(self:objectName(),data) then
					-- 建立判定结构体
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.reason = self:objectName()
					judge.play_animation = false
					room:judge(judge)  -- 进行判定
				end
			end
		-- 判定完成时
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()  -- 获取判定结构体
			-- 如果时此技能发动的判定
			if judge.reason == self:objectName() then
					-- 获取判定牌花色
				local card = judge.card 
				local suit = card:getSuit()
				-- 依据相应的花色变成相应形态的乌迪尔
				if suit == sgs.Card_Spade then
					room:changeHero(player,"Udyr_tiger",false,false,false,false)
					room:broadcastSkillInvoke("lolUtiger")
				elseif suit == sgs.Card_Heart then
					room:changeHero(player,"Udyr_turtle",false,false,false,false)
					room:broadcastSkillInvoke("lolUturtle")
				elseif suit == sgs.Card_Club then
					room:changeHero(player,"Udyr_bear",false,false,false,false)
					room:broadcastSkillInvoke("lolUbear")
				elseif suit == sgs.Card_Diamond then
					room:changeHero(player,"Udyr_Phoenix",false,false,false,false)
					room:broadcastSkillInvoke("lolUphoenix")
				end
			end
		end
	end,
}

--音效技能
siling = function(skill_name)
	local lolskill = sgs.CreateTriggerSkill{
		name = skill_name,	
		frequeny = sgs.Skill_Frequent, 
		events = {sgs.EventPhaseEnd},
		-- view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
		end,
	}
	return lolskill
end

lolUtiger = siling("lolUtiger")
lolUturtle = siling("lolUturtle")
lolUbear = siling("lolUbear")
lolUphoenix = siling("lolUphoenix")

Anjiang:addSkill(lolUphoenix)
Anjiang:addSkill(lolUbear)
Anjiang:addSkill(lolUtiger)
Anjiang:addSkill(lolUturtle)

Udyr_tiger:addSkill(lolSiling)
Udyr_turtle:addSkill(lolSiling)
Udyr_bear:addSkill(lolSiling)
Udyr_Phoenix:addSkill(lolSiling)
Udyr:addSkill(lolSiling)

Azir = sgs.General(extension,"Azir$","shu",3)

lolShabingCard = sgs.CreateSkillCard{
	name = "lolShabingCard",
	target_fixed = true,	 
	will_throw = true,
	-- handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		return true
	end,
	on_use = function(self,room,source,targets)	
		local id = room:askForCardChosen(source, source, "h", self:objectName())
		source:addToPile("solder", id)
	end,
}

lolShabing = sgs.CreateZeroCardViewAsSkill{
	name = "lolShabing",		
	view_as = function(self)
		local vs = lolShabingCard:clone()
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self,player)
		return player:getPile("solder"):length() == 0		
	end,
}

lolShabingPassive = sgs.CreateTriggerSkill{
	name = "#lolShabingPassive",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "finish" then
			local handlist = player:getHandcards()
			local pilelist = player:getPile("solder")
			if handlist:length() > 0 then
				for _, hand in sgs.qlist(handlist) do
					player:addToPile("solder", hand, false)
				end
			end
			if pilelist:length() then
				for _, pile in sgs.qlist(pilelist) do
					room:obtainCard(player, pile, false)
				end
			end
			if player:getMark("@solder") == 0 then  -- 第一个回合，没有标记
				room:setPlayerMark(player, "@solder", 1)
				player:gainAnExtraTurn()
			else
				room:setPlayerMark(player, "@solder", 0)
			end
		end
	end,	
}

lolShabingMax = sgs.CreateMaxCardsSkill{
	name = "#lolShabingMax",
	extra_func = function(self,player)
		-- 手牌上限是跟血量挂钩的
		local num = player:getHp()
		if player:getMark("@solder")>0 then
			return 1 - num
		end
	end
}

lolFuxing = sgs.CreateMaxCardsSkill{
	name = "lolFuxing",
	extra_func = function(self,player)
		local count = 0
		local targets = player:getAliveSiblings()
		for _, target in sgs.qlist(targets) do
			if target:getKingdom() == "shu" then
				count = count + 1
			end
		end
		if player:getMark("@solder")>0 and player:isLord() then
			return count
		end
	end
}

Azir:addSkill(lolShabing)
Azir:addSkill(lolShabingPassive)
Azir:addSkill(lolShabingMax)
Azir:addSkill(lolFuxing)

-- lolJingeCard = sgs.CreateSkillCard{
-- 	name = "lolJingeCard",	
-- 	target_fixed = false,	 -- 需要指定目标
-- 	will_throw = false, -- 不弃置，还要交给目标
-- 	handling_method = sgs.Card_MethodNone,
-- 	filter = function(self,targets,to_select,player)
-- 		if #targets == 0 then
-- 			return player:inMyAttackRange(to_select) -- 在我的攻击范围内
-- 		end
-- 	end,
-- 	on_use = function(self,room,source,targets)		
-- 		local target = targets[1] -- 第一个目标
-- 		target:obtainCard(self) -- 获得这张牌
-- 		-- 呼唤目标使用一张杀
-- 		local use = room:askForUseCard(target,"Slash|.|.|.|.","@lolJinge")
-- 		-- 如果目标不杀且有手牌，获得其一张手牌
-- 		if not use and not target:isKongcheng() then 
-- 			local id = room:askForCardChosen(source,target,"h",self:objectName())
-- 			room:obtainCard(source,id,false)
-- 		end
-- 	end,
-- 	on_effect = function(self,effect)
-- 	end,	
-- }	

-- lolJinge = sgs.CreateViewAsSkill{
-- 	name = "lolJinge",
-- 	relate_to_place = deputy,	
-- 	response_pattern = "",
-- 	n = 1 , -- 一张牌
-- 	view_filter = function(self,selected,to_select)
-- 		if #selected == 0 then
-- 			return to_select:isKindOf("Slash") -- 杀
-- 		end
-- 	end,
-- 	view_as = function(self,cards)
-- 		if #cards ~= 1 then return nil end -- 如果选择的不是一张牌，就无法发动
-- 		local jingecard = lolJingeCard:clone() -- 视为技能牌
-- 		jingecard:addSubcard(cards[1])
-- 		return jingecard
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		return not player:hasUsed("#lolJingeCard") -- 每回合只能用一次
-- 	end,
-- 	enabled_at_response = function(self,player,pattern)
		
-- 	end,		
-- }

-- lolTiema = sgs.CreateTriggerSkill{
-- 	name = "lolTiema",	
-- 	frequeny = sgs.Skill_NotFrequent, 
-- 	events = {sgs.Damaged},
	
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local damage = data:toDamage()
-- 		if damage.to:hasSkill(self:objectName()) and damage.to:askForSkillInvoke(self:objectName(),data) then
-- 			local lose = damage.to:getLostHp()
-- 			damage.to:drawCards(lose,self:objectName())
-- 		end	
-- 	end,	
-- }

-- lolFuxingEx = sgs.CreateTriggerSkill{
-- 	name = "#lolFuxingEx$",	
-- 	frequeny = sgs.Skill_Compulsory, 
-- 	events = {sgs.EventPhaseChanging},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local change = data:toPhaseChange()
-- 		local me = room:findPlayerBySkillName(self:objectName())
		
-- 		if change.to == sgs.Player_NotActive then
-- 			if not player:hasSkill(self:objectName()) and player:getKingdom() == "shu" then
-- 				local playerdata = sgs.QVariant()
-- 				playerdata:setValue(me)
-- 				room:setTag("lolFuxingTarget",playerdata)
-- 			end
-- 		end
		
-- 	end,	
-- 	can_trigger = function(self,target)
-- 		return target
-- 	end
-- }

-- lolFuxing = sgs.CreateTriggerSkill{
-- 	name = "lolFuxing$",	
-- 	frequeny = sgs.Skill_Compulsory, 
-- 	events = {sgs.EventPhaseStart},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		if room:getTag("lolFuxingTarget") then
-- 			local target = room:getTag("lolFuxingTarget"):toPlayer()
-- 			room:removeTag("lolFuxingTarget")
-- 			if target and target:isAlive() then
-- 				target:gainAnExtraTurn()
-- 			end
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self,target)
-- 			return target and (target:getPhase() == sgs.Player_NotActive)
-- 		end	
-- }

-- Azir:addSkill(lolJinge)
-- Azir:addSkill(lolTiema)
-- Azir:addSkill(lolFuxing)
-- Azir:addSkill(lolFuxingEx)

Kaisa = sgs.General(extension,"Kaisa","wei",3,false)

lolSuodi = sgs.CreateTriggerSkill{
	name = "lolSuodi",	
	frequeny = sgs.Skill_NotCompulsory, 
	events = {sgs.TargetConfirmed}, --卡牌指定角色后
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		
		local use = data:toCardUse() 
		if player:objectName() == use.from:objectName() then --如果你是使用者
			--多几个条件确定你时卡莎
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local dTrick = use.card
				--使用的牌时兵粮寸断或者乐不思蜀
				if dTrick:isKindOf("Indulgence") or dTrick:isKindOf("SupplyShortage") then
					--因为目标是列表，所以需要遍历
					for _,p in sgs.qlist(use.to) do
						--将角色设置进环境值里
						local ai_data = sgs.QVariant()
						ai_data:setValue(p)
						--询问触发技能
						if player:askForSkillInvoke(self:objectName(), ai_data) then
							--设置与目标角色距离始终为1
							room:setFixedDistance(player,p,1)
							room:broadcastSkillInvoke("lolSuodi")
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

lolChaozai = sgs.CreateTriggerSkill{
	name = "lolChaozai",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		--如果是出牌阶段
		if player:getPhase() == sgs.Player_Play then
			--如果你没有手牌
			if not player:isKongcheng() and player:getPile("HeavyRain"):length() == 0
				--触发技能
				and player:askForSkillInvoke(self:objectName(),data) then
				room:broadcastSkillInvoke("lolChaozai")
				--获取手牌列表
				local cards = player:getCards("h")
				--你弃掉的手牌里每有一张红色牌
				for _,c in sgs.qlist(cards) do
					if c:isRed() then
						--获得一枚标记
						-- player:gainMark("HeavyRain")
						player:addToPile("HeavyRain", c, true)
					end
				end
			end
		end
	end,	
}

lolBaoyu = sgs.CreateOneCardViewAsSkill{
	name = "lolBaoyu",
	expand_pile = "HeavyRain",
	view_filter = function(self,card)
		return sgs.Self:getPileName(card:getId()) == "HeavyRain"
	end,
	view_as = function(self,card)
		local to_copy = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		to_copy:addSubcard(card)
		to_copy:setSkillName(self:objectName())
		return to_copy
	end,
	enabled_at_play = function(self,player)
		return player:getPile("HeavyRain"):length() > 0
	end,		
}

-- lolBaoyuClear = sgs.CreateTriggerSkill{
-- 	name = "#lolBaoyuClear",
-- 	frequeny = sgs.Skill_Compulsory,
-- 	events = {sgs.EventPhaseEnd},
-- 	--view_as_skill = lolBaoyu,
-- 	on_trigger = function(self,event,player,data)
-- 		if player:getPhaseString() == "finish" then
-- 			player:clearOnePrivatePile("HeavyRain")
-- 			room:setPlayerMark(player, "HeavyRain", 0)
-- 		end
-- 	end,
-- }

lolBaoyuPlus = sgs.CreateTargetModSkill{
	name = "#lolBaoyuPlus",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",	
	residue_func = function(self,player)
		return player:getPile("HeavyRain"):length()
	end,
}

Kaisa:addSkill(lolSuodi)
Kaisa:addSkill(lolChaozai)
Kaisa:addSkill(lolBaoyu)
-- Kaisa:addSkill(lolBaoyuClear)
Kaisa:addSkill(lolBaoyuPlus)

Ornn = sgs.General(extension,"Ornn","wei",4)

lolZhongsheng = sgs.CreateTriggerSkill{
	name = "lolZhongsheng",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.BeforeCardsMove},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		--卡牌移动且不是你的牌并且有装备区的牌而且这些牌要被弃掉
		if move.from and move.from:objectName() ~= player:objectName()
			and player:hasSkill(self:objectName())
			and player:isAlive()
			and move.from_places:contains(sgs.Player_PlaceEquip) 
			and move.to_place == sgs.Player_DiscardPile then
			for i = 0 ,move.card_ids:length()-1,1 do --遍历这些卡牌
				if not move.from:isAlive() then return false end --如果来源死了就算了
				-- 如果是装备区的牌且你正面朝上
				if move.from_places:at(i) == sgs.Player_PlaceEquip
					and player:faceUp() then
					if room:askForSkillInvoke(player,self:objectName()) then
						room:broadcastSkillInvoke("lolZhongsheng")
						player:turnOver() -- 翻面
						-- 修改卡牌移动结构体，获得这张牌
						move.to_place = sgs.Player_PlaceHand
						move.to = player
						data:setValue(move)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}

lolPingdengCard = sgs.CreateSkillCard{
	name = "lolPingdengCard",	
	target_fixed = false,	 
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return #targets == 0
	end,
	on_use = function(self,room,source,targets)	
		-- 你和目标翻面，目标角色获得一张牌
		room:broadcastSkillInvoke("lolPingdeng")
		source:turnOver()
		targets[1]:turnOver()
		targets[1]:drawCards(1)
	end,
}

lolPingdeng = sgs.CreateOneCardViewAsSkill{
	name = "lolPingdeng",
	view_filter = function(self,card)
		return true
	end,
	view_as = function(self,card)
		local to_copy = lolPingdengCard
		to_copy:addSubcard(card)
		to_copy:setSkillName(self:objectName())
		return to_copy
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolPingdengCard")
	end,
}

Ornn:addSkill(lolZhongsheng)
Ornn:addSkill(lolPingdeng)

newGaren = sgs.General(extension,"newGaren","wei",4)

lolnewJianren = sgs.CreateTriggerSkill{
	name = "lolnewJianren",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then -- 回合开始
			-- 若你已受伤且有被动在
			if player:isWounded() and player:getMark("@Firm") > 0 then
				room:broadcastSkillInvoke(self:objectName())
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player,recover) --恢复一点体力
			end
		elseif player:getPhase() == sgs.Player_Finish then -- 回合结束
			if player:getMark("@Firm") == 0 then -- 若你没有被动
				player:gainMark("@Firm") -- 你重新获得被动
			end
		end
	end,	
}

lolnewJianrenPasstive = sgs.CreateTriggerSkill{
	name = "#lolnewJianrenPasstive",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		-- 你受到伤害便失去被动
		if damage.to:objectName() == player:objectName() then
			if player:getMark("@Firm") > 0 then
				player:loseMark("@Firm")
			end
		end
	end,	
}

lolnewJianrenStart = sgs.CreateTriggerSkill{
	name = "#lolnewJianrenStart",	
	events = {sgs.GameStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		player:gainMark("@Firm")
	end,	
}	

lolNZhengyiCard = sgs.CreateSkillCard{
	name = "lolNZhengyiCard",	
	target_fixed = false,	 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return true
		end
	end,
	on_use = function(self,room,source,targets)	
		room:broadcastSkillInvoke("lolNZhengyi")	
		local target = targets[1]
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.damage = 1
		if target:getMaxHp()-target:getHp()>=3 then
			damage.damage = 2
		end
		room:damage(damage)
		room:setPlayerMark(source, "@Garen_R", 0)
	end,
}

lolNZhengyi = sgs.CreateViewAsSkill{
	name = "lolNZhengyi",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolNZhengyiCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@Garen_R")>0
	end,		
}

lolGarenR = getRMark("@Garen_R")

newGaren:addSkill(lolnewJianren)
newGaren:addSkill(lolnewJianrenPasstive)
newGaren:addSkill(lolnewJianrenStart)
newGaren:addSkill(lolNZhengyi)
newGaren:addSkill(lolGarenR)

Skarner = sgs.General(extension,"Skarner","qun",4)

Jiatenghui = sgs.General(extension,"Jiatenghui","qun",3,false,true,true)
Yinglili = sgs.General(extension,"Yinglili","qun",3,false,true,true)
Shiyu = sgs.General(extension,"Shiyu","qun",3,false,true,true)
Meizhiliu = sgs.General(extension,"Meizhiliu","qun",3,false,true,true)

Jiatenghui:addSkill("luoshen")
Jiatenghui:addSkill("qingguo")
Yinglili:addSkill("xiaoji")
Yinglili:addSkill("zhenlie")
Shiyu:addSkill("biyue")
Shiyu:addSkill("")
Meizhiliu:addSkill("shenxian")
Meizhiliu:addSkill("nosqicai")

-- card_id就是随机获取的卡牌的id

lolJinlile = sgs.CreateTriggerSkill{
	name = "lolJinlile",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.GameStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		targets = {}
		-- 加入选择武将的名字对象
		table.insert(targets,Yinglili:objectName())
		table.insert(targets,Jiatenghui:objectName())
		table.insert(targets,Shiyu:objectName())
		table.insert(targets,Meizhiliu:objectName())
		-- 变换一下格式
		targets = table.concat(targets,"+")
		-- 人品测试机
		local renpin = {1,2,3,4,3,2,1}
		local rp = renpin[math.random(1,7)]
		for i=1,rp,1 do
			local general = room:askForGeneral(player,targets)
			local target = sgs.Sanguosha:getGeneral(general)
			local skills = target:getVisibleSkillList()
			local skillnames = {} -- 用于记录真正技能的名字的表
			for _,skill in sgs.qlist(skills) do
				local skillname = skill:objectName() -- 获得技能名
				if not player:hasSkill(skillname) then
					table.insert(skillnames,skillname) -- 记录技能名字
				end
			end
			-- 选择技能
			local choices = table.concat(skillnames,"+")
			local skill = room:askForChoice(player,"lolJinlile",choices)
			-- 添加技能
			room:acquireSkill(player,skill,true)
		end
		room:detachSkillFromPlayer(player, self:objectName())
		room:broadcastSkillInvoke("lolJinlile")
	end,	
}

Skarner:addSkill(lolJinlile)

Malzahar = sgs.General(extension,"Malzahar","shu",3)

lolMingfu = sgs.CreateViewAsSkill{
	name = "lolMingfu",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolMingfuCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@Sheol") >= 1
	end,	
}

Anjiang:addSkill(lolMingfu)

lolMingfuStart = sgs.CreateTriggerSkill{
	name = "#lolMingfuStart",	 
	events = {sgs.GameStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		player:gainMark("@Sheol")
	end,	
}

lolMingfuCard = sgs.CreateSkillCard{
	name = "lolMingfuCard",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return not to_select:hasSkill("lolMingfu")
		end
	end,
	on_use = function(self,room,source,targets)	
		room:broadcastSkillInvoke("lolMalzahar")	
		local target = targets[1]
		local skills = target:getVisibleSkillList()
		room:setPlayerMark(source, "@Sheol", 0)
		detachList = {}	
		for _,skill in sgs.qlist(skills) do
			if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() then
				table.insert(detachList,"-"..skill:objectName())
			end
		end
		room:handleAcquireDetachSkills(target, table.concat(detachList,"|"))
		room:broadcastSkillInvoke("lolMingfu")
		room:acquireSkill(target,"lolMingfu")
		target:gainMark("@Sheol")
	end,
}

lolChongqun = sgs.CreateTriggerSkill{
	name = "lolChongqun",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.DrawNCards},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local players = room:getAlivePlayers()
		local n = 0
		for _,p in sgs.qlist(players) do
			if p:hasSkill(lolMingfu:objectName()) then
				n = n + 1
			end
		end
		local count = data:toInt() + n
		data:setValue(count)
		room:broadcastSkillInvoke("lolMalzahar")
	end,	
}

Malzahar:addSkill(lolMingfuStart)
Malzahar:addSkill(lolMingfu)
Malzahar:addSkill(lolChongqun)

Draven = sgs.General(extension,"Draven","wei",3)

lolLianmeng = sgs.CreateTriggerSkill{
	name = "lolLianmeng",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if card:isKindOf("Slash") and not card:isVirtualCard() then
			local id = card:getId()
			local color = ""
			if card:isRed() then
				color = "red"
			elseif card:isBlack() then
				color = "black"
			end
			if player:askForSkillInvoke(self:objectName(),data) then
				room:addPlayerHistory(player, card:getClassName(), -1)
				local judge = sgs.JudgeStruct()
				judge.who = player
				judge.pattern = ".|"..color
				judge.good = true
				judge.reason = self:objectName()
				room:judge(judge)
				if judge:isGood() then
					room:broadcastSkillInvoke("lolLianmeng")
					player:addToPile("league", card, true)
				end
			end
		end
	end,	
}

lolLianmengPlus = sgs.CreateTriggerSkill{
	name = "#lolLianmengPlus",	
	frequeny = sgs.Skill_Compulsory,	 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "finish" then
			local card_ids = player:getPile("league")
			if card_ids:length() > 0 then
				for _, id in sgs.qlist(card_ids) do
					room:obtainCard(player,id,true)
				end
			end
		end
	end,	
}	

lolRongyu = sgs.CreateTriggerSkill{
	name = "lolRongyu",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.AskForPeachesDone},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		if not dying.damage.from then
			return false
		end
		if player:getHp()>0 then
			return false
		end
		local killer = dying.damage.from
		if not killer:hasSkill(self:objectName()) then
			return false
		end
		killer:drawCards(3)
		local card_ids = killer:getPile("league")
		if card_ids:length() > 0 then
			for _, id in sgs.qlist(card_ids) do
				room:obtainCard(killer, id, true)
			end
		end
		room:broadcastSkillInvoke("lolRongyu")
	end,
	can_trigger = function(self,target)
		return target
	end
}

Draven:addSkill(lolLianmeng)
Draven:addSkill(lolLianmengPlus)
Draven:addSkill(lolRongyu)

Yasuo = sgs.General(extension,"Yasuo","qun",4)

lolLangke = sgs.CreateTriggerSkill{
	name = "lolLangke",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		if not me:isAlive() then
			return false
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if me:getPhase() == sgs.Player_NotActive then
				return false
			end
			if not player:objectName() == me:objectName() then
				return false
			end
			if me:hasFlag("windBlade") then
				return false
			end
			me:gainMark("windBlade")
			if me:getMark("windBlade") >= 3 then
				me:speak("哈撒给")
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(me,"windBlade",0)
				local targets = room:getOtherPlayers(me)
				local target = room:askForPlayerChosen(me,targets,self:objectName())
				room:askForDiscard(target,self:objectName(),2,2)
				room:setPlayerFlag(me,"windBlade")
			end
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if player:objectName() == me:objectName() then
				me:gainMark("@Yasuo_E")
				room:broadcastSkillInvoke(self:objectName())
				if me:getMark("@Yasuo_E") >= 3 then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(me,"@Yasuo_E",0)
					me:drawCards(2)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if me:getPhase() == sgs.Player_Play then
				room:setPlayerMark(me,"windBlade",0)
			end
		end
	end,
}

-- lolFengzhan = sgs.CreateTriggerSkill{ 
-- 	name = "lolFengzhan",	
-- 	frequeny = sgs.Skill_Frequent, 
-- 	events = {sgs.CardsMoveOneTime},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local me = room:findPlayerBySkillName(self:objectName())
-- 		local move = data:toMoveOneTime()
-- 		if me:getMark("@YasuoR") > 0 then
-- 			if move.is_last_handcard and move.from:objectName() ~= me:objectName() then
-- 			--击飞效果是一个reson为"Diaup"的判定，判定成功则视为判定角色被击飞
-- 				if me:askForSkillInvoke(self:objectName(), data) then
-- 					move.from:setFlags( self:objectName() )
	
-- 					for _, target in sgs.qlist( room:getAlivePlayers() ) do
-- 						-- player:speak( target:getFlags() ) 
-- 						if target:hasFlag( self:objectName() ) then
-- 							room:broadcastSkillInvoke("lolLangke")
-- 							me:speak("痛里牙个痛")
-- 							me:gainMark("@Dun")
-- 							room:setPlayerMark(me, "@YasuoR", 0)
-- 							local damage = sgs.DamageStruct()
-- 							damage.from = me
-- 							damage.to = target
-- 							damage.damage = 1
-- 							room:damage(damage)
-- 							room:setFixedDistance(me, target, 1)
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end,	
-- }

-- lolYasuoR = getRMark("@YasuoR")

Yasuo:addSkill(lolLangke)
-- Yasuo:addSkill(lolFengzhan)
-- Yasuo:addSkill(lolYasuoR)
-- Yasuo:addSkill(lolHuDun)

Sion = sgs.General(extension,"Sion","shu",4)

lolRonghunCard = sgs.CreateSkillCard{
	name = "lolRonghunCard",	
	target_fixed = true,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		source:gainMark("@Dun",1)
		room:loseHp(source,1)
		room:broadcastSkillInvoke("lolRonghun")
	end,	
}

lolRonghun = sgs.CreateViewAsSkill{
	name = "lolRonghun",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolRonghunCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolRonghunCard") and player:getMark("@Dun")==0
	end,
}

lolRonghunPassive = sgs.CreateTriggerSkill{
	name = "#lolRonghunPassive",
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirmed,sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then
				return false
			end
			if use.from:hasSkill(self:objectName()) and
			 player:objectName() == use.from:objectName() and
			 player:getMark("@Dun")>0 then
				local targets = use.to
				for _,t in sgs.qlist(targets) do
					-- t:setCardLimitation("response,use","Jink|diamond|.|.|.",true)
					room:setPlayerCardLimitation(t, "use,response", "Jink|diamond|.|.", true)
				end
			end
		end			
	end,	
}

lolZhuhunCard = sgs.CreateSkillCard{
	name = "lolZhuhunCard",	
	target_fixed = true,
	will_throw = true,
	skill_name = "lolZhuhun",
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("lolZhuhun")
		local mhp = sgs.QVariant()
		local count =source:getMaxHp()
		mhp:setValue(count+1)
		room:setPlayerProperty(source,"maxhp",mhp)
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(source,recover)
	end,	
}

lolZhuhun = sgs.CreateViewAsSkill{
	name = "lolZhuhun",
	--relate_to_place = deputy,	
	--response_pattern = "peach",
	n = 1,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return to_select:isKindOf("Peach")
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return false
		end
		local vs_card = lolZhuhunCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:isWounded()
	end,	
}

Sion:addSkill(lolRonghun)
Sion:addSkill(lolRonghunPassive)
Sion:addSkill(lolZhuhun)
Sion:addSkill(lolHuDun)

Kassadin = sgs.General(extension,"Kassadin","wei",4)

lolXuwuCard = sgs.CreateSkillCard{
	name = "lolXuwuCard",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return true
		end
	end,
	on_use = function(self,room,source,targets)		
		room:broadcastSkillInvoke("lolXuwu")
		local target = targets[1]
		target:gainMark("@skill_invalidity")
		room:setPlayerFlag(target,"lolXuwu")
		if source:getMark("@MoDun") < 2 then
			room:setPlayerMark(source, "@MoDun", 2)
		end
	end,	
}

lolXuwu = sgs.CreateViewAsSkill{
	name = "lolXuwu",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolXuwuCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolXuwuCard")
	end,
}

lolKassadinClear = sgs.CreateTriggerSkill{
	name = "#lolKassadinClear",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			players = room:getAlivePlayers()
			for _,p in sgs.qlist(players) do
				if p:hasFlag("lolXuwu") and p:getMark("@skill_invalidity")>0 then
					-- 减少一张我赋予的技能禁止标记
					p:loseMark("@skill_invalidity")
					room:setPlayerFlag(p,"-lolXuwu")
				end
			end
		end
	end,
}

-- lolXuxingCard = sgs.CreateSkillCard{
-- 	name = "lolXuxingCard",	
-- 	target_fixed = true,	 
-- 	will_throw = true,
-- 	--handling_method = sgs.Card_MethodNone,
-- 	on_use = function(self,room,source,targets)		
-- 		room:broadcastSkillInvoke("lolKassadin")
-- 		source:gainMark("voidWalk")
-- 		source:speak("1")
-- 	end,	
-- }

-- lolXuxing = sgs.CreateViewAsSkill{
-- 	name = "lolXuxing",
-- 	--relate_to_place = deputy,	
-- 	--response_pattern = "",
-- 	n = 1,
-- 	view_filter = function(self,selected,to_select)
-- 		if #selected == 0 then
-- 			return true
-- 		end
-- 	end,
-- 	view_as = function(self,cards)
-- 		if #cards == 0 then
-- 			return nil
-- 		end
-- 		local vs_card = lolXuxingCard:clone()
-- 		vs_card:addSubcard(cards[1])
-- 		vs_card:setSkillName(self:objectName())
-- 		return vs_card
-- 	end,		
-- }

lolXuxing = sgs.CreateDistanceSkill{
	name = "lolXuxing",
	correct_func = function(self,from,to)
		if from:hasSkill(self:objectName()) then
			return -999
		end
	end
}

lolXuren = sgs.CreateTriggerSkill{
	name = "lolXuren",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.TargetConfirmed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from:hasSkill(self:objectName()) and
			 use.from:objectName() == player:objectName() then
				if use.card:isNDTrick() then
					local to = use.to:first()
					if to:objectName() == player:objectName() or 
					 player:hasFlag(self:objectName()) then
						return false
					end
					if player:askForSkillInvoke(self:objectName(),data) then
						room:broadcastSkillInvoke("lolXuren")
						room:setPlayerFlag(player, self:objectName())
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = to
						damage.damage = 1
						room:damage(damage)
						local nullified = use.nullified_list
						table.insert(nullified,to:objectName())
						use.nullified_list = nullified
						data:setValue(use)
					end
				end
			end
		end
	end,	
}

Kassadin:addSkill(lolXuwu)
Kassadin:addSkill(lolKassadinClear)
Kassadin:addSkill(lolXuxing)
Kassadin:addSkill(lolXuren)
Kassadin:addSkill(lolMoDun)

newYi = sgs.General(extension,"newYi","wei",3)

lolNWujiCard = sgs.CreateSkillCard{
	name = "lolNWujiCard",	
	target_fixed = true,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		source:gainMark("@Wuju",2)
		source:loseMark("@YiR")
		room:handleAcquireDetachSkills(source,"wusheng|paoxiao|nosyingzi|mashu")
		room:broadcastSkillInvoke("lolNWuji")
	end,
}

lolNWuji = sgs.CreateViewAsSkill{
	name = "lolNWuji",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolNWujiCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@YiR")>0
	end,	
}

lolNWujiplus = sgs.CreateTriggerSkill{
	name = "#lolNWujiplus",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd,sgs.AskForPeachesDone},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
				if player:getMark("@Wuju") > 0 then
					player:loseMark("@Wuju")
					if player:getMark("@Wuju") == 0 then
						if player:hasSkill("wusheng") then
							room:detachSkillFromPlayer(player,"wusheng")
						end
						if player:hasSkill("paoxiao") then
							room:detachSkillFromPlayer(player,"paoxiao")
						end
						if player:hasSkill("nosyingzi") then
							room:detachSkillFromPlayer(player,"nosyingzi")
						end
						if player:hasSkill("mashu") then
							room:detachSkillFromPlayer(player,"mashu")
						end
					end
				end
			end
		elseif event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if not dying.damage.from then
				return false
			end
			local killer = dying.damage.from
			if player:getHp()>0 then
				return false
			end
			if not killer:hasSkill(self:objectName()) then
				return false
			end
			if not killer:hasFlag("Wuju") then
				killer:gainMark("@Wuju")
				room:setPlayerFlag("Wuju")
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

lolNMingxiangCard = sgs.CreateSkillCard{
	name = "lolNMingxiangCard",	
	target_fixed = true,	 
	will_throw = false,
	on_use = function(self,room,source,targets)		
		source:turnOver()
		if source:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = 1
			room:recover(source,recover)
			room:broadcastSkillInvoke("lolNMingxiang")
		end
	end,
}

lolNMingxiang = sgs.CreateViewAsSkill{
	name = "lolNMingxiang",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolNMingxiangCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolNMingxiangCard")
	end,	
}

lolnewYiR = getRMark("@YiR")

newYi:addSkill(lolNWuji)
newYi:addSkill(lolNWujiplus)
newYi:addSkill(lolNMingxiang)
newYi:addSkill(lolnewYiR)

newJarvanIV = sgs.General(extension,"newJarvanIV$","shu",4)

-- lolSDilieCard = sgs.CreateSkillCard{
-- 	name = "lolSDilieCard",	
-- 	target_fixed = false,	 
-- 	will_throw = true,
-- 	--handling_method = sgs.Card_MethodNone,
-- 	filter = function(self,targets,to_select,player)
-- 		if player:hasLordSkill("lolNTianbeng") then
-- 			return to_select:getKingdom() == "shu"
-- 		else
-- 			return to_select:hasSkill("lolNDilie")
-- 		end
-- 	end,
-- 	on_use = function(self,room,source,targets)	
-- 		room:broadcastSkillInvoke("lolNDilie")
-- 		if #targets == 0 then
-- 			room:setPlayerMark(source,"@zhanqi",1)
-- 		else
-- 			for _,t in ipairs(targets) do
-- 				room:setPlayerMark(t,"@zhanqi",1)
-- 			end
-- 		end
-- 	end,
-- }

-- lolMDilieCard = sgs.CreateSkillCard{
-- 	name = "lolMDilieCard",	
-- 	target_fixed = false,	 
-- 	will_throw = true,
-- 	--handling_method = sgs.Card_MethodNone,
-- 	filter = function(self,targets,to_select,player)
-- 		if player:hasLordSkill("lolNTianbeng") then
-- 			return to_select:getKingdom() == "shu"
-- 		else
-- 			return to_select:hasSkill("lolNDilie")
-- 		end
-- 	end,
-- 	on_use = function(self,room,source,targets)
-- 		room:broadcastSkillInvoke("lolNDilie")
-- 		room:acquireSkill(source,"wushuang")
-- 		room:acquireSkill(source,"mashu")
-- 		room:acquireSkill(source,"#lolChuanJia")
-- 		if #targets == 0 then
-- 			room:setPlayerMark(source,"@zhanqi",1)
-- 		else
-- 			for _,t in ipairs(targets) do
-- 				room:setPlayerMark(t,"@zhanqi",1)
-- 			end
-- 		end
-- 	end,	
-- }

-- lolBWDilieCard = sgs.CreateSkillCard{
-- 	name = "lolBWDilieCard",	
-- 	target_fixed = false,	 
-- 	will_throw = true,
-- 	--handling_method = sgs.Card_MethodNone,
-- 	filter = function(self,targets,to_select,player)
-- 		if player:hasLordSkill("lolNTianbeng") then
-- 			return to_select:getKingdom() == "shu"
-- 		else
-- 			return to_select:hasSkill("lolNDilie")
-- 		end
-- 	end,
-- 	on_use = function(self,room,source,targets)
-- 		room:broadcastSkillInvoke("lolNDilie")
-- 		local players = room:getAlivePlayers()
-- 		local target = room:askForPlayerChosen(source,players,"lolNDilie")
-- 		local id = room:askForCardChosen(source,target,"he","lolNDilie")
-- 		room:throwCard(id,target,source)
-- 		--获得技能
-- 		room:acquireSkill(source,"wushuang")
-- 		room:acquireSkill(source,"mashu")
-- 		room:acquireSkill(source,"#lolChuanJia")
-- 		if #targets == 0 then
-- 			room:setPlayerMark(source,"@zhanqi",1)
-- 		else
-- 			for _,t in ipairs(targets) do
-- 				room:setPlayerMark(t,"@zhanqi",1)
-- 			end
-- 		end
-- 	end,	
-- }

-- lolBADilieCard = sgs.CreateSkillCard{
-- 	name = "lolBADilieCard",	
-- 	target_fixed = false,	 
-- 	will_throw = true,
-- 	--handling_method = sgs.Card_MethodNone,
-- 	filter = function(self,targets,to_select,player)
-- 		if player:hasLordSkill("lolNTianbeng") then
-- 			return to_select:getKingdom() == "shu"
-- 		else
-- 			return to_select:hasSkill("lolNDilie")
-- 		end
-- 	end,
-- 	on_use = function(self,room,source,targets)	
-- 		room:broadcastSkillInvoke("lolNDilie")
-- 		source:gainMark("@Dun")	
-- 		room:acquireSkill(source,"wushuang")
-- 		room:acquireSkill(source,"mashu")
-- 		room:acquireSkill(source,"#lolChuanJia")
-- 		if #targets == 0 then
-- 			room:setPlayerMark(source,"@zhanqi",1)
-- 		else
-- 			for _,t in ipairs(targets) do
-- 				room:setPlayerMark(t,"@zhanqi",1)
-- 			end
-- 		end
-- 	end,
-- }

lolNDilieCard = sgs.CreateSkillCard{
	name = "lolNDilieCard",	
	target_fixed = false,	 
	will_throw = true,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if player:hasLordSkill("lolNTianbeng") then
			return to_select:getKingdom() == "shu"
		else
			return to_select:objectName() == player:objectName()
		end
	end,
	on_use = function(self,room,source,targets)		
		room:broadcastSkillInvoke("lolNDilie")
		room:acquireSkill(source,"wushuang")
		room:acquireSkill(source,"mashu")
		room:acquireSkill(source,"lolChuanJia")
		if #targets == 0 then
			room:setPlayerMark(source,"@zhanqi",1)
		else
			for _,t in ipairs(targets) do
				room:setPlayerMark(t,"@zhanqi",1)
			end
		end
	end,
}

lolNDilie = sgs.CreateViewAsSkill{
	name = "lolNDilie",
	n = 1,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return to_select:isRed() or to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return false
		end
		local card = cards[1]
		local vs_card = nil
		vs_card = lolNDilieCard:clone()
		vs_card:addSubcard(card)
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolNDilieCard")
	end,		
} 

lolNZhanqi = sgs.CreateTargetModSkill{
	name = "#lolNZhanqi",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	residue_func = function(self,player)
		if player:getMark("@zhanqi")>0 then
			return 1
		end
	end,
}

lolNDilieClear = sgs.CreateTriggerSkill{
	name = "#lolNDilieClear",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getMark("@zhanqi")>0 then
				room:setPlayerMark(player,"@zhanqi",0)
			end
			if player:hasSkill("wushuang") then
				room:detachSkillFromPlayer(player,"wushuang")
			end
			if player:hasSkill("mashu") then
				room:detachSkillFromPlayer(player,"mashu")
			end
			if player:hasSkill("lolChuanJia") then
				room:detachSkillFromPlayer(player,"lolChuanJia")
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}	

lolNTianbeng = sgs.CreateTriggerSkill{
	name = "lolNTianbeng$",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.GameStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:isLord() then
			room:broadcastSkillInvoke(self:objectName())
		end
	end,
}

newJarvanIV:addSkill(lolNDilie)
newJarvanIV:addSkill(lolNDilieClear)
newJarvanIV:addSkill(lolNZhanqi)
newJarvanIV:addSkill(lolNTianbeng)
newJarvanIV:addSkill(lolHuDun)

Maokai = sgs.General(extension,"Maokai","shu",4)

lolShugen = sgs.CreateTriggerSkill{
	name = "lolShugen",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		local me = room:findPlayerBySkillName(self:objectName())
		if card:isNDTrick() then
		 	if me:getMark("@greenTree") == 0 then
		 		me:gainMark("@Tree")
		 		if me:getMark("@Tree") >= 3 then
		 			room:broadcastSkillInvoke(self:objectName())
		 			room:setPlayerMark(me,"@Tree",0)
		 			room:setPlayerMark(me,"@greenTree",1)
		 		end
		 	end
		end
		if card:isKindOf("Slash") and use.from:objectName() == me:objectName() then
		 	if me:getMark("@greenTree") > 0 and me:isWounded() then
		 		room:setPlayerMark(me,"@greenTree",0)
		 		local recover =sgs.RecoverStruct()
		 		recover.who = me
		 		recover.recover = 1
		 		room:recover(me,recover)
		 	end
		end
	end,
	can_trigger = function(self,target)
		return target
	end	
}	

Maokai:addSkill(lolShugen)

-- loldrawTime = endRemoveMark("loldrawTime")

newTryndamere = sgs.General(extension,"newTryndamere","shu",4)

-- lolNNurenCard = sgs.CreateSkillCard{
-- 	name = "lolNNurenCard",	
-- 	target_fixed = true,	 
-- 	will_throw = false,
-- 	on_use = function(self,room,source,targets)		
-- 		room:broadcastSkillInvoke("lolNNuren")
-- 		room:setPlayerMark(source,"@anger",0)
-- 		local recover = sgs.RecoverStruct()
-- 		recover.who = source
-- 		recover.recover = 1
-- 		room:recover(source,recover)
-- 	end,
-- }

-- lolNNuren = sgs.CreateViewAsSkill{
-- 	name = "lolNNuren",
-- 	n = 0,
-- 	view_as = function(self,cards)
-- 		local vs_card = lolNNurenCard:clone()
-- 		vs_card:setSkillName(self:objectName())
-- 		return vs_card
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		return player:isWounded() and player:getMark("@anger")>=3
-- 	end,		
-- }	

lolNNuren = sgs.CreateTriggerSkill{
	name = "lolNNuren",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
			local count = player:getMark("@anger")
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.good = true
			judge.reason = self:objectName()
			if count == 1 then
				judge.pattern = ".|spade"
			elseif count == 2 then
				judge.pattern = ".|black"
			elseif count == 3 then
				judge.good = false
				judge.pattern = ".|heart"
			elseif count == 4 then
				judge.pattern = "."
			end
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke("lolNNuren")
				local id = use.card:getId()
				room:setCardFlag(id,"BaoJi")
			end
		end
	end,	
}

lolGetAnger,lolLostAnger = SlashedMarkPassive("@anger",2,4)

lolBumie = sgs.CreateTriggerSkill{
	name = "lolBumie",	
	frequeny = sgs.Skill_Limited, 
	events = {sgs.AskForPeachesDone},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		local source = dying.who
		if source:objectName() == player:objectName() then
			if player:getMark("lolBumieTime")==0 and player:getMark("@TryndamereR")>0 then
				if player:askForSkillInvoke(self:objectName(),data) then
					room:broadcastSkillInvoke(self:objectName())
					-- player:loseMark("@TryndamereR")
					room:setPlayerMark(player, "@TryndamereR", 0)
					room:setPlayerMark(player,"lolBumieTime",1)
					room:setPlayerMark(player,"angerClear",0)
					if player:getMark("@anger") < 3 then
						player:gainMark("@anger",2)
					elseif player:getMark("@anger") == 3 then
						player:gainMark("@anger")
					end
				end
			end
			if player:getMark("lolBumieTime")>0 then
				local hp = sgs.QVariant(1)
				room:setPlayerProperty(player,"hp",hp)
			end
		end
	end,	
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName()) and target:isAlive()
	end
}

lolTryndamereR = getRMark("@TryndamereR")
lolBumieTime = endRemoveMark("lolBumieTime")

-- newTryndamere:addSkill(lolDraw)
--ewTryndamere:addSkill(loldrawTime)
newTryndamere:addSkill(lolNNuren)
newTryndamere:addSkill(lolGetAnger)
newTryndamere:addSkill(lolLostAnger)
newTryndamere:addSkill(lolBaoJi)
newTryndamere:addSkill(lolBumie)
newTryndamere:addSkill(lolTryndamereR)
newTryndamere:addSkill(lolBumieTime)

Renekton = sgs.General(extension,"Renekton","wu",4) --鳄霸

lolGetViolent,lolLostViolent = SlashedMarkPassive("@violent",2,4)

lolBaoJun = sgs.CreateTriggerSkill{
	name = "lolBaoJun",
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.DamageCaused},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from:objectName() == player:objectName() then
			if damage.card and damage.card:isKindOf("Slash") then
				if player:getMark("@violent")>=2 then
					if player:askForSkillInvoke(self:objectName(),data) then
						damage.to:turnOver()
						player:loseMark("@violent",2)
						room:broadcastSkillInvoke("lolBaoJun")
						if player:getHp() <= 1 then
							local recover = sgs.RecoverStruct()
							recover.who = player
							room:recover(player,recover)
						end
					end
				end
			end
		end
	end,	
}	

lolTongzhiCard = sgs.CreateSkillCard{
	name = "lolTongzhiCard",	
	target_fixed = true,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		room:setPlayerMark(source,"lolTongzhiTime",3)
		source:gainMark("@violent")
		room:setPlayerMark(source,"@RenektonR",0)
		room:setPlayerMark(source,"violentClear",0)
		room:broadcastSkillInvoke("lolTongzhi")
	end,
}

lolTongzhi = sgs.CreateZeroCardViewAsSkill{
	name = "lolTongzhi",
	--relate_to_place = deputy,	
	--response_pattern = "",		
	view_as = function(self)
		return lolTongzhiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@RenektonR")>0
	end,
}

lolTongzhiPlus = sgs.CreateTriggerSkill{
	name = "#lolTongzhiPlus",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:getMark("lolTongzhiTime")>0 then
				player:gainMark("@violent")
				room:setPlayerMark(player,"violentClear",0)
			end
		end
	end,	
}

lolTongzhiTime = endRemoveMark("lolTongzhiTime")

lolRenektonR = getRMark("@RenektonR")

Renekton:addSkill(lolGetViolent)
Renekton:addSkill(lolLostViolent)
Renekton:addSkill(lolBaoJun)
Renekton:addSkill(lolTongzhiTime)
Renekton:addSkill(lolTongzhiPlus)
Renekton:addSkill(lolTongzhi)
Renekton:addSkill(lolRenektonR)

Karthus = sgs.General(extension, "Karthus", "qun", 2)

lolZhenhun = sgs.CreateTriggerSkill{
	name = "lolZhenhun",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayer("Karthus", true)
		if player:objectName() ~= me:objectName() then
			if player:getPhaseString() == "start" then
				if me:askForSkillInvoke(self:objectName(), data) then
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|black"
					judge.reason = self:objectName()
					judge.good = false
					room:judge(judge)
					if judge:isBad() then
						room:broadcastSkillInvoke(self:objectName())
						local damage = sgs.DamageStruct()
						damage.to = player
						if me:isAlive() then
							damage.from = me
						else
							damage.from = player
						end
						room:damage(damage)
					end
				end
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

Karthus:addSkill(lolZhenhun)

Graves = sgs.General(extension, "Graves", "wei", 3)

lolMolu = sgs.CreateTargetModSkill{
	name = "lolMolu",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",	
	extra_target_func = function(self,player)
		if player:getHandcardNum() <= 1 and player:hasSkill(self:objectName()) then
			return 2
		end
	end,
}

lolQiongtuCard = sgs.CreateSkillCard{
	name = "lolQiongtuCard",	
	target_fixed = true,	 
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return true
	end,
	on_use = function(self,room,source,targets)		
		room:setPlayerFlag(source, "lolQiongtu")
	end,
}

lolSQiongtuCard = sgs.CreateSkillCard{
	name = "lolSQiongtuCard",	
	target_fixed = true,	 
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return true
	end,
	on_use = function(self,room,source,targets)		
		room:setPlayerFlag(source, "lolSQiongtu")		
	end,
}

lolQiongtu = sgs.CreateViewAsSkill{
	name = "lolQiongtu",	
	n = 2,
	view_filter = function(self,selected,to_select)
		return #selected < 2 and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local vs = lolSQiongtuCard:clone()
			vs:addSubcard(cards[1])
			vs:setSkillName(self:objectName())
			return vs
		elseif #cards == 2 then
			local vs = lolQiongtuCard:clone()
			vs:addSubcard(cards[1])
			vs:addSubcard(cards[2])
			vs:setSkillName(self:objectName())
			return vs
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolQiongtuCard") or player:hasUsed("#lolSQiongtuCard")
	end,	
}

lolQiongtuPassive = sgs.CreateTriggerSkill{
	name = "#lolQiongtuPassive",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseEnd},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhaseString() == "finish" then
			if player:hasFlag("lolQiongtu") then
				player:drawCards(2)
			elseif player:hasFlag("lolSQiongtu") then
				player:drawCards(1)
			end
		end
	end,	
}

Graves:addSkill(lolMolu)
Graves:addSkill(lolQiongtu)
Graves:addSkill(lolQiongtuPassive)

----------------------名测试将-----------------------------------
Test = sgs.General(extension, "test", "wei", 8)

-- lolxinxi = 	sgs.CreateTriggerSkill{
-- 	name = "lolxinxi",	
-- 	frequeny = sgs.Skill_Frequent, 
-- 	events = {sgs.EventPhaseStart},
-- 	-- view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local players = room:getAlivePlayers()
-- 		local frends = sgs.SPlayerList()
-- 		local tos = {}
-- 		for _,p in sgs.qlist(players) do
-- 			if p then
-- 				frends:append(p)
-- 				table.insert(tos, p:getGeneralName())
-- 			end
-- 		end
-- 		if frends:length() > 0 then
-- 			local sunfrom = player
-- 			local toss = table.concat(tos)
-- 			local prompt = string.format("invoke:"..sunfrom:getGeneralName())
-- 			if player:getPhaseString() == "start" then
-- 				if player:askForSkillInvoke(self:objectName(), sgs.QVariant(prompt)) then
-- 					player:speak(sunfrom:objectName())
-- 				end
-- 			end
-- 		end
-- 	end,	
-- }

shishi = sgs.CreateTriggerSkill{
	name = "shishi",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	-- view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local kingdom_set = {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			table.insert(kingdom_set, p:getKingdom())
		end
		local n = #kingdom_set
		player:speak(tostring(n))
	end,	
}

-- Test:addSkill(shishi)
Test:addSkill(lolGM)
-- Test:addSkill(lolxinxi)
skill_list = sgs.SkillList()


------------------------装备区---------------------------



------------------------装备区---------------------------

------------------------添加技能---------------------------
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
	["lol"] = "英雄联盟包",
	["@Dun"] = "护盾",
	["@MoDun"] = "魔法护盾",
	["@XuanYun"] = "眩晕",
	["@JinGu"] = "禁锢",

	["lolGiveArmor"] = "给甲",
	["lolDamage"] = "伤害",
	["lolRecover"] = "回复",
	["lolThrow"] = "弃牌",
	["lolDraw"] = "摸牌",
	["lolChange"] = "变身",
	["lolChuanJia"] = "穿甲",
	[":lolChuanJia"] = "你的【杀】无视防具",

	["@Garen_R"] = "德玛西亚正义",
	["newGaren"] = "盖伦",
	["&newGaren"] = "盖伦",
	["#newGaren"] = "德玛西亚之力",
	["@Justice"] = "正义",
	["lolnewJianren"] = "坚韧",
	[":lolnewJianren"] = "锁定技，除你受伤后的下个回合外，回合开始阶段，若你已受伤，你回复一点体力",
	["$lolnewJianren1"] = "正义，与我同在！",
	["$lolnewJianren2"] = "人在塔在",
	["lolNZhengyi"] = "正义",
	["lolnzhengyi"] = "正义",
	[":lolNZhengyi"] = "限定技，出牌阶段，你可对一名与你距离为1的角色造成一点伤害，若该角色已损失至少，此伤害+1。",
	["$lolNZhengyi"] = "别怕，我来了",
	["~newGaren"] = "狡诈恶徒",
	["designer:newGaren"] = "Wargon",
	["cv:newGaren"] = "Miss Baidu",
	["illustrator:newGaren"] = "Riot",
	
	["@NasusR"] = "死神降临",
	["Nasus"] = "内瑟斯",
	["&Nasus"] = "内瑟斯",
	["#Nasus"] = "沙漠死神",
	["@getSoul"] = "汲魂",
	["lolJihun"] = "汲魂",
	[":lolJihun"] = "锁定技，你杀死一名角色后，你的杀造成的伤害永久+1",
	["$lolJihun1"] = "生是轮回的一部分，而你的这部分，已经结束了",
	["$lolJihun2"] = "死亡与我同在",
	["lolSishen"] = "死神",
	["lolsishen"] = "死神",
	[":lolSishen"] = "限定技，出牌阶段，你可增加1点体力上限并回复1点体力，然后摸1张牌，且接下来的两个回合外，当有角色死亡时，你获得一枚“汲魂”标记",
	["designer:Nasus"] = "Wargon",
	["cv:Nasus"] = "Miss Baidu",
	["illustrator:Nasus"] = "Riot",
	
	["Soroka"] = "索拉卡",
	["&Soroka"] = "索拉卡",
	["#Soroka"] = "众星之子",
	["lolJiushu"] = "救赎",
	["loljiushu"] = "救赎",
	[":lolJiushu"] = "出牌阶段限一次，你可自减1点体力，令一名受伤的其他角色恢复至多2点体力。",
	["$lolJiushu"] = "我引领着星光的降临",
	["lolQidao"] = "祈祷",
	[":lolQidao"] = "当你的非延时类锦囊造成伤害时，你回复一点体力，每回合限一次。",
	["$lolQidao"] = "我的力量，来自众星",
	["designer:Soroka"] = "Wargon",
	["cv:Soroka"] = "Miss Baidu",
	["illustrator:Soroka"] = "Riot",
	
	["@Wuju"] = "无极",
	["@YiR"] = "高原血统",
	["newYi"] = "易",
	["&newYi"] = "易",
	["#newYi"] = "无极剑圣",
	["designer:newYi"] = "Wargon",
	["cv:newYi"] = "Miss Baidu",
	["illustrator:newYi"] = "Riot",
	["lolNWuji"] = "无极",
	["lolnwuji"] = "无极",
	[":lolNWuji"] = "限定技，你可获得“武圣”“咆哮”“英姿”“马术”两个回合。在此期间你每杀死一名角色，便多延长一个回合。",
	["$lolNWuji"] = "无极之道！",
	["lolNMingxiang"] = "冥想",
	["lolnmingxiang"] = "冥想",
	[":lolNMingxiang"] = "出牌阶段，你可将武将牌翻面，若你已受伤，你回复1点体力。每回合限一次",
	["$lolNMingxiang"] = "你们的技术太烂了",
	-- ["LuaYingzi"] = "英姿",
	-- [":LuaYingzi"] = "摸牌阶段，你可以额外摸一张牌。",
	-- ["$LuaYingzi"] = "眼睛多看东西才更加清楚",
	
	["Jax"] = "贾克斯",
	["&Jax"] = "贾克斯",
	["#Jax"] = "武器大师",
	["designer:Jax"] = "Wargon",
	["cv:Jax"] = "Miss Baidu",
	["illustrator:Jax"] = "Riot",
	["lolZongshi"] = "宗师",
	[":lolZongshi"] = "你的【杀】造成伤害时，你摸一张牌，且可额外再出一张【杀】。",
	["$lolZongshi1"] = "哼，一个能打的都没有",
	["$lolZongshi2"] = "现在该我了",
	["$lolZongshi3"] = "还有谁",
	
	["newJarvanIV"] = "嘉文四世",
	["&newJarvanIV"] = "嘉文四世",
	["#newJarvanIV"] = "德玛西亚皇子",
	["designer:newJarvanIV"] = "Wargon",
	["cv:newJarvanIV"] = "Miss Baidu",
	["illustrator:newJarvanIV"] = "Riot",
	["lolNDilie"] = "地裂",
	["lolndilie"] = "地裂",
	[":lolNDilie"] = "出牌阶段，你可弃置一张红色牌或装备牌，本回合你可额外使用一张【杀】，并获得“无双”、“马术”、“穿甲”直至回合结束。",
	["$lolNDilie"] = "犯我德邦者，虽远必诛！",
	["@zhanqi"] = "战旗",
	["lolNTianbeng"] = "天崩",
	[":lolNTianbeng"] = "主公技，你发动“地裂”时可以任意指定蜀势力角色，令其下回合可额外使用一张杀",
	["$lolNTianbeng"] = "德玛西亚，无可匹敌！",
	
	["hou"] = "分身",
	["Wukong"] = "孙悟空",
	["&Wukong"] = "孙悟空",
	["#Wukong"] = "齐天大圣",
	["designer:Wukong"] = "Wargon",
	["cv:Wukong"] = "Miss Baidu",
	["illustrator:Wukong"] = "Riot",
	["lolQianbian"] = "千变",
	[":lolQianbian"] = "回合结束阶段，若你的武将牌上没有“分身”，你可将一张手牌掩置于武将牌上，成为“分身”。",
	["@lolQianbian"] = "是否将一张手牌作为“分身”牌",
	["$lolQianbian"] = "嗯~此地不宜久留",
	["lolWanhua"] = "万化",
	[":lolWanhua"] = "当你受到伤害时，你可弃置一张“分身”，若这张“分身”为红桃牌，你可令伤害来源失去一点体力，并防止此伤害。",
	["$lolWanhua"] = "嘿嘿，俺老孙正等着呢",
	["lolQitian"] = "齐天",
	[":lolQitian"] = "出牌阶段，你可使用X张【杀】。（X为你当前攻击距离）",
	["$lolQitian"] = "吃俺老孙一棒",
	
	["@coldPrison"] = "寒狱",
	["Sejuani"] = "瑟庄妮",
	["&Sejuani"] = "瑟庄妮",
	["#Sejuani"] = "凛冬之怒",
	["designer:Sejuani"] = "Wargon",
	["cv:Sejuani"] = "Miss Baidu",
	["illustrator:Sejuani"] = "Riot",
	["lolHanyu"] = "寒狱",
	["lolhanyu"] = "寒狱",
	[":lolHanyu"] = "出牌阶段，若场上其他角色的手牌总数大于其他存活角色总数乘以3，你可弃置一名角色一张牌，每回合一名角色最多2次。",
	["$lolHanyu1"] = "我将统治弗雷尔卓德",
	["$lolHanyu2"] = "不要手下留情",
	["$lolHanyu3"] = "反对我的人必将，血溅四方",
	
	["Vladimir"] = "弗拉基米尔",
	["&Vladimir"] = "弗拉基米尔",
	["#Vladimir"] = "猩红收割者",
	["designer:Vladimir"] = "Wargon",
	["cv:Vladimir"] = "Miss Baidu",
	["illustrator:Vladimir"] = "Riot",
	["lolXueqi"] = "血契",
	[":lolXueqi"] = "锁定技，你没造成或受到一点伤害，你每回复一点体力时，你摸一张牌。",
	["$lolXueqi1"] = "请让鲜血都流出来吧",
	["$lolXueqi2"] = "血液，正在慢慢滴落",
	["$lolXueqi3"] = "收获之夜，多美妙的名字啊",
	
	["Lux"] = "拉克丝",
	["&Lux"] = "拉克丝",
	["#Lux"] = "光辉女郎",
	["designer:Lux"] = "Wargon",
	["cv:Lux"] = "Miss Baidu",
	["illustrator:Lux"] = "Riot",
	["lolGuangfu"] = "光缚",
	["lolguangfu"] = "光缚",
	[":lolGuangfu"] = "出牌阶段，你可弃置一张【杀】，然后指定一名不在你攻击范围内的角色，眩晕该角色。每回合限一次",
	["lolQuguang"] = "曲光",
	["lolquguang"] = "曲光",
	[":lolQuguang"] = "出牌阶段，你可弃置一张装备牌，令一名没有护盾的角色获得一枚护盾。每回合限一次",
	["$lolGuangfu"] = "注意战场形势",
	["$lolQuguang"] = "德玛西亚万岁",
	
	["Olaf"] = "奥拉夫",
	["&Olaf"] = "奥拉夫",
	["#Olaf"] = "狂战士",
	["designer:Twisted"] = "Wargon",
	["cv:Twisted"] = "Miss Baidu",
	["illustrator:Twisted"] = "Riot",
	["lolZhushen"] = "诛神",
	[":lolZhushen"] = "摸牌阶段摸牌时，你多摸X张牌；出牌阶段，你可额外使用X张【杀】（X为你损失的体力值-1，且至少为0）",
	["$lolZhushen"] = "所到之处，寸草不生",

	["@cardBlue"] = "蓝",
	["@cardRed"] = "红",
	["@cardYellow"] = "黄",
	["Twisted"] = "崔斯特",
	["&Twisted"] = "崔斯特",
	["#Twisted"] = "卡牌大师",
	["designer:Twisted"] = "Wargon",
	["cv:Twisted"] = "Miss Baidu",
	["illustrator:Twisted"] = "Riot",
	["lolMingyun"] = "命运",
	["lolmingyun"] = "命运",
	[":lolMingyun"] = "回合开始时，若你没有标记，则你获得一枚“蓝”标记，若你拥有“蓝标记”，则失去他，获得一枚“红”标记，若你拥有“红”标记，则失去他，获得一枚“黄”标记，若你拥有“黄”标记，则失去他，获得一枚“蓝”标记。你可发动此技能，消耗拥有的标记",
	["$lolMingyun"] = "胜利女神在微笑",
	["lolXuanpai"] = "选牌",
	[":lolXuanpai"] = "你发动命运消耗一枚标记后，若消耗的标记为“蓝”，当前回合，你可将黑桃牌当【过河拆桥】使用；若为“红”，当前回合，你可将方块牌当【乐不思蜀】使用；若为“黄”，当前回合，你可将红桃牌当【无中生有】使用",

	["Udyr"] = "乌迪尔",
	["&Udyr"] = "乌迪尔",
	["Udyr_tiger"] = "乌迪尔",
	["&Udyr_tiger"] = "乌迪尔",
	["Udyr_turtle"] = "乌迪尔",
	["&Udyr_turtle"] = "乌迪尔",
	["Udyr_bear"] = "乌迪尔",
	["&Udyr_bear"] = "乌迪尔",
	["Udyr_Phoenix"] = "乌迪尔",
	["&Udyr_Phoenix"] = "乌迪尔",
	["#Udyr"] = "兽灵行者",
	["designer:Udyr"] = "Wargon",
	["cv:Udyr"] = "Miss Baidu",
	["illustrator:Udyr"] = "Riot",
	["lolSiling"] = "四灵",
	[":lolSiling"] = "回合开始时，你可进行一次判定，依照判定结果你可进入相应状态：黑桃：“虎”（群）（铁骑），红桃：“龟”（吴）（八阵），梅花：“熊”（魏）（国色），方块：“凤”（蜀）（火计）",
	["$lolSiling1"] = "我们的狂怒仍在继续",
	["$lolSiling2"] = "野性的本能指引着我们的拳头",
	
	["newTryndamere"] = "泰达米尔",
	["&newTryndamere"] = "泰达米尔",
	["#newTryndamere"] = "蛮族之王",
	["designer:newTryndamere"] = "Wargon",
	["cv:newTryndamere"] = "Miss Baidu",
	["illustrator:newTryndamere"] = "Riot",
	["@anger"] = "怒",
	["lolNNuren"] = "怒刃",
	[":lolNNuren"] = "锁定技，你使用一张【杀】时获得一枚“怒”标记，最多4枚。你使用【杀】时，若你拥有“怒”标记，则进行一次判定，若符合条件（你的每一张“怒”标记都会为条件增加一种判定花色），此【杀】伤害+1。若你连续两个回合未获得“怒”标记，你失去一枚“怒”标记。",
	["$lolNNuren1"] = "现在他们可以死了",
	["$lolNNuren2"] = "随心而动，随刃而行",
	["$lolNNuren3"] = "开战吧",
	["$lolNNuren4"] = "我的大刀早已饥渴难耐了",
	["lolBumie"] = "不灭",
	[":lolBumie"] = "限定技，当你处于濒死状态时，你可将体力值回复至1点，并摸得两枚“怒”标记，直至你的下个回合结束，你的体力至少为1。",
	["$lolBumie"] = "我是你最可怕的噩梦",
	["@TryndamereR"] = "无尽怒火",

	["solder"] = "兵",
	["Azir"] = "阿兹尔",
	["&Azir"] = "阿兹尔",
	["#Azir"] = "沙漠皇帝",
	["designer:Azir"] = "Wargon",
	["cv:Azir"] = "Miss Baidu",
	["illustrator:Azir"] = "Riot",
	["lolShabing"] = "沙兵",
	[":lolShabing"] = "出牌阶段，若你武将牌上没有牌，你可将一张手牌置于武将牌上，称为“兵”，回合结束时，你将手牌和“兵”互换；你的回合结束时，额外进行一个回合（此回合你的手牌上限为1）",
	["lolFuxing"] = "复兴",
	[":lolFuxing"] = "主公技，你在“沙兵”的额外回合里，场上每存活一个其他蜀势力角色，你的手牌上限便+1",

	["HeavyRain"] = "暴雨",
	["Kaisa"] = "卡莎",
	["&Kaisa"] = "卡莎",
	["#Kaisa"] = "虚空之女",
	["designer:Kaisa"] = "Wargon",
	["cv:Kaisa"] = "Miss Baidu",
	["illustrator:Kaisa"] = "Riot",
	["lolSuodi"] = "索敌",
	[":lolSuodi"] = "你使用【乐不思蜀】或【兵粮寸断】指定一名角色后，你可令本局游戏你与该角色计算距离时始终为1",
	["lolChaozai"] = "超载",
	[":lolChaozai"] = "出牌阶段开始时，若你的武将牌上没有牌，你可将所有的红色手牌置于武将牌上成为“暴雨”，你每拥有一张“暴雨”，出牌阶段便可额外使用一张【杀】",
	["lolBaoyu"] = "暴雨",
	[":lolBaoyu"] = "你可将一枚“暴雨”牌当【杀】使用",

	["Ornn"] = "奥恩",
	["&Ornn"] = "奥恩",
	["#Ornn"] = "山隐之焰",
	["lolZhongsheng"] = "众生",
	[":lolZhongsheng"] = "其他角色的装备区失去一张装备牌时，若你的武将牌正面朝上，你可就将武将牌反面并将这张装备牌获得之",
	["lolPingdeng"] = "平等",
	["lolpingdeng"] = "平等",
	[":lolPingdeng"] = "阶段技，你可弃置一张牌，令一名角色摸一张牌，然后你与其翻面",

	["league"] = "联盟",
	["Draven"] = "德莱文",
	["&Draven"] = "德莱文",
	["#Draven"] = "荣誉行刑官",
	["designer:Draven"] = "Wargon",
	["cv:Draven"] = "Miss Baidu",
	["illustrator:Draven"] = "Riot",
	["lolLianmeng"] = "联盟",
	[":lolLianmeng"] = "你使用的【杀】不计入出牌数，且你使用一张非转化的【杀】后，可进行一次判定，若判定结果与此【杀】颜色相同，你将这张【杀】置于武将牌上称为“联盟”，回合结束阶段，你将所有“联盟”牌获得之。",
	["$lolLianmeng"] = "好好看，好好学",
	["lolRongyu"] = "荣誉",
	[":lolRongyu"] = "锁定技，你杀死一名角色后，立即摸3张牌。并将所有的“联盟”牌获得之",
	["$lolRongyu"] = "欢迎来到德莱联盟",

	["Yasuo"] = "亚索",
	["&Yasuo"] = "亚索",
	["#Yasuo"] = "疾风剑豪",
	["designer:Yasuo"] = "Wargon",
	["cv:Yasuo"] = "Miss Baidu",
	["illustrator:Yasuo"] = "Riot",
	["lolLangke"] = "浪客",
	["$lolLangke1"] = "此剑之势，愈斩愈烈",
	["$lolLangke2"] = "且随疾风前行，身后亦须留心",
	["$lolLangke3"] = "一剑，一念",
	["$lolLangke4"] = "无罪之人，方可安睡",
	["$lolLangke5"] = "吾之初心，永世不忘",
	["$lolLangke6"] = "死亡如风，长伴吾身",
	["windBlade"] = "风刃",
	[":lolLangke"] = "你的回合外，每当你用来响应的牌总计达到3张时，你获得两张牌；你的一个回合内，当你总计使用了3张牌时，你可指定一名角色，令其弃置两张手牌。",
	["lolFengzhan"] = "风斩",
	[":lolFengzhan"] = "限定技，当一名角色在你的回合内失去最后一张手牌时，你可对其造成1点伤害，然后你获得1枚“护盾”，且之后与其计算距离时，始终为1。",
	["@Yasuo_E"] = "浪客",
	["@YasuoR"] = "狂风绝息斩",

	["Sion"] = "塞恩",
	["&Sion"] = "塞恩",
	["#Sion"] = "亡灵战神",
	["designer:Sion"] = "Wargon",
	["cv:Sion"] = "Miss Baidu",
	["illustrator:Sion"] = "Riot",
	["lolRonghun"] = "融魂",
	["lolronghun"] = "融魂",
	["$lolRonghun"] = "吃我一记重击",
	[":lolRonghun"] = "出牌阶段，若你没有“护盾”标记，你可自减1点体力，获得1枚“护盾”标记；当你拥有护盾时，你的【杀】不得被方块【闪】响应",
	["lolZhuhun"] = "铸魂",
	["lolzhuhun"] = "铸魂",
	["$lolZhuhun"] = "交给我吧",
	[":lolZhuhun"] = "出牌阶段，若你未受伤，你可弃置一张【桃】，增加1点体力上限，回复1点体力",

	["Kassadin"] = "卡萨丁",
	["&Kassadin"] = "卡萨丁",
	["#Kassadin"] = "虚空行者",
	["designer:Kassadin"] = "Wargon",
	["cv:Kassadin"] = "Miss Baidu",
	["illustrator:Kassadin"] = "Riot",
	["lolXuwu"] = "虚无",
	["lolxuwu"] = "虚无",
	[":lolXuwu"] = "出牌阶段，你可沉默一名角色直至回合结束，并获得2点魔法护盾，你最多拥有2枚魔法护盾。每回合限一次",
	["$lolXuwu"] = "必须维持力量的均衡",
	["lolXuxing"] = "虚行",
	[":lolXuxing"] = "你与其他角色计算距离时，始终为1",
	["lolXuren"] = "虚刃",
	[":lolXuren"] = "你使用一张非延时类锦囊时，若你不为此锦囊的目标，则你可令此锦囊的第一个目标受到1点伤害，并令此锦囊对其无效。每回合限一次",
	["$lolXuren"] = "正义将会得到伸张",

	["Maokai"] = "茂凯",
	["&Maokai"] = "茂凯",
	["#Maokai"] = "扭曲树精",
	["designer:Maokai"] = "Wargon",
	["cv:Maokai"] = "Miss Baidu",
	["illustrator:Maokai"] = "Riot",
	["lolShugen"] = "树根",
	[":lolShugen"] = "场上每有人使用非延时类锦囊时，你获得一枚“树苗”标记，当你拥有3张“树苗”标记时，你失去所有“树苗”标记，获得一枚“树根”标记，拥有“树根”标记时你不能获得“树苗”标记；你使用一张【杀】时，若你拥有“树根”标记且已受伤，你失去“树根”标记，然后回复1点体力。",
	["$lolShugen"] = "群岛，将再次茂盛",

	["Renekton"] = "雷克顿",
	["&Renekton"] = "雷克顿",
	["#Renekton"] = "荒漠屠夫",
	["designer:Renekton"] = "Wargon",
	["cv:Renekton"] = "Miss Baidu",
	["illustrator:Renekton"] = "Riot",
	["lolBaoJun"] = "暴君",
	[":lolBaoJun"] = "被动）你使用【杀】时，获得一枚“残暴”标记，最多4枚。你每有连续的两个回合未获得“残暴”标记，你失去一枚“残暴”标记。当你的【杀】造成伤害时，若你至少拥有两枚“残暴”，你可失两枚“残暴”标记，令该角色翻面，若此时你体力值不大于2，你回复1点体力。",
	["$lolBaoJun"] = "所有人，都得死",
	["#lolBaoJunSlash"] = "暴君",
	["lolTongzhi"] = "统治",
	["loltongzhi"] = "统治",
	[":lolTongzhi"] = "限定技，出牌阶段，你可令包括本回合在内的3个回合里，每个回合开始时你获得一枚“残暴”标记（本回合发动时立即获得）。",
	["$lolTongzhi"] = "没有什么可以阻止我了",
	["@violent"] = "残暴",
	["@RenektonR"] = "终极统治",

	["@Sheol"] = "冥府",
	["Malzahar"] = "玛尔扎哈",
	["&Malzahar"] = "玛尔扎哈",
	["#Malzahar"] = "虚空先知",
	["designer:Malzahar"] = "Wargon",
	["cv:Malzahar"] = "Miss Baidu",
	["illustrator:Malzahar"] = "Riot",
	["lolMingfu"] = "冥府",
	["lolmingfu"] = "冥府",
	[":lolMingfu"] = "限定技，你可指定一名没有“冥府”技能的角色，令其失去所有技能，获得技能“冥府”",
	["$lolMingfu"] = "等待湮灭",
	["lolChongqun"] = "虫群",
	[":lolChongqun"] = "摸牌阶段，你可额外摸X张牌（X为场上拥有“冥府”技能的角色数）",

	["Karthus"] = "卡尔萨斯",
	["&Karthus"] = "卡尔萨斯",
	["#Karthus"] = "死亡颂唱者",
	["designer:Karthus"] = "Wargon",
	["cv:Karthus"] = "Miss Baidu",
	["illustrator:Karthus"] = "Riot",
	["lolZhenhun"] = "镇魂",
	[":lolZhenhun"] = "一名其他角色的回合开始时，你可令其进行一次判定，若为黑色，其受到一点来自自己的伤，你死亡后也可发动此技能",
	["$lolZhenhun"] = "极悲，极怒，平和，每个必经阶段，都有其美妙之处",

	["Jiatenghui"] = "加藤惠",
	["Yinglili"] = "英梨梨",
	["Shiyu"] = "诗羽",
	["Meizhiliu"] = "美智留",
	["Skarner"] = "斯卡纳",
	["&Skarner"] = "斯卡纳",
	["#Skarner"] = "水晶先锋",
	["designer:Skarner"] = "Wargon",
	["cv:Skarner"] = "Miss Baidu",
	["illustrator:Skarner"] = "Riot",
	["lolJinlile"] = "尽梨了",
	[":lolJinlile"] = "游戏开始时，你随机获得1-4次机会，每次可以从4个路人女主中获得其一项技能",
	["$lolJinlile"] = "我的毒刺不会让你失望的",

	["Graves"] = "格雷福斯",
	["&Graves"] = "格雷福斯",
	["#Graves"] = "法外狂徒",
	["designer:Graves"] = "Wargon",
	["cv:Graves"] = "Miss Baidu",
	["illustrator:Graves"] = "Riot",
	["lolMolu"] = "末路",
	[":lolMolu"] = "若你使用的【杀】是你的最后一张手牌，此【杀】可额外指定2名角色",
	["$lolMolu"] = "",
	["lolQiongtu"] = "穷途",
	[":lolQiongtu"] = "出牌阶段，你可弃置至多两张手牌，则回合结束时，你摸等同于你以此法弃置的牌数。每回合限一次",
	["$lolQiongtu"] = "",
}