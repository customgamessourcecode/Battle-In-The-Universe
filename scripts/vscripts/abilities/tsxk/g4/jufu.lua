---巨斧：奋力一击
function jf_flyj(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local damage = caster:GetAttackDamage() * math.pow(caster:GetLevel(),2)
	
	--狂热加成
	local bonusBuff = caster:FindModifierByName("modifier_tsxk_JuFu_kr")
	if bonusBuff then
		damage = damage + damage * GetAbilitySpecialValueByLevel(bonusBuff:GetAbility(),"ratio") / 100
		ability:EndCooldown()
	end
	ApplyDamageEx(caster,target,ability,damage)
end