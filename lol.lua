module("extensions.lol",package.seeall)

extension = sgs.Package("lol")

--------------------通用技能栏-----------------------
--以下技能有些是为了方便测试而添加的，有些武将的技能触发条件有些苛刻，用这些技能可以方便达成条件，有些技能则是为了减少重复的工作

--你只需为武将添加这个函数返回的技能，游戏开始时他就会为你的武将返回一个Rmark所代表的标记
--ex：lolWujinagR = Rset("#lolWujiangR","@WujiangR")
--    Wujiang:addSkill(lolWujiangR)
-- 游戏开始时，Wujiang这个武将就会获得一枚"@WujiangR"标记，以下的其他函数同理
--（字符串）Rname 技能的name属性,
--（字符串）Rmark 游戏开始时要添加的mark
Rset = function(Rname,Rmark)
	lolR = sgs.CreateTriggerSkill{
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

--自动清除标记，你只需要给武将添加一个这个函数返回的技能，然后武将每个回合结束就会自动清除time所代表的标记
--（字符串）time 标记的名字，比如“@mark”，“flag”等等
timeEnd = function(time)

	local lolTime = sgs.CreateTriggerSkill{
		name = "#"..time,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.EventPhaseEnd},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Finish then
				if player:getMark(time)>0 then
					player:loseMark(time)
				end
			end
		end,	
	}
	return lolTime
end

--自动清除标记，你只需要给武将添加一个这个函数返回的技能，然后武将每个回合开始就会自动清除time所代表的标记
--（字符串）time 标记的名字，比如“@mark”，“flag”等等
timeStar = function(time)

	local lolTime = sgs.CreateTriggerSkill{
		name = "#"..time,	
		frequeny = sgs.Skill_Compulsory, 
		events = {sgs.EventPhaseStart},
		--view_as_skill = ,
		on_trigger = function(self,event,player,data)
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Start then
				if player:getMark(time)>0 then
					player:loseMark(time)
				end
			end
		end,	
	}
	return lolTime
end

--穿甲，拥有这个技能，你的【杀】会无视防具
lolChuanJia = sgs.CreateTriggerSkill{
	name = "#lolChuanJia",	
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

--技能卡
lolGiveArmorCard = sgs.CreateSkillCard{
	name = "lolGeiJia",	
	target_fixed = false,	 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return to_select:getArmor() == nil
		end
	end,
	on_use = function(self,room,source,targets)		
		local armor = source:getArmor()
		local target = targets[1]
		if armor then
			room:moveCardTo(armor,target,sgs.Player_PlaceEquip)
		end
	end,
}

--给盾，可以把你装备的防具给一名角色装上，如果这个角色没装备防具的话
lolGiveArmor = sgs.CreateViewAsSkill{
	name = "lolGiveArmor",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolGiveArmorCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:getArmor()
	end,		
}

--摸牌，指定一名角色，让他摸一张牌
lolDraw = sgs.CreateTriggerSkill{
	name = "lolDraw",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getMark("loldrawTime") == 0 then
			player:gainMark("loldrawTime",2)
			player:drawCards(1)
			room:setPlayerFlag(player,self:objectName())
		end
	end,	
}

--
lolCardUseReason = sgs.CreateTriggerSkill{
	name = "lolHah",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed,sgs.CardResponded},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_who then
				response.m_who:gainMark("@card1")
			end
			if response.m_isUse then
				player:gainMark("@card2")
			end
			if response.m_isRetrial then
				player:gainMark("@card3")
			end
			if response.m_isHandcard then
				player:gainMark("@card4")
			end
		end
	end,
	can_trigger = function(self,target)
			return target
		end	
}

