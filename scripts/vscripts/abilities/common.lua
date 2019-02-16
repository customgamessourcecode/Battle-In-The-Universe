function teleport(keys)
	local caster = keys.caster
	local postion = keys.target_points[1]
	FindClearSpaceForUnit( caster, postion, false )
end

---返回出生点
function builder_return(keys)
	local caster = keys.caster
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	local spawnEntity = EntityHelper.findEntityByName("hero_spawn_pos_"..tostring(PlayerID))
	if spawnEntity then
		Teleport(caster,spawnEntity:GetAbsOrigin())
	end
end

---创建塔
function tower_build(keys)
	local caster = keys.caster
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	if caster:IsRealHero() then
		Towermgr.create(caster,keys.ability,keys.unitName,keys.target_points[1])
	else
		NotifyUtil.ShowError(PlayerID,"#error_only_hero_can_create",3)
	end
end
---收回塔
function tower_destroy(keys)
	Towermgr.destroy(keys.target,keys.caster)
end
---塔升级
function tower_levelup(keys)
	local caster = keys.caster
	local ability = keys.ability
	local goldCost = ability:GetSpecialValueFor("gold_cost")
	
	local success,tower = Towermgr.upgrade(caster,goldCost)
	if success then
		local path = "particles/econ/events/ti8/hero_levelup_ti8.vpcf"
		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN_FOLLOW,tower)
		
		EmitSoundForPlayer("ui.trophy_levelup",PlayerUtil.GetOwner(tower))
		
		--由于单位变了，通知客户端重新选中新的单位
		SendToClient(tower,"xxdld_tower_upgrade_success",{entity=tower:entindex()})
		
		--由于目前的升级逻辑会替换塔实体，这个技能也就被销毁了，这里也不用升级了
--		ability:UpgradeAbility(true)
	end
end

---禁止塔自动释放技能
function tower_enable_ai(keys)
	local caster = keys.caster
	local enable = keys.enable == 1
	
	if caster._ai then
		caster._ai.disabled = not enable
		if enable then
			caster:RemoveAbility("tower_disable_ai")
			local ability = caster:AddAbility("tower_enable_ai")
			if ability then
				ability:SetLevel(1)
			end
		else
			caster:RemoveAbility("tower_enable_ai")
			local ability = caster:AddAbility("tower_disable_ai")
			if ability then
				ability:SetLevel(1)
			end
		end
	end
end

---碧灵果：增加人口数量
function population_max_upgrade(keys)
	local caster = keys.caster
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	local max,canIncrease = Towermgr.GetPopulationMax(PlayerID)
	if canIncrease then
		local money = GetAbilitySpecialValueByLevel(keys.ability,"money")
		local goldCost = (max - 10 + 1) * money
		
		if PlayerUtil.GetGold(PlayerID) >= goldCost then
			PlayerUtil.SpendGold(PlayerID,goldCost)
			local status,err = pcall(function()
				Towermgr.AddPopulationMax(PlayerID)
				caster:RemoveItem(keys.ability)
				NotifyUtil.BottomUnique(PlayerID,"#info_population_limit_upgraded",3,"yellow")
			end)
			if not status then
				PlayerUtil.AddGold(PlayerID,goldCost)
				DebugPrint(err)
			end
		else
			NotifyUtil.BottomGroupUnique(PlayerID,{"#error_need_more_gold",":"..tostring(goldCost)},3,"yellow")
		end
	else
		NotifyUtil.BottomUnique(PlayerID,"#error_population_reached_limit",3,"yellow")
	end
end

---游戏内抽卡。
--keys:
--quality = 12345...
--gold = 123，金币消耗
--noHigh = 1，不会抽取到比quality高一阶的人物
function draw_card_in_game(keys)
	local quality = keys.quality
	if quality then
		local caster = keys.caster
		local ability = keys.ability
		local gold = keys.gold or 0
		local noHigh = keys.noHigh
		draw.DrawInGame(caster,ability,quality,gold,noHigh == 1)
	end
end

