---小舞：暴杀八段摔
function xw_bsbds(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local modifier = caster:FindModifierByName("modifier_dldl_XiaoWu_bsbds")
	if modifier then
		if modifier:GetStackCount() < 7 then
			modifier:IncrementStackCount()
		else
			--第8次攻击，触发效果
			modifier:SetStackCount(0)
			
			local unitLevel = caster:GetLevel()
			local damage = caster:GetAverageTrueAttackDamage(target) * unitLevel * unitLevel
			
			--6-9级，击退目标单位，9级以后击退范围内的单位
			if unitLevel < 6 then
				ApplyDamageEx(caster,target,ability,damage)
			elseif unitLevel < 9  then
				local duration = GetAbilitySpecialValueByLevel(ability,"knock_duration")
				local distance = GetAbilitySpecialValueByLevel(ability,"knock_distance")
				local cooldown = GetAbilitySpecialValueByLevel(ability,"knock_interval")
				local height = 0
				
				ApplyDamageEx(caster,target,ability,damage)
				KnockBackX(caster,target,ability,duration,distance,height,false,cooldown)
			else
				local radius = GetAbilitySpecialValueByLevel(ability,"knock_radius")
				local duration = GetAbilitySpecialValueByLevel(ability,"knock_duration")
				local distance = GetAbilitySpecialValueByLevel(ability,"knock_distance")
				local cooldown = GetAbilitySpecialValueByLevel(ability,"knock_interval")
				local height = 0
				
				local units = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
				for key, unit in pairs(units) do
					ApplyDamageEx(caster,unit,ability,damage)
					KnockBackX(caster,unit,ability,duration,distance,height,false,cooldown)
				end
			end
		end
	end
end