--
lolRecoverCard = sgs.CreateSkillCard{
	name = "lolRecoverCard",	
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
lolRecover = sgs.CreateViewAsSkill{
	name = "lolRecover",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolRecoverCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,		
}

--
lolDamageCard = sgs.CreateSkillCard{
	name = "lolDamageCard",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return true
		end
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
lolDamage = sgs.CreateViewAsSkill{
	name = "lolDamage",	
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolDamageCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
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
	name = "lolDizzy",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		if player:getMark("TouYun") == 0 then
			return false
		end
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			room:setPlayerMark(player,"TouYun",0)
			if player:containsTrick("indulgence") then
				return false
			end
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
			room:setCardLimitation("use","slash|.|.|.",true)
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}	

--
lolThrowCard = sgs.CreateSkillCard{
	name = "lolThrowCard",	
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
		room:askForDiscard(target,self:objectName(),1,1)
	end,
}

--弃牌，你可弃置一名角色一张牌
lolThrow = sgs.CreateZeroCardViewAsSkill{
	name = "lolThrow",
	view_as = function(self)
		return lolThrowCard:clone()
	end,	
}

--------------------通用技能栏-------------------------

--暗降
Anjiang = sgs.General(extension,"anjiang","god",4,true,true,true)

--------------------通用技添加区-----------------------

-- Anjiang:addSkill(lolTime)
Anjiang:addSkill(lolThrow)
Anjiang:addSkill(lolDizzy)
Anjiang:addSkill(lolHuDun)
Anjiang:addSkill(lolMoDun)
Anjiang:addSkill(lolChuanJia)
Anjiang:addSkill(lolGiveArmor)
Anjiang:addSkill(lolDraw)
Anjiang:addSkill(lolCardUseReason)
Anjiang:addSkill(lolDamage)
Anjiang:addSkill(lolBaoJi)

--------------------通用技添加区-----------------------

--盖伦
-- Garen = sgs.General(extension,"Garen","shu",4)

-- lolJianren = sgs.CreateTriggerSkill{
-- 	name = "lolJianren" ,
-- 	events = {sgs.DrawNCards}, --摸牌阶段
-- 	on_trigger = function(self, event, player, data)
-- 		local room = player:getRoom()
-- 		if player:isWounded() then --如果受伤
-- 			--不是很懂为什么要搞个invoked出来
-- 			local invoked = false
-- 			--return false 应该是不能触发的意思
-- 			if player:isSkipped(sgs.Player_Draw) then return false end  --没有跳过摸牌阶段
-- 			invoked = player:askForSkillInvoke(self:objectName())
-- 			if invoked then
-- 				room:broadcastSkillInvoke(self:objectName()) -- 技能音效
-- 				data:setValue(1) --只摸一张牌
-- 				local recover = sgs.RecoverStruct()
-- 				recover.who = player
-- 				room:recover(player,recover) --恢复一点体力
-- 			end
-- 		end
-- 	end
-- }

-- lolZhengyi = sgs.CreateTriggerSkill{
-- 	name = "lolZhengyi",	
-- 	frequeny = sgs.Skill_Limited, 
-- 	events = {sgs.Damaged},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local damage = data:toDamage()
-- 		local victim = damage.to
-- 		local me = room:findPlayerBySkillName(self:objectName())
-- 		if victim:objectName() ~= me:objectName() and victim:getHp() == 1 
-- 			and me:getMark("@Justice")>0 then
-- 			ai_data = sgs.QVariant()
-- 			ai_data:setValue(victim)
-- 			if room:askForSkillInvoke(me,self:objectName(),ai_data) then
-- 				me:loseMark("@Justice")
-- 				local damage = sgs.DamageStruct()
-- 				damage.from = me
-- 				damage.to = victim
-- 				damage.damage = 1
-- 				room:damage(damage)
-- 			end
-- 		end
-- 	end,	
-- 	can_trigger = function(self,target)
-- 		return target
-- 	end
-- }

-- lolZhengyiPlus = sgs.CreateTriggerSkill{
-- 	name = "#lolZhengyiPlus",	
-- 	events = {sgs.GameStart},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		player:gainMark("@Justice",1)
-- 	end,	
-- }
-- --成功喽！！！

-- Garen:addSkill(lolJianren)
-- Garen:addSkill(lolZhengyi)
-- Garen:addSkill(lolZhengyiPlus)
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

lolSishen = sgs.CreateZeroCardViewAsSkill{
	name = "lolSishen",
	-- relate_to_place = deputy,	
	-- response_pattern = "",		
	view_as = function(self)
		local vs = lolSishenCard:clone()
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@NasusR")>0
	end,
}

lolSishenTime = timeStar("SishenTime")

lolNasusR = Rset("#lolNasusR","@NasusR")

Nasus:addSkill(lolJihun)
Nasus:addSkill(lolSishen)
Nasus:addSkill(lolSishenTime)
Nasus:addSkill(lolNasusR)

--[[
lolJihunSlash = sgs.CreateTriggerSkill{
	name = "#lolJihunSlash",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.by_user then return false end -- 如果没有伤害来源，那就算了吧
		if damage.from and damage.card and damage.card:isKindOf("Slash") then -- 若果是杀造成的伤害
			local count = damage.from:getMark("@getSoul") -- 获取标记数量
			room:notifySkillInvoked(damage.from,self:objectName())
			damage.damage = damage.damage + count -- 增加伤害
			data:setValue(damage)
			room:broadcastSkillInvoke(lolJihunSlash)
		end
		return false
	end,
}]]--

--Nasus:addSkill(lolJihunSlash)
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

lolJiushu = sgs.CreateViewAsSkill{
	name = "lolJiushu",
	n = 0, -- 不用牌
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolJiushuCard")  --只能用一次
	end,
	view_filter = function(self,selected,to_select)
		return #selected == 0 -- 只能选择一名角色
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return lolJiushuCard:clone()
		else
			return nil
		end
	end
}

lolQidao = sgs.CreateTriggerSkill{
	name = "lolQidao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		-- 如果我的装备区失去了牌
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0,move.card_ids:length() - 1,1 do -- 每一张牌发动一次效果
				if not player:isAlive() then return false end -- 我要是死了就算了
				if move.from_places:at(i) == sgs.Player_PlaceEquip then -- 如果是从装备去丢的
					if room:askForSkillInvoke(player,self:objectName()) then 
						room:broadcastSkillInvoke(self:objectName())
						local recover = sgs.RecoverStruct() -- 恢复1点血
						recover.who = player
						room:recover(player,recover)
					else
						break -- 不发动就算了
					end
				end
			end
		end
		return false
	end,
}

Soroka:addSkill(lolJiushu)
Soroka:addSkill(lolQidao)
--易大师
-- MasterYi = sgs.General(extension,"MasterYi","wei",3)

LuaYingzi = sgs.CreateTriggerSkill{
	name = "LuaYingzi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, "LuaYingzi", data) then
			room:broadcastSkillInvoke(self:objectName())
			local count = data:toInt() + 1
			data:setValue(count)
		end
	end
}

Anjiang:addSkill(LuaYingzi)

-- lolWuji = sgs.CreateTriggerSkill{
-- 	name = "lolWuji",
-- 	frequency = sgs.Skill_Wake,
-- 	events = {sgs.EventPhaseStart}, -- 回合开始时
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		room:addPlayerMark(player,"Wuju") --添加标记
-- 		if room:changeMaxHpForAwakenSkill(player) then -- 觉醒技改变体力上限。顺便获得觉醒标记
-- 			room:broadcastSkillInvoke(self:objectName())
-- 			room:doSuperLightbox("MasterYi","lolWuji") -- 加特效“DUANG”
-- 			room:detachSkillFromPlayer(player,"lolMingxiang") -- 失去冥想
-- 			room:handleAcquireDetachSkills(player,"wusheng|paoxiao|LuaYingzi|mashu") -- 获得技能
-- 		end
-- 		return false
-- 	end,
-- 	can_trigger = function(self,target)
-- 		return (target and target:isAlive() and target:hasSkill(self:objectName()))
-- 				and (target:getMark("Wuju") == 0)
-- 				and (target:getPhase() == sgs.Player_Start)
-- 				and (target:getHp() == 1)
-- 	end
-- }

-- lolMingxiang = sgs.CreateTriggerSkill{
-- 	name = "lolMingxiang",
-- 	events = {sgs.EventPhaseStart},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		if player:getPhase() == sgs.Player_Finish then -- 结束阶段开始时
-- 			if player:isWounded() then -- 如果你已受伤
-- 				if player:askForSkillInvoke(self:objectName(),data) then
-- 					room:broadcastSkillInvoke(self:objectName())
-- 					local recover = sgs.RecoverStruct() -- 恢复1血
-- 					recover.who = player
-- 					room:recover(player,recover)
-- 					player:turnOver() -- 翻面
-- 				end
-- 			end
-- 		end
-- 	end,
-- }

-- MasterYi:addSkill(lolWuji)
-- MasterYi:addSkill(lolMingxiang)
--武器
Jax = sgs.General(extension,"Jax","qun",4)

-- lolZongshi = sgs.CreateTriggerSkill{
-- 	name = "lolZongshi",
-- 	frequency = Skill_NotFrequent,
-- 	events = {sgs.CardUsed,sgs.SlashMissed}, -- 使用牌，杀被闪掉了

-- 	on_trigger = function(self, event, player, data)
-- 		local room = player:getRoom()
-- 		if event == sgs.CardUsed then
-- 			local use = data:toCardUse()
-- 			if use.card:isKindOf("Slash") then -- 如果用的是杀
-- 				if player:askForSkillInvoke(self:objectName(),data) then
-- 					room:broadcastSkillInvoke(self:objectName())
-- 					player:drawCards(1) --摸一张牌
-- 					--不计入出牌次数
-- 					room:addPlayerHistory(player, use.card:getClassName(),-1)
-- 				end
-- 			end
-- 		end
-- 		if event == sgs.SlashMissed then -- 如果被闪掉了
-- 			-- 不能用杀
-- 			room:setPlayerCardLimitation(player,"use","Slash|.|.|.|.",true)
-- 		end
-- 	end,
-- 	can_trigger =  function(self,target)
-- 		if target:hasSkill(self:objectName()) then
-- 			if target:isAlive() then
-- 				return target:getPhase() == sgs.Player_Play -- 出牌阶段才能用
-- 			end
-- 		end
-- 	end
-- }

lolZongshi = sgs.CreateTriggerSkill{
	name = "lolZongshi",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused,sgs.EventPhaseStart},
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
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				room:setPlayerMark(player,"zongshi",0)
			end
		end
	end,	
}

lolZongshiPuls = sgs.CreateTargetModSkill{
	name = "#lolZongshiPuls",
	frequency = sgs.Skill_Compulsory,
	pattern = "Slash",	
	distance_limit_func = function(self,player,card)
		
	end,
	residue_func = function(self,player)
		return player:getMark("zongshi")
	end,
	extra_target_func = function(self,player)
		
	end,
}

Jax:addSkill(lolZongshi)
Jax:addSkill(lolZongshiPuls)
--皇子
-- JarvanIV = sgs.General(extension,"JarvanIV$","shu",4)

-- lolZhanqi = sgs.CreateTargetModSkill{
-- 	name = "lolZhanqi",
-- 	frequency = sgs.Skill_NotCompulsory,
-- 	residue_func = function(self,player)
-- 		if player:hasSkill(self:objectName()) then
-- 			return 1 -- 多用一张杀
-- 		else
-- 			return 0
-- 		end
-- 	end
-- }

-- lolZhanqiclear = sgs.CreateTriggerSkill{
-- 	name = "#lolZhanqiclear",
-- 	frequency = sgs.Skill_Compulsory,
-- 	events = {sgs.EventPhaseStart}, -- 阶段开始时
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local phase = player:getPhase()
-- 		if phase == sgs.Player_Finish then -- 结束阶段
-- 			if player:hasSkill("lolZhanqi") then
-- 				room:detachSkillFromPlayer(player,"lolZhanqi") -- 失去技能
-- 				room:setPlayerMark(player,"@zhanqi",0) --标记清零
-- 			end
-- 		end
-- 	end,
-- }

-- Anjiang:addSkill(lolZhanqi)
-- Anjiang:addSkill(lolZhanqiclear)

-- lolDilieCard = sgs.CreateSkillCard{
-- 	name = "lolDilieCard",
-- 	target_fixed = false,
-- 	will_throw = true,
-- 	filter = function(self,targets,to_select)
-- 		return to_select:getKingdom() == "shu" -- 必须是“蜀”角色
-- 	end,
-- 	on_use = function(self,room,source,targets)
-- 		local room = source:getRoom() 
-- 		for _,p in ipairs(targets) do
-- 			room:acquireSkill(p,"lolZhanqi") -- 加战旗技能
-- 			room:acquireSkill(p,"#lolZhanqiclear") -- 加战旗清除技
-- 			p:gainMark("@zhanqi") -- 加战旗标记
-- 		end
-- 	end,
-- }

-- lolDilie = sgs.CreateOneCardViewAsSkill{
-- 	name = "lolDilie",
-- 	filter_pattern = "BasicCard,EquipCard|red", -- 红色装备或基本牌
-- 	view_as = function(self,card)
-- 		local dilie_card = lolDilieCard:clone()
-- 		dilie_card:addSubcard(card:getId())
-- 		dilie_card:setSkillName("lolDilie")
-- 		return dilie_card
-- 	end,
-- 	enabled_at_play = function(self,player)
-- 		-- 可以弃牌，没有用过此技能卡
-- 		return player:canDiscard(player,"he") and not player:hasUsed("#lolDilieCard")
-- 	end
-- }

-- lolTianbeng = sgs.CreateTriggerSkill{
-- 	name = "lolTianbeng$", -- 主公技
-- 	frequency = sgs.Skill_Wake, -- 觉醒技
-- 	events = {sgs.EventPhaseStart}, --阶段开始
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local can_invoke = false
-- 		local kingdoms = 0
-- 		for _,p in sgs.qlist(room:getAlivePlayers()) do -- 获取场上蜀势力角色数
-- 			if p:getKingdom() == "shu" then
-- 				kingdoms = kingdoms + 1
-- 			end
-- 		end
-- 		if kingdoms == 1 and player:getKingdom() == "shu" then -- 如果就我一个是蜀势力
-- 			can_invoke = true
-- 		end
-- 		if can_invoke and player:isLord() then -- 如果我是主公
-- 			room:broadcastSkillInvoke(self:objectName())
-- 			room:doSuperLightbox("JarvanIV","lolTianbeng")
-- 			room:addPlayerMark(player,"lolTianbeng") -- 获得标记
-- 			room:addPlayerMark(player,"@waked") -- 觉醒
-- 			room:acquireSkill(player,"wushuang") -- 获得无双
-- 		end
-- 	end,
-- 	can_trigger = function(self,target)
-- 		return target and (target:getPhase()==sgs.Player_Start) --回合开始
-- 						and target:hasLordSkill("lolTianbeng") -- 有这么个主公技
-- 						and target:isAlive() -- 我还活着
-- 						and (target:getMark("lolTianbeng")==0) -- 还没觉醒
-- 	end
-- }

-- JarvanIV:addSkill(lolDilie)
-- JarvanIV:addSkill(lolTianbeng)
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
				local card = room:askForCard(player,".|.|.|hand","@lolQianbian",sgs.QVariant(),sgs.Card_MethodNone)
				if card then 
					player:addToPile("hou",card,false) -- 加到牌堆里
					room:broadcastSkillInvoke(self:objectName())
				end
			end
		end
	end,
}