---plus开局抽卡
function draw_card_in_game_plus(keys)
	local item = keys.ability
	local caster = keys.caster
	local names = keys.card
	if names then
		names = Split(names,";")
		if #names > 0 then
			--开局赠送的卡片
			local cards = {}
			for _, name in pairs(names) do
				local data = Cardmgr.GetCard(name)
				if data then
					table.insert(cards,{name=name,data=data})
				end
			end
			draw.ShowGoldDrawResultForClient(PlayerUtil.GetOwnerID(caster),cards,item,true)
		end
	end
end

---箱子随机物品（或者类似的技能随机物品都能用）
--keys:
--item=item1;item2;item3  ，即多个物品之间用分号分隔开即可
function box_random_item(keys)
	local caster = keys.caster
	local ability = keys.ability
	local items = keys.item
	if items and items ~= "" then
		local array = Split(items,";")
		if array and #array > 0 then
			local count = GetAbilitySpecialValueByLevel(ability,"count")
			if count == 0 then
				count = 1
			end
			
			--如果是炼丹操作，则检查施法者是否经过了卡牌等级提升的强化
			if keys.alchemy == 1 then
				local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_danbao");
				if bonusModifier and bonusModifier:GetStackCount() > 0 and RollPercent(bonusModifier:GetStackCount()) then
					count = count * 2
				end
			end
			
			--如果使用的是物品，则添加前先隐藏物品，避免占位
			if ability:IsItem() then
				if not ability:IsStackable() or ability:GetCurrentCharges() == 1 then
					caster:TakeItem(ability)
				end
			end
			
			for var=1, count do
				local itemName = array[RandomInt(1,#array)]
				local item = ItemUtil.AddItem(caster,itemName,true)
				NotifyUtil.ShowSysMsg(PlayerUtil.GetOwnerID(caster),{"#info_got_item","DOTA_Tooltip_ability_"..itemName},3)
				if not item then
					DebugPrint("box_random_item:create item faild.ItemName:"..itemName)
				end
			end
			--如果使用的是物品，添加后，删掉物品或者减少数量
			if ability:IsItem() then
				if not ability:IsStackable() or ability:GetCurrentCharges() == 1 then
					caster:RemoveItem(ability)
				else
					ability:SetCurrentCharges(ability:GetCurrentCharges() - 1)
				end
			end
		end
	end
end

---增加技能点。每次增加一点（暂时没用）
function add_ability_point(keys)
	local item = keys.ability
	local caster = keys.caster
	local PlayerID = PlayerUtil.GetOwnerID(caster)
	local hero = PlayerUtil.GetHero(PlayerID)
	
	local ownedPoints = hero:GetAbilityPoints();
	local needPoints = 0
	local max = hero:GetAbilityCount() - 1
	for index=0, max do
		local ability = hero:GetAbilityByIndex(index)
		if ability then
			if ability:GetLevel() < ability:GetMaxLevel() then
				needPoints = needPoints + ability:GetMaxLevel() - ability:GetLevel()
			end
		end
	end
	
	if needPoints <= ownedPoints then
		NotifyUtil.ShowError(PlayerID,"error_has_none_ability_to_upgrade",2)
		return;
	end
	
	local count = PlayerUtil.getAttrByPlayer(PlayerID,"added_ability_point") or 0
	
	local money = GetAbilitySpecialValueByLevel(item,"money")
	local goldCost = (count + 1) * money
	if PlayerUtil.GetGold(PlayerID) >= goldCost then
		PlayerUtil.SpendGold(PlayerID,goldCost)
		hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
		PlayerUtil.setAttrByPlayer(PlayerID,"added_ability_point",count + 1)
		
		--可叠加的，减少叠加数量
		if item:GetCurrentCharges() > 1 then
			item:SetCurrentCharges(item:GetCurrentCharges() - 1)
		else
			EntityHelper.remove(item)
		end
	else
		NotifyUtil.BottomGroupUnique(PlayerID,{"#error_need_more_gold",":"..tostring(goldCost)},3,"yellow")
	end
end

---纽带：绑定目标施法对象，自动释放增益时只会给目标单位释放。
--目前纽带关系在单位收回的时候并不会记录绑定的目标。
--主要是，一般收回以后目标很可能会发生改变，记录这个的意义不大，还浪费资源。
function tower_autocast_bind_cast(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	---是否要移除已有绑定：切换目标或者重复对自身施法的时候会移除
	local binded = Towermgr.GetTowerKV(caster,"tower_autocast_bind_target")
	if binded then
		--有绑定对象且不是施法者自身时，并且新的目标没有发生变化，则不处理；否者移除已有的效果。
		if binded ~= caster and binded == target then
			return;
		end
		
		caster:RemoveModifierByNameAndCaster("modifier_tower_autocast_bind_caster",caster)
		binded:RemoveModifierByNameAndCaster("modifier_tower_autocast_bind_target",caster)
		
		local pid = Towermgr.GetTowerKV(caster,"tower_autocast_bind_pid")
		if pid then
			ParticleManager:DestroyParticle(pid,true)
		end
		
		Towermgr.SetTowerKV(caster,"tower_autocast_bind_target",nil)
		Towermgr.SetTowerKV(caster,"tower_autocast_bind_pid",nil)
	end
	
	--对施法者自己重复释放，不处理
	if binded == caster then
		return;
	end
	
	--特效id，只有目标和施法者不是同一个的时候才添加特效
	local pid = nil
	if target ~= caster then
		local path = "particles/units/heroes/hero_wisp/wisp_tether.vpcf"
		pid = CreateParticleEx(path,PATTACH_POINT_FOLLOW,caster)
		SetParticleControlEnt(pid,0,caster,PATTACH_POINT_FOLLOW,"attach_hitloc",caster:GetAbsOrigin())
		SetParticleControlEnt(pid,1,target,PATTACH_POINT_FOLLOW,"attach_hitloc",target:GetAbsOrigin())
	end
	
	AddDataDrivenModifier(ability,caster,caster,"modifier_tower_autocast_bind_caster",{})
	AddDataDrivenModifier(ability,caster,target,"modifier_tower_autocast_bind_target",{})
	
	Towermgr.SetTowerKV(caster,"tower_autocast_bind_target",target)
	Towermgr.SetTowerKV(caster,"tower_autocast_bind_pid",pid)
end

---纽带：单位死亡。无论是目标死亡还是施法者死亡，都清空绑定数据
function tower_autocast_bind_died(keys)
	local caster = keys.caster
	
	local modifierCaster = caster:FindModifierByNameAndCaster("modifier_tower_autocast_bind_caster",caster)
	if modifierCaster then
		modifierCaster:Destroy()
	end
	
	local binded = Towermgr.GetTowerKV(caster,"tower_autocast_bind_target")
	if EntityNotNull(binded) then
		local modifierTarget = binded:FindModifierByNameAndCaster("modifier_tower_autocast_bind_target",caster)
		if modifierTarget then
			modifierTarget:Destroy()
		end
	end
	
	local pid = Towermgr.GetTowerKV(caster,"tower_autocast_bind_pid")
	if pid then
		ParticleManager:DestroyParticle(pid,true)
	end
	
	Towermgr.SetTowerKV(caster,"tower_autocast_bind_target",nil)
	Towermgr.SetTowerKV(caster,"tower_autocast_bind_pid",nil)
end

---增加单位护甲，加上以后就不会消失。要移除则使用RemoveCustomArmor
--技能中需要有armor键值来表示要增加的护甲值
--keys:
--ref:护甲关联的modifier，当这个护甲效果是可叠加的时候，需要添加这个参数，这样在实际计算的时候会以这个关联的modifier的叠加层数计算护甲
--key，唯一标识，不能为空，同标识的效果不同时存在，删除的时候也会用到（如果默认用ability去获取技能名字，在删除的时候会找不到ability而出错），一般写技能名字即可。
function AddCustomArmor(keys)
	local caster = keys.cater
	local ability = keys.ability
	local unit = keys.target
	local uniqueKey = keys.key
	if not uniqueKey then
		return;
	elseif type(uniqueKey) ~= "string" then
		uniqueKey = tostring(uniqueKey)
	end
	
	if keys.Target and keys.Target == "CASTER" then
		unit = caster
	end
	CustomArmor.AddAbilityArmor(caster,unit,ability,keys.ref,uniqueKey)
end

---移除该技能对目标增加的单位护甲
function RemoveCustomArmor(keys)
	local unit = keys.target
	local uniqueKey = keys.key
	if not uniqueKey then
		return;
	elseif type(uniqueKey) ~= "string" then
		uniqueKey = tostring(uniqueKey)
	end
	if keys.Target and keys.Target == "CASTER" then
		unit = keys.caster
	end
	CustomArmor.RemoveAbilityAddedArmor(unit,uniqueKey)
end

local AddFireWorkBuff = function(hero)
	local ability = hero:FindAbilityByName("newyear_firework_buff")
	if not ability then
		ability = hero:AddAbility("newyear_firework_buff")
	end
	
	if ability then
		local tooltip = hero:FindModifierByName("modifier_newyear_firework_buff_tooltip")
		if not tooltip then
			tooltip = AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_tooltip",{})
		end
		if tooltip then
			if tooltip:GetStackCount() < 125 then
				tooltip:IncrementStackCount()
			end
			if tooltip:GetStackCount() == 10 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_10_aura",{})
			elseif tooltip:GetStackCount() == 20 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_20_aura",{})
			elseif tooltip:GetStackCount() == 30 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_30_aura",{})
			elseif tooltip:GetStackCount() == 50 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_50_aura",{})
			elseif tooltip:GetStackCount() == 80 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_80_aura",{})
			elseif tooltip:GetStackCount() == 125 then
				AddDataDrivenModifier(ability,hero,hero,"modifier_newyear_firework_buff_125_aura",{})
			end
		else
			DebugPrint("modifier_newyear_firework_buff_tooltip add faild")
		end
	else
		DebugPrint("newyear_firework_buff ability add faild")
	end
end

---春节礼花
function newyear_fireworks(keys)
--	local fireworks = keys.ability
--	local caster = keys.caster
--	local hero = PlayerUtil.GetHero(caster)
--	local PlayerID = PlayerUtil.GetOwnerID(caster)
--	
--	local items = {
--		{"gold10",10},{"gold1",20},
--		{"item_box_jj_equipment_3",20},{"item_box_jj_equipment_4",10},{"item_box_jj_equipment_5",5},
--		{"item_box_base_equipment_3",20},{"item_box_base_equipment_4",10},{"item_box_base_equipment_5",5}
--	}
--	local sumed = 0
--	local sections = {}
--	for _, item in pairs(items) do
--		sumed = sumed + item[2]
--		table.insert(sections,sumed)
--	end
--	
--	local random = RandomInt(1,100)
--	table.insert(sections,random)
--	table.sort(sections)
--	local index = -1
--	for idx, section in pairs(sections) do
--		if section == random then
--			index= idx
--			break;
--		end
--	end
--	if index > 0 then
--		if fireworks:GetCurrentCharges() > 1 then
--			--可叠加的，特殊处理
--			fireworks:SetCurrentCharges(fireworks:GetCurrentCharges() - 1)
--		else
--			caster:RemoveItem(fireworks)
--		end
--		--特效
--		local pid = ParticleManager:CreateParticle( "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_calldown_explosion_fireworks.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
--		ParticleManager:SetParticleControl( pid, 3,caster:GetAbsOrigin() )
--		ParticleManager:SetParticleControlOrientation(pid,3,caster:GetForwardVector(),Vector( 0, 1, 0), Vector( 1, 0, 0 ) );
--		caster:EmitSound("ParticleDriven.Rocket.Explode")
--		
--	
--		local item = items[index]
--		if item then
--			item = item[1]
--			local success = false
--			if "gold1" == item then
--				PlayerUtil.AddGold(PlayerID,10000)
--				NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_gold","10000"},3)
--				success = true
--			elseif "gold10" == item then
--				PlayerUtil.AddGold(PlayerID,100000)
--				NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_gold","100000"},3)
--				success = true
--			else
--				local entity = ItemUtil.AddItem(hero,item,true)
--				if entity then
--					NotifyUtil.ShowSysMsg(PlayerID,{"#info_got_item","DOTA_Tooltip_ability_"..item},3)
--					success = true
--				else
--					DebugPrint("newyear_fireworks create item faild")
--				end
--			end
--			
--			if success then
--				AddFireWorkBuff(hero)
--			end
--		else
--			DebugPrint("newyear_fireworks item not exist")
--		end
--	else
--		DebugPrint("newyear_fireworks random error")
--	end
end