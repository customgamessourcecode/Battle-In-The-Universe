
function xx_tt(keys)
	local caster = keys.caster

	local ability = keys.ability

	local radius = GetAbilitySpecialValueByLevel(ability,"radius")

	local damage = GetAbilitySpecialValueByLevel(ability,"damage") / 100

	local units = FindEnemiesInRadiusEx(caster,caster:GetAbsOrigin(),radius)

	local path = "particles/econ/items/pudge/pudge_immortal_arm/pudge_immortal_arm_rot_radius_c.vpcf";

	for key, unit in pairs(units) do

		local pid = CreateParticleEx(path,PATTACH_ABSORIGIN,unit)
		SetParticleControlEx(pid,1,unit:GetAbsOrigin())

		ApplyDamageEx(caster,unit,ability,damage * unit:GetMaxHealth())
	end

end
