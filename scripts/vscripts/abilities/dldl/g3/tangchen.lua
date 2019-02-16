--唐晨：修罗领域创建
function tc_xlly_create(keys)
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	
	AddLuaModifier(caster,target,"tc_xlly_debuff",{},ability)
end

--唐晨：修罗领域移除
function tc_xlly_destroy(keys)
	local caster = keys.caster
	local target = keys.target
	target:RemoveModifierByNameAndCaster("tc_xlly_debuff",caster)
end