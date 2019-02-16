---奥斯卡：老子有根毛毛虫
function ask_mmc(keys)
	local ability = keys.ability
	local target = keys.target
	local used_abilities = target._used_abilities
	if used_abilities and #used_abilities > 0 then
		--取最后一个
		local targetAbility = used_abilities[#used_abilities]
		if EntityNotNull(targetAbility) then
			--不是本技能自身，非大招，正在冷却中，此时冷却技能
			if targetAbility:GetAbilityName() ~= ability:GetAbilityName() 
			and not BitAndTest(targetAbility:GetAbilityType(),ABILITY_TYPE_ULTIMATE) 
			and targetAbility:GetCooldownTimeRemaining() > 0 then
				targetAbility:EndCooldown()
				return;
			end
		end
	end
	ability:EndCooldown()
end