---剑心通明
function ljy_jxtm(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	
	--额外的伤害系数
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	if not ratio or ratio == 0 then
		ratio = 1
	end
	
	local damage = caster:GetAverageTrueAttackDamage(target) * ratio
	
	--斩鬼神加强
	local modifier = caster:FindModifierByName("modifier_zx_linjingyu_zgs")
	if modifier then
		local zgsAbility = modifier:GetAbility()
		if zgsAbility then
			local zgsRatio = GetAbilitySpecialValueByLevel(zgsAbility,"jxtm")
			if zgsRatio > 0 then
				damage = damage * (1 + zgsRatio)
			end
		end
	end
	
	ApplyDamageEx(caster,target,ability,damage)
end