lolWanhua = sgs.CreateTriggerSkill{
	name = "lolWanhua",
	events = {sgs.DamageInflicted}, -- 什么鬼
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local hou = player:getPile("hou")
		-- 如果我还活着，如果不是我在自残
		if source and source:isAlive() and source:objectName() ~= player:objectName() then
			if hou:length() == 1 then -- 就一张牌
				if player:askForSkillInvoke(self:objectName(),data) then
					room:broadcastSkillInvoke(self:objectName())
					local id = hou:first()
					local card = sgs.Sanguosha:getCard(id)
					local suit = card:getSuit()
					room:throwCard(card,nil,nil) -- 丢掉
					if suit == sgs.Card_Heart then -- 如果是红桃
					--player:clearOnePrivatePile("hou")
						room:loseHp(source) -- 伤害来源失去一点体力
						return true -- 结束结算
					end
				end	
			end
		end
		
	end,
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

--[[
lolHanyuCard = sgs.CreateSkillCard{
	name = "lolHanyuCard",
	target_fixed = false,
	filter = function(self,targets,to_select)
		if to_select:objectName() == sgs.Self:objectName() then return false end
		if to_select:isAllNude() then return false end
		return #targets == 0
	end,
	on_use = function(self,room,source,targets)
		local target = targets[1]
		if source:isAlive() and target:isAlive() and source:canDiscard(target,"hej") then
			local card_id = room:askForCardChosen(source,target,"hej",self:objectName())
			room:throwCard(card_id,target,source)
		end
	end,
}
]]--

lolHanyu = sgs.CreateViewAsSkill{
	name = "lolHanyu",
	n = 0,
	view_filter = function(self,selected,to_select)
		return #selected == 0 -- 只选择一张牌
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			-- 视为 过河拆桥
			local vs_card = sgs.Sanguosha:cloneCard("dismantlement",sgs.Card_NoSuit,0)
			vs_card:setSkillName("lolHanyu") -- 设置发动技能名
			return vs_card
		else
			return nil
		end
	end,
	enabled_at_play = function(self,player)
		-- 如果没有标志，使用次数小于4
		return not player:hasFlag("cannt") and player:getMark("@coldPrison") < 3 
	end,
}

lolHanyucan = sgs.CreateTriggerSkill{
	name = "#lolHanyucan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.EventPhaseStart}, -- 使用卡牌时，阶段开始时
	on_trigger = function(self,event,player,data)
		if event == sgs.CardUsed then -- 如果时使用卡牌时
			local room = player:getRoom()
			local use = data:toCardUse()
			-- 如果用的时 过河拆桥
			if use.card:isKindOf("Dismantlement") and use.from == player
				and use.card:getSuit() == sgs.Card_NoSuit then
				player:gainMark("@coldPrison") -- 获得标记计数
				local players = room:getAlivePlayers() -- 获取场上活着的人数
				local alives = players:length()
				local border = alives*4 -- 界线
				local total = 0
				-- 计算卡牌总数
				for _,p in sgs.qlist(players) do
					total = total + p:getCards("hej"):length()
				end
				-- 超过界线了，就给个标记
				if total <= border and not player:hasFlag("cannt") then
					room:setPlayerFlag(player,"cannt")
				end
			end
		elseif event == sgs.EventPhaseStart then -- 如果时阶段开始时
			local room = player:getRoom()
			if player:getPhase() == sgs.Player_Play then -- 如果是出牌阶段
				room:setPlayerMark(player,"@coldPrison",0) -- 清零标记
				-- 又来计算一遍
				local players = room:getAlivePlayers()
				local alives = players:length()
				local border = alives*4+1
				local total = 0
				for _,p in sgs.qlist(players) do
					total = total + p:getCards("hej"):length()
				end
				-- 一样的，超标了给标记
				if total <= border then
					room:setPlayerFlag(player,"cannt")
				end
			end
		end
	end,
}

lolHanyuplus = sgs.CreateTriggerSkill{
	name = "#lolHanyuplus",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected}, -- 卡牌生效时
	
	on_trigger = function(self,target)
		local effect = data:toCardEffect() -- 获取生效结构体
		local card = effect.card
		local source = effect.from
		if source and source:hasSkill(self:objectName()) then -- 如果来源拥有本技能
			if card:isKindOf("Dismantlement") then -- 如果是 过河拆桥
				local point = card:getNumber()
				local suit = card:getSuit()
				if point == 0 and suit == sgs.Card_NoSuit then -- 如果是技能牌
					card:setCancelable(false) -- 不可被无懈可击
					effect.card = card
					data:setValue(effect) -- 设置生效结构体
				end
			end
		end
	end,
}

Sejuani:addSkill(lolHanyu)
Sejuani:addSkill(lolHanyucan)
Sejuani:addSkill(lolHanyuplus)
--吸血鬼
Vladimir = sgs.General(extension,"Vladimir","qun",4)

lolXueqi = sgs.CreateTriggerSkill{
	name = "lolXueqi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage}, -- 受伤时
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		if me:isAlive() then
			room:broadcastSkillInvoke(self:objectName())
			
			me:drawCards(1) -- 伤一次血，摸1张牌
		end
	end,
	can_trigger = function(self,target)
		return target:isAlive() -- 我活着就行了，其他角色的回合也是可以的
	end
}

Vladimir:addSkill(lolXueqi)

Lux = sgs.General(extension,"Lux","qun",3,false)

lolGuangfuCard = sgs.CreateSkillCard{
	name = "lolGuangfuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		if #targets == 0 then--如果只需要选择一个目标
			if to_select:objectName() ~= sgs.Self:objectName() then--其他角色
				return not sgs.Self:inMyAttackRange(to_select)--不在我的攻击范围
			end
		end
		return false
	end,
	on_use = function(self,room,source,targets)
		local target = targets[1]
		if not target:hasSkill("qianxun") then--如果目标角色没有“谦逊”
			local can = true
			local dtk = target:getCards("j")--获取目标判定区
			--检测判定区是否有乐不思蜀
			for _,c in sgs.qlist(dtk) do
				if c:isKindOf("Indulgence") then
					can = false
				end
			end
			if can then --如果没有
				room:setPlayerFlag(target,"GuangfuTarget")--设置技能标志1
				room:setPlayerFlag(source,"GuangfuIndulgence")--设置技能标记2
				room:askForUseCard(source,"@@lolGuangfu","@lolGuangfu")--要求使用技能卡
			end
		end
	end
}

lolGuangfuIndulgenceCard = sgs.CreateSkillCard{
	name = "lolGuangfuIndulgenceCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select)
		return to_select:hasFlag("GuangfuTarget")	--如果目标有技能标签1
	end,
	on_use = function(self,room,source,targets)
		local target = targets[1]
		local subcards = self:getSubcards() 
		local id = subcards:first()
		local card = sgs.Sanguosha:getCard(id) -- 获取卡牌
		local suit = card:getSuit()
		local point = card:getNumber()
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",suit,point) --创建虚拟卡牌
		indulgence:addSubcard(card) -- 添加子卡
		indulgence:setSkillName("lolGuangfu") -- 设置创建卡牌的技能名
		local use = sgs.CardUseStruct() --使用卡牌
		use.from = source
		use.to:append(target)
		use.card = indulgence
		room:useCard(use,true)
	end,
}

lolGuangfu = sgs.CreateViewAsSkill{
	name = "lolGuangfu",
	n = 1,
	view_filter = function(self,selected,to_select)
		if sgs.Self:hasFlag("GuangfuIndulgence") then--如果我有技能标签2
			return #selected == 0 and to_select:isRed()--可以选择一张红色牌
		else 
			return false--否则不能选牌
		end
	end,
	view_as = function(self,cards)
		if sgs.Self:hasFlag("GuangfuIndulgence") then--若果我有技能标签2
			if #cards == 1 then--已选择一张卡牌
				local card = cards[1]
				local vs_card = lolGuangfuIndulgenceCard:clone()--创建乐不思蜀技能卡
				vs_card:addSubcard(card)
				return vs_card
			end
		else
			if #cards == 0 then--如果没有选择卡牌
				return lolGuangfuCard:clone()--创建技能卡
			end
		end
	end,
	enabled_at_play = function(self,player)
		if player:hasFlag("GuangfuIndulgence") then--如果我有技能标签2
			return false--不能主动使用
		else
			return not player:hasUsed("#lolGuangfuCard")--条件：我没有使用技能卡
		end
	end,
	enabled_at_response = function(self,player,pattern)
		if player:hasFlag("GuangfuIndulgence") then--如果我有技能标签2
			return pattern == "@@lolGuangfu"--响应技能
		else
			return false--否则不能响应
		end
	end,
}

lolJiguangCard = sgs.CreateSkillCard{
	name = "lolJiguangCard",
	target_fixed = false, 
	will_throw = true, --丢掉
	filter = function(self,targets,to_select)
		if #targets == 0 then
			return to_select:getHp() == 1 --体力值为1的武将
		end
	end,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("lolJiguang")
		room:throwCard(self,source) -- 丢弃这张牌
		local damage = sgs.DamageStruct() -- 制造1点伤害
		damage.from = source
		damage.to = targets[1]
		room:damage(damage)
	end,
}

lolJiguang = sgs.CreateOneCardViewAsSkill{
	name = "lolJiguang",
	filter_pattern = "TrickCard|red", --红色锦囊牌
	view_as = function(self,card)
		local vs_card = lolJiguangCard:clone() -- 创建虚拟卡牌
		vs_card:addSubcard(card)
		vs_card:setSkillName("lolJiguang")
		return vs_card
	end,
	enabled_at_play = function(self,player)
		-- 可以弃牌，没有用过此技能卡
		return player:canDiscard(player,"he") and not player:hasUsed("#lolJiguangCard")
	end,	
}

Lux:addSkill(lolGuangfu)
Lux:addSkill(lolJiguang)

Olaf = sgs.General(extension,"Olaf","wei",4)

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

