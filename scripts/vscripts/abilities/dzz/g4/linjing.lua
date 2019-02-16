---林静：冰霜劲道
function lj_bsjd(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	local damage = GetAbilitySpecialValueByLevel(ability,"damage")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	
	local debuff = "modifier_dzz_LingJing_bsjd_debuff"
	
	local bonusAbility = caster:FindAbilityByName("dzz_LingJing_bsaj")
	if bonusAbility and bonusAbility:GetLevel() > 0 then
		damage = damage * GetAbilitySpecialValueByLevel(bonusAbility,"ratio")
		debuff = "modifier_dzz_LingJing_bsjd_debuff_an"
	end
	local path = "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_explode.vpcf"
	local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,target)
	SetParticleControlEx(pid,3,target:GetAbsOrigin())
	
	ApplyDamageEx(caster,target,ability,damage)
	AddDataDrivenModifier(ability,caster,target,debuff,{duration=duration})
	
	local units = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
	if #units > 0 then
		for key, unit in pairs(units) do
			if unit ~= target and count > 0 then
				ApplyDamageEx(caster,unit,ability,damage)
				AddDataDrivenModifier(ability,caster,unit,debuff,{duration=duration})
				
				CreateProjectileWithTarget(target,unit,ability,"particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",900);
				
				count = count - 1
			end
		end
	end
end

---林静：冰霜剑气，伤害并有几率冰冻
function lj_bsjq(keys)
	local caster = keys.caster
	local ability = keys.ability
	local units = keys.target_entities
	
	if units and #units > 0 then
		local damage = GetAbilitySpecialValueByLevel(ability,"damage")
		local chance = GetAbilitySpecialValueByLevel(ability,"chance")
		local duration = 0
		--玄凤之水加成
		if ability.group_bonus then
			duration = GetAbilitySpecialValueByLevel(ability,"duration_group")
		else
			duration = GetAbilitySpecialValueByLevel(ability,"duration")
		end
		
		for _, target in pairs(units) do
			ApplyDamageEx(caster,target,ability,damage)
			
			if RollPercent(chance) and not target:HasModifier("modifier_dzz_LingJing_bsjq_debuff_interval") then
				AddDataDrivenModifier(ability,caster,target,"modifier_dzz_LingJing_bsjq_debuff",{duration=duration})
			end
		end
	end
end