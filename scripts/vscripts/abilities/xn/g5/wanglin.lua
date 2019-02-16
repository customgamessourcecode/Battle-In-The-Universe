---王林：定身术
function wl_dss(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local path = "particles/units/heroes/hero_shadowshaman/shadowshaman_shackle_net.vpcf"
	local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	if units then
		for _, unit in pairs(units) do
			if count == 0 then
				return;
			end
			--伤害
			ApplyDamageEx(caster,unit,ability,damage)
			
			--添加debuff
			AddDataDrivenModifier(ability,caster,unit,"modifier_xn_WangLin_dss_debuff",{duration=duration})
			
			local pid = CreateParticleEx(path,PATTACH_POINT,unit,duration)
			ParticleManager:SetParticleControlEnt(pid,1,unit,PATTACH_POINT_FOLLOW,"attach_hitloc",unit:GetAbsOrigin(),true)
			
			count = count - 1
		end
	end
	
	
end

---王林：翻天印
function wl_fty(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local maxCount = GetAbilitySpecialValueByLevel(ability,"maxCount")
	
	local modifier = caster:FindModifierByName("modifier_xn_WangLin_fty")
	if modifier:GetStackCount() < maxCount - 1 then
		modifier:IncrementStackCount()
	else
		modifier:SetStackCount(0)
		local effect = "particles/xn/wanglin_fty.vpcf"
		CreateProjectileWithTarget(caster,target,ability,effect,caster:GetProjectileSpeed())
	end
end

function wl_fty_damage(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local ratio = GetAbilitySpecialValueByLevel(ability,"ratio")
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	
	
	local damage = caster:GetAverageTrueAttackDamage(target) * ratio
	DamageEnemiesWithinRadius(target:GetAbsOrigin(),radius,caster,damage,ability)
end

---王林：生死印
function wl_ssy(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	
	local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)
	for key, unit in pairs(units) do
		if count > 0 and not unit.TD_IsBoss then
			local effect = "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast.vpcf"
			CreateProjectileWithTarget(caster,unit,ability,effect)
			count = count - 1
			
			if count == 0 then
				break;
			end
		end
	end
end
