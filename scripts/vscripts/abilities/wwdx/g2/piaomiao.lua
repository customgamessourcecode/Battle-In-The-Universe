---缥缈：点石成金
function pm_dscj(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	if Spawner.IsInfinite() then
		ability:RefundManaCost()
		ability:EndCooldown()
		return;
	end
	
	local gold = GetAbilitySpecialValueByLevel(ability,"gold")
	
	--检查施法者是否经过了卡牌等级提升的强化
	local bonusModifier = caster:FindModifierByName("modifier_card_lvlup_bonus_money");
	if bonusModifier and bonusModifier:GetStackCount() > 0 then
		gold = gold * (1 + bonusModifier:GetStackCount() / 100)
	end
	
	
	PlayerUtil.AddGold(caster,gold)
	PopupNum:PopupGoldGain(caster,gold)
end