lolMingyunCard = sgs.CreateSkillCard{
	name = "lolMingyunCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self,room,source,targets)
		local id = room:drawCard()
		local card = sgs.Sanguosha:getCard(id)
		local move = sgs.CardsMoveStruct()
		local move2 = sgs.CardsMoveStruct()
		move.card_ids:append(id)
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(),self:objectName(), "")
		move.to_place = sgs.Player_PlaceTable
		room:moveCardsAtomic(move,true)
		room:getThread():delay()
		move2 = move
		move2.to_place = sgs.Player_PlaceHand
		move2.to = source
		room:moveCardsAtomic(move2,true)
		local suit = card:getSuit()
		if suit == sgs.Card_Heart then
			room:setPlayerFlag(source,"heart")
		elseif suit == sgs.Card_Spade then
			room:setPlayerFlag(source,"spade")
		elseif suit == sgs.Card_Diamond then
			room:setPlayerFlag(source,"diamond")
		elseif suit == sgs.Card_Club then
			room:setPlayerFlag(source,"club")
		end
		room:setPlayerFlag(source,"MingyunUse")
	end,
}

lolMingyun = sgs.CreateViewAsSkill{
	name = "lolMingyun",
	n = 1,
	view_filter = function(self,selected,to_select)
		if sgs.Self:hasFlag("heart") then -- 如果有红色标记
			return to_select:getSuit() == sgs.Card_Heart -- 花色必须是红桃
		elseif sgs.Self:hasFlag("spade") then -- 如果有黑色标记
			return to_select:getSuit() == sgs.Card_Spade -- 花色必须是黑桃
		elseif sgs.Self:hasFlag("diamond") then
			return to_select:getSuit() == sgs.Card_Diamond
		elseif sgs.Self:hasFlag("club") then
			return to_select:getSuit() == sgs.Card_Club
		else
			return false -- 不可选牌
		end
	end,
	view_as = function(self,cards)
		if sgs.Self:hasFlag("MingyunUse") then -- 如果有标记
			if #cards == 1 then -- 如果选了一张牌
				local card = cards[1] -- 获取卡牌信息
				local suit = card:getSuit()
				local point = card:getNumber()
				local id = card:getId()
				if suit == sgs.Card_Heart then -- 如果花色为红桃
					local vs_card = sgs.Sanguosha:cloneCard("ex_nihilo",suit,point) -- 视为 无中生有
					vs_card:addSubcard(id)
					vs_card:setSkillName("lolMingyun")
					return vs_card
				elseif suit == sgs.Card_Spade then -- 如果花色为黑桃
					local vs_card = sgs.Sanguosha:cloneCard("dismantlement",suit,point) -- 视为 过河拆桥
					vs_card:addSubcard(id)
					vs_card:setSkillName("lolMingyun")
					return vs_card
				elseif suit == sgs.Card_Diamond then
					local vs_card = sgs.Sanguosha:cloneCard("indulgence",suit,point) -- 视为 过河拆桥
					vs_card:addSubcard(id)
					vs_card:setSkillName("lolMingyun")
					return vs_card
				elseif suit == sgs.Card_Club then
					local vs_card = sgs.Sanguosha:cloneCard("savage_assault",suit,point) -- 视为 过河拆桥
					vs_card:addSubcard(id)
					vs_card:setSkillName("lolMingyun")
					return vs_card	
				end
			end
		else
			if #cards == 0 then -- 如果没选手牌
				local card = lolMingyunCard:clone() -- 命运牌判定
				return card
			end
		end
	end,
}

Twisted:addSkill(lolMingyun)

Udyr = sgs.General(extension,"Udyr","wei",4)
Udyr_tiger = sgs.General(extension,"Udyr_tiger","shu",4,true,true,true)
Udyr_turtle = sgs.General(extension,"Udyr_turtle","wu",4,true,true,true)
Udyr_bear = sgs.General(extension,"Udyr_bear","wei",4,true,true,true)
Udyr_Phoenix = sgs.General(extension,"Udyr_Phoenix","shu",4,true,true,true)

Udyr_tiger:addSkill("wusheng")
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
					room:judge(judge) -- 进行判定
				end	
			end
		-- 判定完成时
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge() -- 获取判定结构体
			-- 如果时此技能发动的判定
			if judge.reason == self:objectName() then
				-- 询问触发技能
				if player:askForSkillInvoke(self:objectName(),data) then
					-- 获取判定牌花色
					local card = judge.card 
					local suit = card:getSuit()
					-- 依据相应的花色变成相应形态的乌迪尔
					if suit == sgs.Card_Spade then
						room:changeHero(player,"Udyr_tiger",false,false,false,false)
					elseif suit == sgs.Card_Heart then
						room:changeHero(player,"Udyr_turtle",false,false,false,false)
					elseif suit == sgs.Card_Club then
						room:changeHero(player,"Udyr_bear",false,false,false,false)
					elseif suit == sgs.Card_Diamond then
						room:changeHero(player,"Udyr_Phoenix",false,false,false,false)
					end
				end
			end
		end
	end,
}

Udyr_tiger:addSkill(lolSiling)
Udyr_turtle:addSkill(lolSiling)
Udyr_bear:addSkill(lolSiling)
Udyr_Phoenix:addSkill(lolSiling)
Udyr:addSkill(lolSiling)

-- Tryndamere = sgs.General(extension,"Tryndamere","shu",4)

-- lolNuren = sgs.CreateTriggerSkill{
-- 	name = "lolNuren",
-- 	frequency = sgs.Skill_Compulsory,
-- 	events = {sgs.CardUsed,sgs.DamageCaused,sgs.EventPhaseEnd},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		-- 使用杀后改变标记数量
-- 		if event == sgs.CardUsed then -- 使用牌时
-- 			local use = data:toCardUse() -- 获取用牌结构体
-- 			-- 如果牌是杀，牌是我用的
-- 			if use.card:isKindOf("Slash") and use.from == player then
-- 				if player:getMark("@anger") < 4 then -- 如果标记小于4
-- 					player:gainMark("@anger") -- 得到标记
-- 					room:setPlayerMark(player,"calmness",0) -- 清空负面标记
-- 				end
-- 			end
-- 		-- 杀造成伤害进行暴击判定
-- 		elseif event == sgs.DamageCaused then -- 造成伤害时
-- 			local damage = data:toDamage() -- 获取伤害结构体
-- 			if not damage.by_user then return false end -- 天灾就算了
-- 			-- 如果是杀造成的伤害
-- 			if damage.card and damage.card:isKindOf("Slash") then 
-- 				-- 建立判定结构体
-- 				local judge = sgs.JudgeStruct()
-- 				judge.who = player
-- 				judge.good = true
-- 				judge.reason = self:objectName()
-- 				-- 获取标记数量
-- 				local count = damage.from:getMark("@anger")
-- 				-- 依据怒标记数设置判定结果
-- 				if count == 1 then
-- 					judge.pattern = ".|spade" -- 黑桃
-- 				elseif count == 2 then
-- 					judge.pattern = ".|black" -- 黑色
-- 				elseif count == 3 then
-- 					judge.good = false
-- 					judge.pattern = ".|heart" -- 不是红桃
-- 				elseif count == 4 then
-- 					judge.pattern = "." -- 随便啦
-- 				end
-- 				if count > 0 then -- 如果有怒标记就进行判定
-- 					room:judge(judge) -- 进行判定
-- 				end
-- 				if judge:isGood() then -- 如果判定符合
-- 					room:notifySkillInvoked(damage.from,self:objectName())
-- 					damage.damage = damage.damage + 1 -- 增加伤害1点伤害
-- 					data:setValue(damage)
-- 				end
-- 			end
-- 		-- 连续两回合不出杀就失去1枚怒标记
-- 		elseif event == sgs.EventPhaseEnd then -- 阶段结束时
-- 			-- 出牌阶段结束时
-- 			if player:getPhase() == sgs.Player_Play then 
-- 				room:addPlayerMark(player,"calmness") -- 获得一枚负面标记
-- 			end
-- 			-- 如果有至少3枚负面标记
-- 			if player:getMark("calmness") >= 3 then
-- 				player:loseMark("@anger") -- 失去1枚怒标记
-- 			end
-- 			return false
-- 		end
-- 	end,
-- }

-- Tryndamere:addSkill(lolNuren)

Azir = sgs.General(extension,"Azir$","shu",3)

lolJingeCard = sgs.CreateSkillCard{
	name = "lolJingeCard",	
	target_fixed = false,	 -- 需要指定目标
	will_throw = false, -- 不弃置，还要交给目标
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return player:inMyAttackRange(to_select) -- 在我的攻击范围内
		end
	end,
	on_use = function(self,room,source,targets)		
		local target = targets[1] -- 第一个目标
		target:obtainCard(self) -- 获得这张牌
		-- 呼唤目标使用一张杀
		local use = room:askForUseCard(target,"Slash|.|.|.|.","@lolJinge")
		-- 如果目标不杀且有手牌，获得其一张手牌
		if not use and not target:isKongcheng() then 
			local id = room:askForCardChosen(source,target,"h",self:objectName())
			room:obtainCard(source,id,false)
		end
	end,
	on_effect = function(self,effect)
	end,	
}	

lolJinge = sgs.CreateViewAsSkill{
	name = "lolJinge",
	relate_to_place = deputy,	
	response_pattern = "",
	n = 1 , -- 一张牌
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return to_select:isKindOf("Slash") -- 杀
		end
	end,
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end -- 如果选择的不是一张牌，就无法发动
		local jingecard = lolJingeCard:clone() -- 视为技能牌
		jingecard:addSubcard(cards[1])
		return jingecard
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolJingeCard") -- 每回合只能用一次
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}

