local m = {}

TD_GMAE_MODE_TEST = false
---要忽略的世界
local hideWorld = {
	test = not TD_GMAE_MODE_TEST
}

---卡片最大等级
local CardMaxLevel = 100
---各个品质卡片每一级所需要的经验系数。每一级所需经验为： 等级*经验系数
local QualityLevelRatio = {
	[1] = 10,
	[2] = 30,
	[3] = 100,
	[4] = 300,
	[5] = 1000
}


---世界信息：
--WorldName（比如wdqk：武动乾坤，首字母） = {cardName,cardName,cardName}
local worlds = {}
---卡片信息：
--
--towerName = {
--		grade = 1,2,3,4,5 	等阶/品质
--		element = 1,2,3,4,5  	元素类型
--		ability = {
--			ability1,ability2	 技能名称
--		}
--		world = wdqk 世界名字
--}
local cards = {}

---卡牌升级后，给单位增加的增益技能。这里只记录特殊的，比如金币收益的，丹宝的炼丹，唐心莲的奉献等。
--如果没有记录，则默认就添加上伤害提升效果
local CardLevelupBonusAbility = require("customsys.cardmgr.lvlup_bonus")

---获取某个世界中的所有卡片
--@param #string worldName 世界名称
--@param #number quality 品质。为空则返回所有品质
--@return #table 
--<pre>可能返回nil
--{
--	cardName = {
--		grade = 12345,
--		element = 1,2,3,4,5.. 元素类型
--		ability = {
--			ability1,ability2,... 技能名称
--		}
--		world = wdqk 世界名字
--	}
--}</pre>
function m.GetCardsInWorld(worldName,quality)
	local all = worlds[worldName]
	local result = {}
	local exist = false;
	for _, cardName in pairs(all) do
		local card = cards[cardName]
		if card and (not quality or card.grade == quality) then
			result[cardName] = card
			exist = true;
		end
	end
	if exist then
		return result
	else
		result = nil
	end
end

---获取指定卡片的信息<pre>
--cardName = {
--		grade = 1,2,3,4,5 	等阶/品质
--		element = 1,2,3,4,5  	元素类型
--		ability = {
--			ability1,ability2	 技能名称
--		}
--		world = "wdqk" 世界名字
--}</pre>
function m.GetCard(cardName)
	if cardName then
		return cards[cardName]
	end
end

---计算某个卡片的经验对应的等级，参数错误返回0
function m.CalculateCardLevel(cardName,exp)
	if type(cardName) == "string" and type(exp) == "number" and exp > 0 then
		local cardData = m.GetCard(cardName)
		if cardData and cardData.grade then
			local ratio = QualityLevelRatio[cardData.grade];
			local level = 1
			local allNeedExp = level * ratio;
			while allNeedExp <= exp do
				if level == CardMaxLevel then
					break;
				end
				level = level + 1;
				allNeedExp = allNeedExp + level * ratio;
			end
			return level
		end
	end
	return 0
end

---某个卡片升级后，更新该玩家已经建造的该类型所有单位的属性
function m.UpdateBonusAbility(PlayerID,cardName)
	local cardData = m.GetCard(cardName)
	if cardData and cardData.world then
		local cardExp = PlayerUtil.GetCard(PlayerID,cardData.world,cardName)
		if cardExp and cardExp.exp and cardExp.exp > 0 then
			local level = m.CalculateCardLevel(cardName,cardExp.exp)
			if level > 0 then
				local abilityName = CardLevelupBonusAbility[cardName] or "card_lvlup_bonus_damage"
				local towers = Towermgr.getPlayerTowers(PlayerID)
				if towers then
					for _, unit in pairs(towers) do
						if EntityNotNull(unit) and unit:GetUnitName() == cardName then
							local ability = unit:FindAbilityByName(abilityName)
							if not ability then
								ability = unit:AddAbility(abilityName)
								if ability then
									ability:SetLevel(1)
								end
							end
							
							if ability then
								--使用buff来作为提示和实际技能使用的中转，设置叠加来代表实际的等级
								local modifier = unit:FindModifierByName("modifier_"..abilityName)
								if modifier then
									modifier:SetStackCount(level)
								end
								
								--伤害加深效果用的lua的modifier，除了修改提示buff的叠加，这个luamodifier也要进行叠加
								--获取的方式，参考basic下面的apply_damage_out_buff
								if abilityName == "card_lvlup_bonus_damage" then
									local key = "do_card_lvlup_bonus_damage"
									if EntityNotNull(unit[key]) then
										unit[key]:SetStackCount(level)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

