---
function dhd_dhqtz(keys)
	local ability = keys.ability
	local caster = keys.caster
	local point = keys.target_points[1]

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local damage = GetAbilitySpecialValueByLevel(ability,"damage")

	local path = "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf";

	local pid = CreateParticleEx(path,PATTACH_POINT,caster)

	SetParticleControlEx(pid,0 ,point)	
	
	DamageEnemiesWithinRadius(point,radius,caster,damage,ability)
end