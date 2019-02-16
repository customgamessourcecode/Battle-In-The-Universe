---刘启：资金运营
function liuqi_zjyy_cast(keys)
	--无尽模式不生效
	if Spawner.IsInfinite() then
		return
	end

	local caster = keys.caster
	local ability = keys.ability
	
	--同时只能有一个效果
	if caster:HasModifier("modifier_dzhz_LiuQi_tooltip") then
		return;
	end
	
	local money = GetAbilitySpecialValueByLevel(ability,"gold_cost")
	local duration = GetAbilitySpecialValueByLevel(ability,"delay")
	local bonus = GetAbilitySpecialValueByLevel(ability,"bonus")
	local chance = GetAbilitySpecialValueByLevel(ability,"chance")
	
	if PlayerUtil.GetGold(caster) >= money then
		PlayerUtil.SpendGold(caster,money)
		--添加提示用的buff，并缓存此时的数据。避免升级以后这些数据发生了变化，再收回重新放置单位，从而提高收益
		local modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_dzhz_LiuQi_tooltip",{duration=duration})
		modifier._money = money
		modifier._bonus = bonus
		modifier._chance = chance
		
		--这个延迟使用kv中的处理的话会有问题，要么保存不了数据（保存在modifier中，使用kv的destroy事件来触发的话，触发时modifier已经为空了），
		--要么延迟时间不对（收回重放的时候延迟时间可能变了，用kv的延迟动作就没法动态修改了）
		--所以是用自定义计时器。并保存计时器在modifier里，在收回的时候如果还在运营中，则移除计时器
		modifier._timer = TimerUtil.createTimerWithDelay(duration,function()
			--如果单位已经被收回了就不处理了。
			if not caster:IsAlive() then
				return;
			end
			local PlayerID = PlayerUtil.GetOwnerID(caster)
			
			if RandomLessInt(chance) then
				local profit = math.ceil(money * bonus / 100)
				
				--检查施法者是否经过了卡牌等级提升的强化
				local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
				if bonusModifier and bonusModifier:GetStackCount() > 0 then
					profit = profit * (1 + bonusModifier:GetStackCount() / 100)
				end
				
				local gold = money + profit
				
				
				PlayerUtil.AddGold(PlayerID,gold)
				PopupNum:PopupGoldGain(caster,gold)
				
				NotifyUtil.ShowSysMsg(PlayerID,{caster:GetUnitName(),"ability_liuqi_zjyy_success",tostring(profit)},3)
			else
				NotifyUtil.ShowSysMsg(PlayerID,{caster:GetUnitName(),"ability_liuqi_zjyy_faild"},3)
			end
		end)
	else
		NotifyUtil.ShowError(PlayerUtil.GetOwnerID(caster),"error_need_more_gold",2)
		ability:EndCooldown()
	end
end

---资金运营升级的时候，检查是否有进行中的投资，如果有，添加对应的提示buff。主要用在塔收回第一次放置的时候
function liuqi_zjyy_upgrade(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local remain = Towermgr.GetTowerKV(caster,"liuqi_zjyy_timer_remain")
	if remain and remain > 0 then
		local money = Towermgr.GetTowerKV(caster,"liuqi_zjyy_timer_money")
		local bonus = Towermgr.GetTowerKV(caster,"liuqi_zjyy_timer_bonus")
		local chance = Towermgr.GetTowerKV(caster,"liuqi_zjyy_timer_chance")
		
		--添加提示用的buff，并暂存此时的数据。避免升级以后这些数据发生了变化，再收回重新放置单位，从而提高收益
		local modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_dzhz_LiuQi_tooltip",{duration=remain})
		modifier._money = money
		modifier._bonus = bonus
		modifier._chance = chance
		
		--这个延迟使用kv中的处理的话会有问题，要么保存不了数据（保存在modifier中，使用kv的destroy事件来触发的话，触发时modifier已经为空了），
		--要么延迟时间不对（收回重放的时候延迟时间可能变了，用kv的延迟动作就没法动态修改了）
		--所以是用自定义计时器。并保存计时器在modifier里，在收回的时候如果还在运营中，则移除计时器
		modifier._timer = TimerUtil.createTimerWithDelay(remain,function()
			--如果单位已经被收回了就不处理了。
			if not caster:IsAlive() then
				return;
			end
			local PlayerID = PlayerUtil.GetOwnerID(caster)
			
			if RandomLessInt(chance) then
				local profit = math.ceil(money * bonus / 100)
				
				--检查施法者是否经过了卡牌等级提升的强化
				local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
				if bonusModifier and bonusModifier:GetStackCount() > 0 then
					profit = profit * (1 + bonusModifier:GetStackCount() / 100)
				end
				
				
				local gold = money + profit
				PlayerUtil.AddGold(PlayerID,gold)
				PopupNum:PopupGoldGain(caster,gold)
				
				NotifyUtil.ShowSysMsg(PlayerID,{caster:GetUnitName(),"ability_liuqi_zjyy_success",tostring(profit)},3)
			else
				NotifyUtil.ShowSysMsg(PlayerID,{caster:GetUnitName(),"ability_liuqi_zjyy_faild"},3)
			end
		end)
		
		--清空暂存数据，避免升级再次使用
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_remain",nil)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_money",nil)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_bonus",nil)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_chance",nil)
	end
end

---当收回刘启的时候，检查是否有资金在使用中，如果有，记录剩余时间
function liuqi_zjyy_owner_died(keys)
	local caster = keys.caster
	
	local modifier = caster:FindModifierByName("modifier_dzhz_LiuQi_tooltip")
	if modifier and modifier:GetRemainingTime() > 0 then
		--移除计时器
		TimerUtil.removeTimer(modifier._timer)
		
		--记录数据
		local remain = modifier:GetRemainingTime()
		local money = modifier._money
		local bonus = modifier._bonus
		local chance = modifier._chance
		
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_remain",remain)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_money",money)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_bonus",bonus)
		Towermgr.SetTowerKV(caster,"liuqi_zjyy_timer_chance",chance)
	end
end