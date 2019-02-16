---刘彻：资金管理
function liuche_zjgl(keys)
	--无尽模式不生效
	if Spawner.IsInfinite() then
		return
	end

	local ability = keys.ability
	local caster = keys.caster
	
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	
	local modifier = caster:FindModifierByName("modifier_dzhz_LiuChe")
	if modifier:GetStackCount() < interval then
		modifier:IncrementStackCount()
	else
		modifier:SetStackCount(0)
		local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
		local max = GetAbilitySpecialValueByLevel(ability,"max")
		local gold = PlayerUtil.GetGold(caster)
		gold = gold * ratio / 100
		if gold > max then
			gold = max
		end
		
		--检查施法者是否经过了卡牌等级提升的强化
		local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
		if bonusModifier and bonusModifier:GetStackCount() > 0 then
			gold = gold * (1 + bonusModifier:GetStackCount() / 100)
		end
		
		
		PlayerUtil.AddGold(caster,gold)
		PopupNum:PopupGoldGain(caster,gold)
	end
end