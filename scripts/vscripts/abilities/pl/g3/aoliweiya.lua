function alwy_extradamage(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local level = caster:GetLevel()
	
	local damage = caster:GetAttackDamage() * level * level
	ApplyDamageEx(caster,target,ability,damage)
end

function alwy_foucus(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local level = ability:GetLevel()
	
	if ability.target == target then
		local modifier = caster:FindModifierByName("modifier_pl_AoLiWeiYa_2_speed")
		if modifier and modifier:GetStackCount() < level then
			modifier:IncrementStackCount()
		end
	else
		ability.target = target
		local modifier = caster:FindModifierByName("modifier_pl_AoLiWeiYa_2_speed")
		if not modifier then
			modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_pl_AoLiWeiYa_2_speed",{})
		end
		
		if modifier then
			modifier:SetStackCount(1)
		end
	end
end