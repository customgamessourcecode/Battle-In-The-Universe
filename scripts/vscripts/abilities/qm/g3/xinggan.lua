--刑干：刑天附体
function xg_xtft(keys)
	local ability = keys.ability
	local caster = keys.caster
	local duration = GetAbilitySpecialValueByLevel(ability,"duration")
	AddDataDrivenModifier(ability,caster,caster,"modifier_qm_XingGan_huashenxingtian",{duration=duration})
	AddLuaModifier(caster,caster,"xg_xtft_damage_out",{duration=duration},ability)
end