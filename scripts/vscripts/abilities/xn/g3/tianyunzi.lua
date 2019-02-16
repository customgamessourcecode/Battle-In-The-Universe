---天运子：分身
function tyz_fs(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local count = GetAbilitySpecialValueByLevel(ability,"count")
	if not count or count == 0 then
		return
	end
	
	local existIllusion = ability._existIllusion
	if not existIllusion then
		existIllusion = {}
		ability._existIllusion = existIllusion
	end
	local exist = RemoveDiedEntityInArray(existIllusion)
	if exist >= count then
		return;
	end
	
	local radius = GetAbilitySpecialValueByLevel(ability,"radius")
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	local damage_outgoing = GetAbilitySpecialValueByLevel(ability,"damage_outgoing")
	local damage_incoming = GetAbilitySpecialValueByLevel(ability,"damage_incoming")
	
	local illusion = CreateIllusion(caster,RandomPosInRadius(caster:GetAbsOrigin(),radius),ability,duration,damage_outgoing,damage_incoming)
	table.insert(existIllusion,illusion)
	
	--需要移除的buff，比如如果幻象不能再制造幻象，就需要移除制造幻象的buff本身
	if keys.remove then
		local modifiers = Split(keys.remove,",")
		for key, modifier in pairs(modifiers) do
			illusion:RemoveModifierByName(modifier)
		end
	end
	--需要新增的buff
	if keys.add then
		local modifiers = Split(keys.add,",")
		for key, modifier in pairs(modifiers) do
			AddDataDrivenModifier(ability,caster,illusion,modifier,{})
		end
	end
end

---人物被移除，删掉所有分身和召唤物
function tyz_died(keys)
	local ability = keys.ability
	local existIllusion = ability._existIllusion
	if existIllusion then --幻象的技能没有这个属性，不用考虑冲突
		ClearUnitArray(existIllusion)
	end
end