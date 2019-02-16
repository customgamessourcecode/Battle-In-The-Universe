

function ty_foucus(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local level = ability:GetLevel()
	
	if ability.target == target then
		local modifier = caster:FindModifierByName("modifier_xjqxz_TangYu_zz_speed")
		if modifier and modifier:GetStackCount() < level then
			modifier:IncrementStackCount()
		end
	else
		ability.target = target
		local modifier = caster:FindModifierByName("modifier_xjqxz_TangYu_zz_speed")
		if not modifier then
			modifier = AddDataDrivenModifier(ability,caster,caster,"modifier_xjqxz_TangYu_zz_speed",{})
		end
		
		if modifier then
			modifier:SetStackCount(1)
		end
	end
end

