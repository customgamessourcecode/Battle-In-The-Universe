--朱竹清：分身
function zzq_fs(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	--虽然这个buff设置了幻象不可继承，但是创建出来的时候已经加上了，避免在未删除该buff的时候就触发了，这里特殊处理一下
	if caster:IsIllusion() then
		return
	end
	
	local existIllusion = ability._existIllusion
	if not existIllusion then
		existIllusion = {}
		ability._existIllusion = existIllusion
	end
	
	local duration = GetAbilitySpecialValueByLevel(ability,"illusion_duration")
	local outgoingDamage = GetAbilitySpecialValueByLevel(ability,"illusion_damage") - 100 --默认为0就表示100%伤害。所以对ui显示值特殊处理一下
	local origin = caster:GetAbsOrigin() + RandomVector(RandomInt(60,120))
	
	local illusion = CreateIllusion(caster,origin,ability,duration,outgoingDamage,0)
	---默认就有这个分身的buff，移除掉，否则虽然buff设置了幻象不可继承，但是仍然会出现在幻象身上，
	--因为创建出来的时候就已经加上了。当时还不是幻象
	illusion:RemoveModifierByName("modifier_dldl_ZhuZhuQing_fs")
	AddDataDrivenModifier(ability,caster,illusion,"modifier_dldl_ZhuZhuQing_fs_illusion",{})
	
	table.insert(existIllusion,illusion)
end

---人物被移除，删掉所有分身和召唤物
function zzq_died(keys)
	local ability = keys.ability
	local existIllusion = ability._existIllusion
	if existIllusion then --幻象的技能没有这个属性，不用考虑冲突
		ClearUnitArray(existIllusion)
	end
end

---朱竹清：幽冥附体创建
function zzq_ymft_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	AddLuaModifier(caster,caster,"zzq_ymft_damage_out",{},ability)
end
---朱竹清：幽冥附体销毁
function zzq_ymft_destroy(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("zzq_ymft_damage_out")
end