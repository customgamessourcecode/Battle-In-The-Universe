--命运主宰奥夫：超越轮回
function af_cylh(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local unitLevel = caster:GetLevel()
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	
	local damage = ratio * caster:GetAttackDamage() * unitLevel * unitLevel
	
	ApplyDamageEx(caster,target,ability,damage)
	
	local interval = GetAbilitySpecialValueByLevel(ability,"interval")
	ability:StartCooldown(interval)
	TimerUtil.createTimerWithDelay(interval,function()
		AddDataDrivenModifier(ability,caster,caster,"modifier_pl_AoFu_cylh_damage",{})
	end)
end