---某个单位被创建的时候，检查是否需要添加等级奖励
function m.AddBonusAbility(unit)
	local cardName = unit:GetUnitName()
	local PlayerID = PlayerUtil.GetOwnerID(unit)
	local cardData = m.GetCard(cardName)
	if cardData and cardData.world then
		local cardExp = PlayerUtil.GetCard(PlayerID,cardData.world,cardName)
		if cardExp and cardExp.exp and cardExp.exp > 0 then
			local level = m.CalculateCardLevel(cardName,cardExp.exp)
			if level > 0 then
				local abilityName = CardLevelupBonusAbility[cardName] or "card_lvlup_bonus_damage"
				if not unit:FindAbilityByName(abilityName) then
					local ability = unit:AddAbility(abilityName)
					if ability then
						ability:SetLevel(1)
						--使用buff来作为提示和实际技能使用的中转，设置叠加来代表实际的等级
						local modifier = unit:FindModifierByName("modifier_"..abilityName)
						if modifier then
							modifier:SetStackCount(level)
						end
						
						--伤害加深效果用的lua的modifier，除了修改提示buff的叠加，这个luamodifier也要进行叠加
						--获取的方式，参考basic下面的apply_damage_out_buff
						if abilityName == "card_lvlup_bonus_damage" then
							local key = "do_card_lvlup_bonus_damage"
							if EntityNotNull(unit[key]) then
								unit[key]:SetStackCount(level)
							end
						end
					end
				end
			end
		end
	end
end

---卡片升级
function m.Client_CardLevelUp(_,keys)
	local PlayerID,cardName,usedExp = keys.PlayerID,keys.name,keys.exp
	if PlayerUtil.IsValidPlayer(PlayerID) then
		local cardData = Cardmgr.GetCard(cardName)
		--卡片名字有误
		if not cardData or not cardData.world then
			return;
		end
		--没有该卡片
		if not PlayerUtil.GetCard(PlayerID,cardData.world,cardName) then
			return;
		end
		
		if PlayerUtil.getAttrByPlayer(PlayerID,"cardmgr_lvlup_ing") then
			return;
		end
		--添加间隔标记
		PlayerUtil.setAttrByPlayer(PlayerID,"cardmgr_lvlup_ing",true)
		TimerUtil.createTimerWithDelay(2,function()
			PlayerUtil.setAttrByPlayer(PlayerID,"cardmgr_lvlup_ing",nil)
		end)
	
		local aid = PlayerUtil.GetAccountID(PlayerID)
		http.load("card_lvlup",{aid=aid,cardname=cardName,exp=usedExp},function(data)
			if data then
				if data.success == "1" then
					local totalExp = data.userExp
					PlayerUtil.SetCardExp(PlayerID,totalExp)
					
					local cardExp = data.cardExp
					local world = Cardmgr.GetCard(cardName)
					if world then
						world = world.world
					end
					if world then
						PlayerUtil.UpdateCard(PlayerID,world,cardName,cardExp)
						SendToClient(PlayerID,"xxdld_cardmgr_level_up_result",{cardName=cardName,exp=cardExp})
						
						m.UpdateBonusAbility(PlayerID,cardName)
					else
						DebugPrint("upgrade error,no world for cardName:"..tostring(cardName))
					end
				end
			end
		end)
	end
end


local init = function()
	local units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for unitName, unit in pairs(units) do
		if unitName ~= "tower_world_name" 
			and unit.tower_attack_element
			and unit.tower_grade then
			
			local worldName = Split(unitName,"_")
			if #worldName >= 3 then
				worldName = worldName[2]
				if not hideWorld[worldName] then
					--存储世界信息
					local towers = worlds[worldName]
					if not towers then
						towers = {}
						worlds[worldName] = towers
					end
					table.insert(towers,unitName)
					
					--存储卡片信息
					local tower = {}
					tower.world = worldName
					tower.grade = tonumber(unit.tower_grade)
					local n = string.gsub(unit.tower_attack_element,"ae_","")
					tower.element = tonumber(n)
					--技能信息。这里只获取了前十个，一般都没有超过。后续数量超过10个了，再加
					tower.ability = {}
					for var=1, 10 do
						local abilityName = unit["Ability"..tostring(var)]
						if abilityName and abilityName ~= "" then
							table.insert(tower.ability,abilityName)
						end
					end
					cards[unitName] = tower
				end
			end
		end
	end
	
	for worldName, cardNames in pairs(worlds) do
		local data = {}
		for _, cardName in pairs(cardNames) do
			data[cardName] = cards[cardName]
		end
		SetNetTableValue("worlds",worldName,data)
	end
	
	--注册监听
	RegisterEventListener("xxdld_cardmgr_level_up",m.Client_CardLevelUp)
	
	Towermgr.RegisterTowerCreatedListener(function(tower)
		if EntityNotNull(tower) then
			m.AddBonusAbility(tower)
		end
	end)
end
init()
return m;