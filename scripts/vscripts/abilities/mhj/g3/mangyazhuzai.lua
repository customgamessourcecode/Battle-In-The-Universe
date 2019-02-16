function myzz_lizhua( keys )
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    
    local damage = GetAbilitySpecialValueByLevel(ability,"damage_per_stack")
 
 	local modifier = target:FindModifierByName("modifier_mhj_MangYaZhuZai_lizhua_tooltip")
 	if modifier and modifier:GetStackCount() > 0 then
 		ApplyDamageEx(caster,target,ability,damage * modifier:GetStackCount())
 	end
end