lolTiema = sgs.CreateTriggerSkill{
	name = "lolTiema",	
	frequeny = sgs.Skill_NotFrequent, 
	events = {sgs.Damaged},
	
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:hasSkill(self:objectName()) and damage.to:askForSkillInvoke(self:objectName(),data) then
			local lose = damage.to:getLostHp()
			damage.to:drawCards(lose,self:objectName())
		end	
	end,	
}

lolFuxingEx = sgs.CreateTriggerSkill{
	name = "#lolFuxingEx$",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		local me = room:findPlayerBySkillName(self:objectName())
		
		if change.to == sgs.Player_NotActive then
			if not player:hasSkill(self:objectName()) and player:getKingdom() == "shu" then
				local playerdata = sgs.QVariant()
				playerdata:setValue(me)
				room:setTag("lolFuxingTarget",playerdata)
			end
		end
		
	end,	
	can_trigger = function(self,target)
		return target
	end
}

lolFuxing = sgs.CreateTriggerSkill{
	name = "lolFuxing$",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if room:getTag("lolFuxingTarget") then
			local target = room:getTag("lolFuxingTarget"):toPlayer()
			room:removeTag("lolFuxingTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
	can_trigger = function(self,target)
			return target and (target:getPhase() == sgs.Player_NotActive)
		end	
}

Azir:addSkill(lolJinge)
Azir:addSkill(lolTiema)
Azir:addSkill(lolFuxing)
Azir:addSkill(lolFuxingEx)

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
--[[
lolChaozaiCard = sgs.CreateSkillCard{
	name = "lolChaozaiCard",	
	target_fixed = true,	 
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		
	end,
	on_use = function(self,room,source,targets)		
		if source:isKongcheng() then return false end
		local cards = source:getCards("h")
		
		source:throwAllHandCardsAndEquips()
		for _,c in ipairs(cards) do
			if c:isRed() then
				source:gainMark("HeavyRain")
			end
		end
	end,
	on_effect = function(self,effect)
		
	end,	
}

lolChaozai = sgs.CreateZeroCardViewAsSkill{
	name = "lolChaozai",
	relate_to_place = deputy,	
	response_pattern = "",		
	view_as = function(self)
		return lolChaozaiCard
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolChaozaiCard")
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}
]]--
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
			if not player:isKongcheng() 
				--触发技能
				and player:askForSkillInvoke(self:objectName(),data) then
				--获取手牌列表
				local cards = player:getCards("h")
				--弃掉所有牌
				player:throwAllHandCardsAndEquips()
				--你弃掉的手牌里每有一张红色牌
				for _,c in sgs.qlist(cards) do
					if c:isRed() then
						--获得一枚标记
						player:gainMark("HeavyRain")
					end
				end
			end
		end
	end,	
}

lolBaoyu = sgs.CreateZeroCardViewAsSkill{
	name = "lolBaoyu",
	relate_to_place = deputy,	
	response_pattern = "",		
	view_as = function(self)
		--视为你是用了杀
		local vs_card = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		vs_card:setSkillName("lolBaoyu")
		return vs_card
	end,
	enabled_at_play = function(self,player)
		-- 你要有标记
		return player:getMark("HeavyRain") > 0
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}

lolBaoyuPlus = sgs.CreateTriggerSkill{
	name = "#lolBaoyuPlus",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed,sgs.EventPhaseEnd},
	--view_as_skill = lolBaoyu,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if use.card:getSuit() == sgs.Card_NoSuit then -- 如果用的是杀
					if player:getMark("HeavyRain") > 0 then --你有标记
						player:loseMark("HeavyRain") -- 失去一枚标记
						--此杀不计入历史
						room:addPlayerHistory(player, use.card:getClassName(),-1)
					end
				else
					room:setPlayerMark(player,"HeavyRain",0)
				end
			end
		elseif event == sgs.EventPhaseEnd then
			--如果你还有标记
			if player:getMark("HeavyRain") > 0 then
				--失去所有标记
				room:setPlayerMark(player,"HeavyRain",0)
			end
		end
	end,	
}

Kaisa:addSkill(lolSuodi)
Kaisa:addSkill(lolChaozai)
Kaisa:addSkill(lolBaoyu)
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
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		return #targets == 0
	end,
	on_use = function(self,room,source,targets)	
		-- 你和目标翻面，目标角色获得一张牌
		source:turnOver()
		targets[1]:turnOver()
		targets[1]:drawCards(1)
	end,
	on_effect = function(self,effect)

	end,	
}

lolPingdeng = sgs.CreateOneCardViewAsSkill{
	name = "lolPingdeng",
	relate_to_place = deputy,	
	response_pattern = "",	
	filter_pattern = "",
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
	enabled_at_response = function(self,player,pattern)
		
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
		source:loseMark("@Garen_R")
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

lolGarenR = Rset("GarenR","@Garen_R")

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
Jiatenghui:addSkill("hongyan")
Yinglili:addSkill("xiaoji")
Yinglili:addSkill("zhenlie")
Shiyu:addSkill("biyue")
Meizhiliu:addSkill("shenxian")
Meizhiliu:addSkill("nosqicai")


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
	end,	
}

Skarner:addSkill(lolJinlile)

-- Saber = sgs.General(extension,"Saber","wei",4,false)

-- fateShiyue = sgs.CreateTriggerSkill{
-- 	name = "fateShiyue",	
-- 	frequeny = sgs.Skill_NotFrequent, 
-- 	events = {sgs.CardUsed},
-- 	--view_as_skill = ,
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		local use = data:toCardUse()
-- 		if use.card:isKindOf("Slash") and use.from == player then
-- 			if player:askForSkillInvoke(self:objectName(),data) then
-- 			end
-- 		end
-- 	end,	
-- }

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
		source:loseMark("@Sheol")
		for _,skill in sgs.qlist(skills) do
			if not skill:inherits("SPConverSkill") then
				room:detachSkillFromPlayer(target,skill:objectName())
			end
		end
		room:acquireSkill(target,"lolMingfu")
		target:gainMark("@Sheol")
	end,
}

lolXingxiang = sgs.CreateTriggerSkill{
	name = "lolXingxiang",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if player:askForSkillInvoke(self:objectName(),data) then
				local players = room:getAlivePlayers()
				local n = 0
				for _,p in sgs.qlist(players) do
					if p:hasSkill(lolMingfu:objectName()) then
						n = n + 1
					end
				end
				local cards = room:getNCards(n)
				room:askForGuanxing(player,cards)
				room:broadcastSkillInvoke("lolMalzahar")
			end
		end
	end,	
}

Malzahar:addSkill(lolMingfuStart)
Malzahar:addSkill(lolMingfu)
Malzahar:addSkill(lolXingxiang)

Draven = sgs.General(extension,"Draven","wei",3)

lolFeifu = sgs.CreateTriggerSkill{
	name = "lolFeifu",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if not use.from:hasSkill(self:objectName()) then
			return false
		end
		if not card:isKindOf("Slash") then
			return false
		end
		if card:isVirtualCard() then
			return false
		end
		if card:hasFlag(self:objectName()) then
			return false
		end
		local id = card:getId()
		room:addPlayerHistory(player,card:getClassName(),-1)
		local color = ""
		if card:isRed() then
			color = "red"
		elseif card:isBlack() then
			color = "black"
		end
		if player:askForSkillInvoke(self:objectName(),data) then
			local judge = sgs.JudgeStruct()
			judge.who = player
			judge.pattern = ".|"..color
			judge.good = true
			judge.reason = self:objectName()
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke("lolDraven")
				room:obtainCard(player,card)
				room:setCardFlag(id,self:objectName())
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
		room:broadcastSkillInvoke("lolDraven")
	end,
	can_trigger = function(self,target)
		return target
	end
}

Draven:addSkill(lolFeifu)
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
				if target:isKongcheng() then
					local judge = sgs.JudgeStruct()
					judge.who = target
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = "Diaup"
					room:judge(judge)
				end
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

lolFengzhan = sgs.CreateTriggerSkill{
	name = "lolFengzhan",	
	frequeny = sgs.Skill_Frequent, 
	events = {sgs.FinishJudge},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local me = room:findPlayerBySkillName(self:objectName())
		local judge = data:toJudge()
		if me:getMark("@YasuoR")==0 then
			return false
		end
		if judge.reason == "Diaup" and judge:isGood() then
		--击飞效果是一个reson为"Diaup"的判定，判定成功则视为判定角色被击飞
			if me:askForSkillInvoke(self:objectName(),data) then
				room:broadcastSkillInvoke("lolFengzhan")
				me:sepak("痛里牙个痛")
				me:gainMark("@Dun")
				room:setPlayerMark(me,"@YasuoR",0)
				local damage = sgs.DamageStruct()
				damage.from = me
				damage.to = judge.who
				damage.damage = 1
				room:damage(damage)
				room:setFixedDistance(me,judge.who,1)
			end
		end
	end,	
	can_trigger = function(self,target)
		return target
	end
}

lolYasuoR = Rset("lolYasuoR","@YasuoR")

Yasuo:addSkill(lolLangke)
Yasuo:addSkill(lolFengzhan)
Yasuo:addSkill(lolYasuoR)
Yasuo:addSkill(lolHuDun)

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
					t:setCardLimitation("response,use","Jink|diamond|.|.|.",true)
				end
			end
		end			
	end,	
}

lolZhuhunCard = sgs.CreateSkillCard{
	name = "lolZhuhun",	
	target_fixed = true,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		room:broadcastSkillInvoke("lolRonghun")
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
		room:broadcastSkillInvoke("lolKassadin")
		local target = targets[1]
		target:gainMark("@skill_invalidity")
		room:setPlayerFlag(target,"lolXuwu")
		if source:getMark("@MoDun") <3 then
			source:gainMark("@MoDun")
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
					p:loseMark("@skill_invalidity")
					room:setPlayerFlag(p,"-lolXuwu")
				end
			end
			room:setPlayerMark(player,"voidWalk",0)
		end
	end,
}

