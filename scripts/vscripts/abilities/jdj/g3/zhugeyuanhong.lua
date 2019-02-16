---诸葛元洪：归元剑法
function zgyh_gyjf(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local modifier = caster:FindModifierByName("modifier_jdj_ZhuGeYuanHong_gyjf_1")
	if modifier then
		local maxCount = GetAbilitySpecialValueByLevel(ability,"attack_count")
	
		if modifier:GetStackCount() < maxCount - 1 then
			modifier:IncrementStackCount()
		else
			--达到次数，触发效果
			modifier:SetStackCount(0)
		
			local chance = GetAbilitySpecialValueByLevel(ability,"chance")
			local reduce = GetAbilitySpecialValueByLevel(ability,"reduce")
			local damage = GetAbilitySpecialValueByLevel(ability,"damage")
			local radius = GetAbilitySpecialValueByLevel(ability,"radius")
			
			--归元剑法二式伤害加成
			local bonusAbility = caster:FindAbilityByName("jdj_ZhuGeYuanHong_gyjf_2")
			if bonusAbility and bonusAbility:GetLevel() > 0 then
				local ratio = GetAbilitySpecialValueByLevel(bonusAbility,"ratio")
				damage = damage * ratio / 100
			end
			
--			local path = "particles/units/heroes/hero_windrunner/windrunner_base_attack_explosion_flash.vpcf"
--			CreateParticleEx(path,PATTACH_ABSORIGIN,target)
			ApplyDamageEx(caster,target,ability,damage)
			
			--对其他单位造成伤害
			if RollPercent(chance) then
			
				local enemies = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),radius)
				if enemies and #enemies > 0 then
					local enemy = nil
					for key, unit in pairs(enemies) do
						if unit ~= target then
							enemy = unit
							break;
						end
					end
					
					if enemy then
						local dummy = CreateDummyUnit(target:GetAbsOrigin(),caster)
						local dummyAbility = dummy:AddAbility(ability:GetAbilityName());
						--dummyAbility:SetLevel(1);
						
						dummyAbility.sourceAbility = ability
						dummyAbility.chance = chance + reduce
						dummyAbility.reduce = reduce
						dummyAbility.damage = damage
						dummyAbility.radius = radius
						
						dummyAbility.projectile = caster:GetRangedProjectileName()
						dummyAbility.speed = caster:GetProjectileSpeed()
						
						CreateProjectileWithTarget(target,enemy,dummyAbility,dummyAbility.projectile,dummyAbility.speed)
					end
				end
			end
		end
	end
end

---额外弹射攻击命中目标造成伤害
function zgyh_gyjf_projectile_landed(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
--	local path = "particles/units/heroes/hero_windrunner/windrunner_base_attack_explosion_flash.vpcf"
--	CreateParticleEx(path,PATTACH_ABSORIGIN,target)
	ApplyDamageEx(caster:GetOwner(),target,ability.sourceAbility,ability.damage)
	
	if RollPercent(ability.chance) then
		--继续衰减几率
		ability.chance = ability.chance + ability.reduce
		--寻找新的目标
		local enemies = FindEnemiesInRadiusEx(caster,target:GetAbsOrigin(),ability.radius)
		if enemies and #enemies > 0 then
			local HasNewTarget = false
			for key, enemy in pairs(enemies) do
				if enemy ~= target then
					HasNewTarget = true
					CreateProjectileWithTarget(target,enemy,ability,ability.projectile,ability.speed)
				end
			end
			if not HasNewTarget then
				EntityHelper.remove(caster)
			end
		else
			EntityHelper.remove(caster)
		end
	else
		EntityHelper.remove(caster)
	end
end