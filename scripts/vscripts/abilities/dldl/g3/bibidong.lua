--比比东：死亡蛛皇，添加一个buff，就添加/叠加提示buff。用两个buff是因为默认dota的buff设置了持续时间后就必然会在持续时间结束后
function bbd_swzh_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	local modifierName = "modifier_dldl_BiBiDong_swzh_debuff"
	local modifier = target:FindModifierByName(modifierName)
	if modifier then
		modifier:ForceRefresh() --每次刷新持续时间
		modifier:IncrementStackCount()
	else
		modifier = AddDataDrivenModifier(ability,caster,target,modifierName)
		if modifier then--添加的时候，这个单位可能已经挂了
			modifier:SetStackCount(1)
		end
	end
end

---带有死亡蛛皇debuff的单位死亡触发爆炸伤害
function bbd_swzh_death(keys)
	local ability = keys.ability
	local caster = keys.caster
	local unit = keys.unit--死亡这里获取不到target，只有unit
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local damage = GetAbilitySpecialValueByLevel(ability,"death_damage")
	
	local modifier = unit:FindModifierByName("modifier_dldl_BiBiDong_swzh_debuff")
	if modifier then
		local count = modifier:GetStackCount()
		if count == 0 then
			count = 1
		end
		local enemies = FindAlliesInRadiusEx(unit,unit:GetAbsOrigin(),radius,DOTA_UNIT_TARGET_FLAG_NO_INVIS)
		if enemies and #enemies > 0 then
			local path = "particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf"
			for key, enemy in pairs(enemies) do
				CreateParticleEx(path,PATTACH_ABSORIGIN,enemy,2)
				ApplyDamageEx(caster,enemy,ability,damage)
			end
		end
	end
end

function bbd_shzh_debuff_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	AddLuaModifier(caster,target,"bbd_shzh_debuff",{},ability)
end

function bbd_shzh_debuff_destroy(keys)
	local caster = keys.caster
	local target = keys.target
	target:RemoveModifierByNameAndCaster("bbd_shzh_debuff",caster)
end