lolXuxingCard = sgs.CreateSkillCard{
	name = "lolXuxingCard",	
	target_fixed = true,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source,targets)		
		room:broadcastSkillInvoke("lolKassadin")
		source:gainMark("voidWalk")
		source:speak("1")
	end,	
}

lolXuxing = sgs.CreateViewAsSkill{
	name = "lolXuxing",
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 1,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return true
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return nil
		end
		local vs_card = lolXuxingCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,		
}

lolXuxingDistance = sgs.CreateDistanceSkill{
	name = "#lolXuxingDistance",
	correct_func = function(self,from,to)
		if from:hasSkill(self:objectName()) then
			if from:getMark("voidWalk")>0 then
				return -from:getMark("voidWalk")
			end
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
			if use.from:hasSkill(self:objectName()) and use.from == player then
				if use.card:isNDTrick() then
					local to = use.to:first()
					if to == player or player:hasFlag(self:objectName()) then
						return false
					end
					if player:askForSkillInvoke(self:objectName(),data) then
						room:broadcastSkillInvoke("lolKassadin")
						room:setPlayerFlag(player,self:objectName())
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
Kassadin:addSkill(lolXuxingDistance)
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
	end,	
}

lolNWuji = sgs.CreateViewAsSkill{
	name = "lolNWuji",
	--relate_to_place = deputy,	
	--response_pattern = "",
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
			killer:gainMark("@Wuju")
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

lolnewYiR = Rset("lolnweYiR","@YiR")

newYi:addSkill(lolNWuji)
newYi:addSkill(lolNWujiplus)
newYi:addSkill(lolNMingxiang)
newYi:addSkill(lolnewYiR)

newJarvanIV = sgs.General(extension,"newJarvanIV$","shu",4)

lolSDilieCard = sgs.CreateSkillCard{
	name = "lolSDilieCard",	
	target_fixed = false,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if sgs.Self:hasLordSkill(lolNTianbeng) then
			return to_select:getKingdom() == "shu"
		else
			return to_select:hasSkill("lolNDilie")
		end
	end,
	on_use = function(self,room,source,targets)	
		room:broadcastSkillInvoke("lolNDilie")
		if #targets == 0 then
			room:setPlayerMark(source,"@zhanqi",1)
		else
			for _,t in ipairs(targets) do
				room:setPlayerMark(t,"@zhanqi",1)
			end
		end
	end,
}

lolMDilieCard = sgs.CreateSkillCard{
	name = "lolMDilieCard",	
	target_fixed = false,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if sgs.Self:hasLordSkill(lolNTianbeng) then
			return to_select:getKingdom() == "shu"
		else
			return to_select:hasSkill("lolNDilie")
		end
	end,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("lolNDilie")
		room:acquireSkill(source,"wushuang")
		room:acquireSkill(source,"mashu")
		room:acquireSkill(source,"#lolChuanJia")
		if #targets == 0 then
			room:setPlayerMark(source,"@zhanqi",1)
		else
			for _,t in ipairs(targets) do
				room:setPlayerMark(t,"@zhanqi",1)
			end
		end
	end,	
}

lolBWDilieCard = sgs.CreateSkillCard{
	name = "lolBWDilieCard",	
	target_fixed = false,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if sgs.Self:hasLordSkill(lolNTianbeng) then
			return to_select:getKingdom() == "shu"
		else
			return to_select:hasSkill("lolNDilie")
		end
	end,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("lolNDilie")
		local players = room:getAlivePlayers()
		local target = room:askForPlayerChosen(source,players,"lolNDilie")
		local id = room:askForCardChosen(source,target,"he","lolNDilie")
		room:throwCard(id,target,source)
		--获得技能
		room:acquireSkill(source,"wushuang")
		room:acquireSkill(source,"mashu")
		room:acquireSkill(source,"#lolChuanJia")
		if #targets == 0 then
			room:setPlayerMark(source,"@zhanqi",1)
		else
			for _,t in ipairs(targets) do
				room:setPlayerMark(t,"@zhanqi",1)
			end
		end
	end,	
}

lolBADilieCard = sgs.CreateSkillCard{
	name = "lolBADilieCard",	
	target_fixed = false,	 
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if sgs.Self:hasLordSkill(lolNTianbeng) then
			return to_select:getKingdom() == "shu"
		else
			return to_select:hasSkill("lolNDilie")
		end
	end,
	on_use = function(self,room,source,targets)	
		room:broadcastSkillInvoke("lolNDilie")
		source:gainMark("@Dun")	
		room:acquireSkill(source,"wushuang")
		room:acquireSkill(source,"mashu")
		room:acquireSkill(source,"#lolChuanJia")
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
	--relate_to_place = deputy,	
	--response_pattern = "",
	n = 1,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			if to_select:isRed() then
				return to_select:isKindOf("BasicCard")
			elseif to_select:isBlack() then
				return to_select:isKindOf("EquipCard")
			end
		end
	end,
	view_as = function(self,cards)
		if #cards == 0 then
			return false
		end
		local card = cards[1]
		local vs_card = nil
		if card:isKindOf("BasicCard") then
			vs_card = lolSDilieCard:clone()
		elseif card:isKindOf("Weapon") then
			vs_card = lolBWDilieCard:clone()
		elseif card:isKindOf("Armor") then
			vs_card = lolBADilieCard:clone()
		else
			vs_card = lolMDilieCard:clone()
		end
		vs_card:addSubcard(card)
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#lolSDilieCard") and not player:hasUsed("#lolBADilieCard")
		 and not player:hasUsed("#lolMDilieCard") and not player:hasUsed("#lolBWDilieCard")
	end,		
} 

lolNZhanqi = sgs.CreateTargetModSkill{
	name = "#lolNZhanqi",
	frequency = sgs.Skill_NotFrequent,
	pattern = "Slash",
	distance_limit_func = function(self,player,card)
		
	end,
	residue_func = function(self,player)
		if player:getMark("@zhanqi")>0 then
			return 1
		end
	end,
	extra_target_func = function(self,player)
		
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
			room:setPlayerMark(player,"@zhanqi",0)
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
		return target:getMark("@zhanqi")>0
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
		if card:isKindOf("Slash") or
		 (card:isNDTrick() and use.from and use.from:objectName() == me:objectName()) then
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

-- loldrawTime = timeEnd("loldrawTime")

newTryndamere = sgs.General(extension,"newTryndamere","shu",4)

lolNNurenCard = sgs.CreateSkillCard{
	name = "lolNNurenCard",	
	target_fixed = true,	 
	will_throw = false,
	on_use = function(self,room,source,targets)		
		room:broadcastSkillInvoke("lolNNuren")
		room:setPlayerMark(source,"@anger",0)
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		room:recover(source,recover)
	end,
}

lolNNuren = sgs.CreateViewAsSkill{
	name = "lolNNuren",
	n = 0,
	view_as = function(self,cards)
		local vs_card = lolNNurenCard:clone()
		vs_card:setSkillName(self:objectName())
		return vs_card
	end,
	enabled_at_play = function(self,player)
		return player:isWounded() and player:getMark("@anger")>=3
	end,		
}	

lolNNurenPassive = sgs.CreateTriggerSkill{
	name = "#lolNNurenPassive",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local me = room:findPlayerBySkillName(self:objectName())
		if use.from and use.from:objectName() == me:objectName() and use.card:isKindOf("Slash") then
			room:setPlayerMark(me,"angerClear",0)
			room:setPlayerFlag(me,"anger")
			if me:getMark("@anger")<4 then
				room:broadcastSkillInvoke("lolNNuren")
				me:gainMark("@anger")
			end
			local count = me:getMark("@anger")
			local judge = sgs.JudgeStruct()
			judge.who = me
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

lolNNurenClear = sgs.CreateTriggerSkill{
	name = "#lolNNurenClear",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("anger") then
				return false
			end
			room:addPlayerMark(player,"angerClear")
			if player:getMark("angerClear") >= 2 and player:getMark("@anger")>0 then
				player:loseMark("@anger")
				room:setPlayerMark(player,"angerClear",1)
			end
		end
	end,	
}

lolBumie = sgs.CreateTriggerSkill{
	name = "lolBumie",	
	frequeny = sgs.Skill_Limited, 
	events = {sgs.AskForPeaches},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		local source = dying.who
		if source:objectName() == player:objectName() then
			if player:getMark("lolBumieTime")==0 and player:getMark("@TryndamereR")>0 then
				if player:askForSkillInvoke(self:objectName(),data) then
					room:broadcastSkillInvoke(self:objectName())
					player:loseMark("@TryndamereR")
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

lolTryndamereR = Rset("lolTryndamereR","@TryndamereR")
lolBumieTime = timeEnd("lolBumieTime")

-- newTryndamere:addSkill(lolDraw)
--ewTryndamere:addSkill(loldrawTime)
newTryndamere:addSkill(lolNNuren)
newTryndamere:addSkill(lolNNurenPassive)
newTryndamere:addSkill(lolNNurenClear)
newTryndamere:addSkill(lolBaoJi)
newTryndamere:addSkill(lolBumie)
newTryndamere:addSkill(lolTryndamereR)
newTryndamere:addSkill(lolBumieTime)

Renekton = sgs.General(extension,"Renekton","wu",4) --鳄霸

lolBaoJunPassive = sgs.CreateTriggerSkill{
	name = "#lolBaoJunPassive",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.CardUsed},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from:objectName() == player:objectName() then
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player,"violentClear",0)
				room:setPlayerFlag(player,"violent")
				if player:getMark("@violent") < 4 then
					player:gainMark("@violent")
				end
			end
		end	
	end,	
}

lolBaoJunClear = sgs.CreateTriggerSkill{
	name = "#lolBaoJunClear",	
	frequeny = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseEnd},
	--view_as_skill = ,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:hasFlag("violent") then
				return false
			end
			room:addPlayerMark(player,"violentClear")
			if player:getMark("violentClear") >= 2 and player:getMark("@violent")>0 then
				player:loseMark("@violent")
				room:setPlayerMark(player,"violentClear",1)
			end
		end
	end,	
}

lolBaoJunSlash = sgs.CreateTriggerSkill{
	name = "#lolBaoJunSlash",
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
					end
				end
			end
		end
	end,	
}	

lolBaoJunCard = sgs.CreateSkillCard{
	name = "lolBaoJunCard",
	target_fixed = false,
	will_throw = true,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		local player = sgs.Self
		if player:getMark("@violent")<2 then
			if #targets == 0 then
				return to_select:hasSkill("lolBaoJun")
			end
		elseif player:getMark("@violent")>= 2 then
			if #targets == 0 then
				return player:canSlash(to_select,nil,true)
			end
		end
	end,
	on_use = function(self,room,source,targets)		
		if source:getMark("@violent")<2 then
			local card = source:getWeapon()
			room:throwCard(card,source,source)	
			local players = room:getOtherPlayers(source)
			local count = 0
			for _,p in sgs.qlist(players) do
				if p:isAlive() and source:distanceTo(p) == 1 then
					count = count + 1
				end
			end
			room:broadcastSkillInvoke("lolBaoJun")
			count = math.min(count,2)
			source:drawCards(count)
		elseif source:getMark("@violent")>= 2 then
			source:loseMark("@violent",2)
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = 1
			room:recover(source,recover)
			for _,t in ipairs(targets) do
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.damage = 1
				damage.card = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				damage.to = t
				room:damage(damage)
				room:broadcastSkillInvoke("lolBaoJun")
			end
		end
	end,	
}

lolBaoJun = sgs.CreateZeroCardViewAsSkill{
	name = "lolBaoJun",
	--relate_to_place = deputy,	
	--response_pattern = "",		
	view_as = function(self)
		return lolBaoJunCard:clone()
	end,
	enabled_at_play = function(self,player)
		if not player:hasUsed("#lolBaoJunCard") then
			if player:getMark("@violent")<2 then
				return player:getWeapon()
			elseif player:getMark("@violent")>=2 then
				return true
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
		source:loseMark("@RenektonR")
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

lolTongzhiTime = timeEnd("lolTongzhiTime")

lolRenektonR = Rset("lolRenektonR","@RenektonR")

Renekton:addSkill(lolBaoJun)
Renekton:addSkill(lolBaoJunPassive)
Renekton:addSkill(lolBaoJunClear)
Renekton:addSkill(lolBaoJunSlash)
Renekton:addSkill(lolBaoJunPassive)
Renekton:addSkill(lolTongzhiTime)
Renekton:addSkill(lolTongzhiPlus)
Renekton:addSkill(lolTongzhi)
Renekton:addSkill(lolRenektonR)

Xreath = sgs.General(extension,"Xreath","wei",9)

lolXuanfaCard = sgs.CreateSkillCard{
	name = "lolXuanfaCard",	
	target_fixed = false,	 
	will_throw = false,
	--handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,player)
		if #targets == 0 then
			return true
		end
	end,
	on_use = function(self,room,source,targets)		
		targets[1]:gainMark("TouYun")
	end,
	on_effect = function(self,effect)
		
	end,	
}

lolXuanfa = sgs.CreateZeroCardViewAsSkill{
	name = "lolXuanfa",
	--relate_to_place = deputy,	
	--response_pattern = "",		
	view_as = function(self)
		return lolXuanfaCard:clone()
	end,
	enabled_at_play = function(self,player)
		return true
	end,
	enabled_at_response = function(self,player,pattern)
		
	end,		
}

Xreath:addSkill(lolXuanfa)
Xreath:addSkill(lolDizzy)

--祭品效果
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
	["newGaren"] = "盖伦",
	["&newGaren"] = "盖伦",
	["#newGaren"] = "德玛西亚之力",
	["@Justice"] = "正义",
	["lolnewJianren"] = "坚韧",
	[":lolnewJianren"] = "锁定技，除你受伤后的下个回合外，回合开始阶段，若你已受伤，你回复一点体力",
	["$lolnewJianren1"] = "正义，与我同在！",
	["$lolnewJianren2"] = "人在塔在",
	["lolNZhengyi"] = "正义",
	[":lolNZhengyi"] = "限定技，出牌阶段，你可对一名与你距离为1的角色造成一点伤害，若该角色已损失至少，此伤害+1。",
	["$lolNZhengyi"] = "别怕，我来了",
	["~newGaren"] = "狡诈恶徒",
	["designer:newGaren"] = "Wargon",
	["cv:newGaren"] = "Miss Baidu",
	["illustrator:newGaren"] = "Riot",
	
	["Nasus"] = "内瑟斯",
	["&Nasus"] = "内瑟斯",
	["#Nasus"] = "沙漠死神",
	["@getSoul"] = "汲魂",
	["lolJihun"] = "汲魂",
	[":lolJihun"] = "锁定技，你杀死一名角色后，你的杀造成的伤害永久+1",
	["$lolJihun1"] = "生是轮回的一部分，而你的这部分，已经结束了",
	["$lolJihun2"] = "死亡与我同在",
	["lolSishen"] = "死神",
	[":lolSishen"] = "限定技，出牌阶段，你可增加1点体力上限并回复1点体力，然后摸1张牌，且接下来的两个回合外，当有角色死亡时，你获得一枚“汲魂”标记",
	["designer:Nasus"] = "Wargon",
	["cv:Nasus"] = "Miss Baidu",
	["illustrator:Nasus"] = "Riot",
	
	["Soroka"] = "索拉卡",
	["&Soroka"] = "索拉卡",
	["#Soroka"] = "众星之子",
	["lolJiushu"] = "救赎",
	[":lolJiushu"] = "出牌阶段限一次，你可自减1点体力，令一名受伤的其他角色恢复至多2点体力。",
	["$lolJiushu"] = "我引领着星光的降临",
	["lolQidao"] = "祈祷",
	[":lolQidao"] = "每当你失去一张装备区的装备牌时，若你已受伤，则你恢复1点体力。",
	["$lolQidao"] = "我的力量，来自众星",
	["designer:Soroka"] = "Wargon",
	["cv:Soroka"] = "Miss Baidu",
	["illustrator:Soroka"] = "Riot",
	
	["newYi"] = "易",
	["&newYi"] = "易",
	["#newYi"] = "无极剑圣",
	["designer:newYi"] = "Wargon",
	["cv:newYi"] = "Miss Baidu",
	["illustrator:newYi"] = "Riot",
	["lolNWuji"] = "无极",
	[":lolNWuji"] = "限定技，你可获得“武圣”“咆哮”“英姿”“马术”两个回合。在此期间你每杀死一名角色，便多延长一个回合。",
	["$lolNWuji"] = "无极之道！",
	["lolNMingxiang"] = "冥想",
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
	[":lolNDilie"] = "出牌阶段，你可弃置一张红色基本牌或黑色武器牌，本回合你可额外使用一张【杀】，若你弃置的是装备牌，你额外获得技能“无双”“马术”以及穿甲效果直至回合结束，若你弃置的是武器牌，可弃置一名角色一张牌，若你弃置的是防具牌，你获得一枚“护盾”。每回合限一次",
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
	[":lolHanyu"] = "出牌阶段，若场上所有区域内的牌数总和大于4X,你可视为对一名角色使用了【过河拆桥】（不可被无懈可击响应），当场上的所有区域内的牌数总和不大于4X，或你在本阶段至少发动了3次此技能时，此技能不能发动直至回合结束。（X为场上存活角色数）",
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
	[":lolXueqi"] = "锁定技，场上每有一名角色受到伤害或恢复体力，你摸一张牌。",
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
	[":lolGuangfu"] = "出牌阶段限一次，你可指定一名不在你攻击范围内的角色，如果其没有被【乐不思蜀】指定，你可将一张红色牌当【乐不思蜀】对其使用。",
	["@lolGuangfu"] = "若果目标角色区域内没有【乐不思蜀】，你才能继续发动此技能。",
	["~lolGuangfu"] = "选择一张红色牌—>点击“确定”",
	["$lolGuangfu"] = "注意战场形势",
	["lolJiguang"] = "极光",
	[":lolJiguang"] = "出牌阶段限一次，你可弃置一张红色锦囊牌对一名只有1点体力的角色造1点伤害。",
	["$lolJiguang"] = "德玛西亚万岁",
	
	["Olaf"] = "奥拉夫",
	["&Olaf"] = "奥拉夫",
	["#Olaf"] = "狂战士",
	["designer:Twisted"] = "Wargon",
	["cv:Twisted"] = "Miss Baidu",
	["illustrator:Twisted"] = "Riot",
	["lolZhushen"] = "诛神",
	[":lolZhushen"] = "摸牌阶段，你多摸X张牌，出牌阶段，你可额外使用X张【杀】（X为你当前已损失体力值-1）",

	["Twisted"] = "崔斯特",
	["&Twisted"] = "崔斯特",
	["#Twisted"] = "卡牌大师",
	["designer:Twisted"] = "Wargon",
	["cv:Twisted"] = "Miss Baidu",
	["illustrator:Twisted"] = "Riot",
	["lolMingyun"] = "命运",
	[":lolMingyun"] = "出牌阶段，你可展示牌堆顶一张牌，并获得之，该回合你可将与该牌相同花色的牌按以下规则使用：黑桃【过河拆桥】  红桃【无中生有】  梅花【南蛮入侵】  方块【乐不思蜀】",
	
	["Udyr"] = "乌迪尔",
	["&Udyr"] = "乌迪尔",
	["&Udyr_tiger"] = "乌迪尔",
	["&Udyr_turtle"] = "乌迪尔",
	["&Udyr_bear"] = "乌迪尔",
	["&Udyr_Phoenix"] = "乌迪尔",
	["#Udyr"] = "兽灵行者",
	["designer:Udyr"] = "Wargon",
	["cv:Udyr"] = "Miss Baidu",
	["illustrator:Udyr"] = "Riot",
	["lolSiling"] = "四灵",
	[":lolSiling"] = "回合开始时，你可进行一次判定，依照判定结果你可进入相应状态：黑桃：“虎”（蜀）（武圣），红桃：“龟”（吴）（八阵），梅花：“熊”（魏）（国色），方块：“凤”（蜀）（火计）",
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
	[":lolNNuren"] = "（被动）锁定技，你使用一张【杀】时获得一枚“怒”标记，最多4枚。你使用【杀】时，若你拥有“怒”标记，则进行一次判定，若符合条件（你的每一张“怒”标记都会为条件增加一种判定花色），此【杀】伤害+1。若你连续两个回合未使用【杀】，你失去一枚“怒”标记。（主动）出牌阶段，若你已受伤且至少拥有3枚“怒”标记，你可失去所有“怒”标记，然后回复1点体力。每回合限一次",
	["lolBumie"] = "不灭",
	[":lolBumie"] = "限定技，当你处于濒死状态时，你可将体力值回复至1点，并摸得两枚“怒”标记，直至你的下个回合结束，你的体力至少为1。此期间你不会因为被动失去“怒”标记。",
	["@TryndamereR"] = "无尽怒火",

	["Azir"] = "阿兹尔",
	["&Azir"] = "阿兹尔",
	["#Azir"] = "沙漠皇帝",
	["designer:Azir"] = "Wargon",
	["cv:Azir"] = "Miss Baidu",
	["illustrator:Azir"] = "Riot",
	["lolJinge"] = "金戈",
	[":lolJinge"] = "出牌阶段限一次，你可交给在你攻击范围内的一名角色一张【杀】，其选择一项：1.使用一张【杀】；2.你获得其一张手牌",
	["lolTiema"] = "铁马",
	[":lolTiema"] = "当你受到伤害时，可以摸X张牌（X为你当前已损失的体力值）",
	["lolFuxing"] = "复兴",
	[":lolFuxing"] = "主公技，其他蜀势力角色回合结束时，你进行一个额外的回合",

	["Kaisa"] = "卡莎",
	["&Kaisa"] = "卡莎",
	["#Kaisa"] = "虚空之女",
	["designer:Kaisa"] = "Wargon",
	["cv:Kaisa"] = "Miss Baidu",
	["illustrator:Kaisa"] = "Riot",
	["lolSuodi"] = "索敌",
	[":lolSuodi"] = "你使用【乐不思蜀】或【兵粮寸断】指定一名角色后，你可令本局游戏你与该角色计算距离时始终为1",
	["lolChaozai"] = "超载",
	[":lolChaozai"] = "出牌阶段开始时，你可弃置所有牌，你以此法每弃置一张红色手牌，获得一枚“暴雨”标记直至回合结束或你是用了一张非“暴雨”杀。",
	["lolBaoyu"] = "暴雨",
	[":lolBaoyu"] = "你可将一枚“暴雨”标记当【杀】使用，此【杀】不计入出牌次数。",

	["Ornn"] = "奥恩",
	["&Ornn"] = "奥恩",
	["#Ornn"] = "山隐之焰",

	["@Sheol"] = "冥府",

	["Draven"] = "德莱文",
	["&Draven"] = "德莱文",
	["#Draven"] = "荣誉行刑官",
	["designer:Draven"] = "Wargon",
	["cv:Draven"] = "Miss Baidu",
	["illustrator:Draven"] = "Riot",
	["lolFeifu"] = "飞斧",
	[":lolFeifu"] = "你使用的【杀】不计入出牌数，且你使用一张【杀】后，可进行一次判定，若判定结果与此【杀】颜色相同，你可将这张【杀】获得。你以此法获得的【杀】不得发动此技能。",
	["lolRongyu"] = "荣誉",
	[":lolRongyu"] = "锁定技，你杀死一名角色后，立即摸3张牌。",

	["Yasuo"] = "亚索",
	["&Yasuo"] = "亚索",
	["#Yasuo"] = "疾风剑豪",
	["designer:Yasuo"] = "Wargon",
	["cv:Yasuo"] = "Miss Baidu",
	["illustrator:Yasuo"] = "Riot",
	["lolLangke"] = "浪客",
	["windBlade"] = "风刃",
	[":lolLangke"] = "你的回合外，每当你用来响应的牌总计达到3张时，你获得两张牌；你的一个回合内，当你总计使用了3张牌时，你可指定一名角色，令其弃置两张手牌，若其因此而失去所有手牌，你可令其进行一次击飞判定，若不为红桃，则判定成功。",
	["lolFengzhan"] = "风斩",
	[":lolFengzhan"] = "限定技，当一名角色的击飞判定成功时，你可对其造成1点伤害，然后你获得1枚“护盾”，且之后与其计算距离时，始终为1。",
	["@Yasuo_E"] = "浪客",
	["@YasuoR"] = "狂风绝息斩",

	["Sion"] = "塞恩",
	["&Sion"] = "塞恩",
	["#Sion"] = "亡灵战神",
	["designer:Sion"] = "Wargon",
	["cv:Sion"] = "Miss Baidu",
	["illustrator:Sion"] = "Riot",
	["lolRonghun"] = "融魂",
	[":lolRonghun"] = "出牌阶段，若你没有“护盾”标记，你可自减1点体力，获得1枚“护盾”标记；当你拥有护盾时，你的【杀】不得被方块【闪】响应",
	["lolZhuhun"] = "铸魂",
	[":lolZhuhun"] = "出牌阶段，若你未受伤，你可弃置一张【桃】，增加1点体力上限，回复1点体力",

	["Kassadin"] = "卡萨丁",
	["&Kassadin"] = "卡萨丁",
	["#Kassadin"] = "虚空行者",
	["designer:Kassadin"] = "Wargon",
	["cv:Kassadin"] = "Miss Baidu",
	["illustrator:Kassadin"] = "Riot",
	["lolXuwu"] = "虚无",
	[":lolXuwu"] = "出排解段，你可沉默一名角色直至回合结束，若你的魔法护盾小于3，你获得1点魔法护盾。每回合限一次",
	["lolXuxing"] = "虚行",
	[":lolXuxing"] = "出牌阶段，你可弃置一张牌，本回合你与其他角色计算距离时便-1",
	["lolXuren"] = "虚刃",
	[":lolXuren"] = "你使用一张非延时类锦囊时，若你不为此锦囊的目标，则你可令此锦囊的第一个目标受到1点伤害，并令此锦囊对其无效。每回合限一次",

	["Maokai"] = "茂凯",
	["&Maokai"] = "茂凯",
	["#Maokai"] = "扭曲树精",
	["designer:Maokai"] = "Wargon",
	["cv:Maokai"] = "Miss Baidu",
	["illustrator:Maokai"] = "Riot",
	["lolShugen"] = "树根",
	[":lolShugen"] = "场上每有人使用一张【杀】或者你使用一张非延时类锦囊时，你获得一枚“树苗”标记，当你拥有3张“树苗”标记时，你失去所有“树苗”标记，获得一枚“树根”标记，拥有“树根”标记时你不能获得“树苗”标记；你使用一张【杀】时，若你拥有“树根”标记且已受伤，你失去“树根”标记，然后回复1点体力。",

	["Renekton"] = "雷克顿",
	["&Renekton"] = "雷克顿",
	["#Renekton"] = "荒漠屠夫",
	["designer:Renekton"] = "Wargon",
	["cv:Renekton"] = "Miss Baidu",
	["illustrator:Renekton"] = "Riot",
	["lolBaoJun"] = "暴君",
	[":lolBaoJun"] = "被动）你使用【杀】时，获得一枚“残暴”标记，最多4枚。你每有连续的两个回合未使用【杀】，你失去一枚“残暴”标记。当你的【杀】造成伤害时，若你至少拥有两枚“残暴”，你可失两枚“残暴”标记，令目标角色翻面。（主动）若你的“残暴”标记不足两枚，且你装备有武器牌，你可弃置此牌，每有1名角色与你距离为1，你摸一张牌（最多两张）。若你的“残暴”值不小于2，你可失去两枚“残暴”标记，对一名攻击范围内可以被【杀】指定的角色造成1点【杀】的伤害。每回合限发动一次主动效果。",
	["#lolBaoJunSlash"] = "暴君",
	["lolTongzhi"] = "统治",
	[":lolTongzhi"] = "限定技，出牌阶段，你可令包括本回合在内的3个回合里，每个回合开始时你获得一枚“残暴”标记（本回合发动时立即获得）。此期间你不会因为被动失去“残暴”标记。",
	["@violent"] = "残暴",
	["@RenektonR"] = "终极统治",

	["Malzahar"] = "玛尔扎哈",
	["&Malzahar"] = "玛尔扎哈",
	["#Malzahar"] = "虚空先知",
	["designer:Malzahar"] = "Wargon",
	["cv:Malzahar"] = "Miss Baidu",
	["illustrator:Malzahar"] = "Riot",
	["lolMingfu"] = "冥府",
	[":lolMingfu"] = "限定技，你可指定一名没有“冥府”技能的角色，令其失去所有技能，获得技能“冥府”",
	["lolXingxiang"] = "星象",
	[":lolXingxiang"] = "回合开始阶段，你可观看排队顶X张牌（X为场上拥有“冥府”技能的角色）",

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



}
	
